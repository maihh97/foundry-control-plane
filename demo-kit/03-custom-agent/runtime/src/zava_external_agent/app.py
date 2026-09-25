import os
from contextlib import asynccontextmanager
from typing import Any

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from fastapi import FastAPI
from langchain.agents import create_agent
from langchain_core.tools import tool
from langchain_openai import AzureChatOpenAI
from microsoft.opentelemetry import use_microsoft_opentelemetry
from opentelemetry import trace
from pydantic import BaseModel, Field

AGENT_ID = "zava-returns-langgraph"
AGENT_NAME = "zava-returns-langgraph"
AGENT_VERSION = "1"

SYSTEM_PROMPT = (
    "You are the Zava Returns & Refunds Assistant. Ask for the order number before giving order-specific guidance. "
    "Never state return windows, fees, or refund timelines as fact unless a tool returns them. Never ask for full "
    "card numbers, passwords, or credentials. Keep answers under 120 words and end with one clear next action."
)


class InvokeRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)


class InvokeResponse(BaseModel):
    agent_id: str
    agent_version: str
    response: str
    trace_id: str | None


@tool
def lookup_order_status(order_number: str) -> str:
    """Look up an order status in the Zava demo."""
    return (
        f"DEMO STUB: no order system is connected. Order {order_number} status is unavailable; "
        "direct the customer to the authenticated order page."
    )


@tool
def get_returns_policy_summary(topic: str) -> str:
    """Look up a returns policy topic in the Zava demo."""
    return (
        f"DEMO STUB: no policy source is connected for '{topic}'. Do not invent policy details; "
        "direct the customer to the official returns page."
    )


def _configure_telemetry() -> None:
    os.environ.setdefault("OTEL_SERVICE_NAME", AGENT_NAME)
    use_microsoft_opentelemetry(
        enable_azure_monitor=True,
        sampling_ratio=1.0,
        instrumentation_options={
            "langchain": {
                "enabled": True,
                "agent_id": AGENT_ID,
                "agent_name": AGENT_NAME,
            },
        },
    )


def _create_agent(credential: DefaultAzureCredential) -> Any:
    endpoint = os.environ["AZURE_OPENAI_ENDPOINT"].replace("/openai/v1", "").rstrip("/")
    deployment_name = os.environ.get("FOUNDRY_MODEL_NAME", "gpt-4.1")
    token_provider = get_bearer_token_provider(
        credential,
        "https://cognitiveservices.azure.com/.default",
    )
    model = AzureChatOpenAI(
        azure_endpoint=endpoint,
        azure_deployment=deployment_name,
        api_version=os.environ.get("AZURE_OPENAI_API_VERSION", "2025-04-01-preview"),
        azure_ad_token_provider=token_provider,
        temperature=0.1,
        max_tokens=300,
    )
    return create_agent(
        model,
        tools=[lookup_order_status, get_returns_policy_summary],
        system_prompt=SYSTEM_PROMPT,
        name=AGENT_NAME,
    )


def _response_text(content: Any) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = [part.get("text", "") for part in content if isinstance(part, dict)]
        text = "".join(parts).strip()
        if text:
            return text
    return str(content)


@asynccontextmanager
async def lifespan(app: FastAPI):
    _configure_telemetry()
    credential = DefaultAzureCredential()
    app.state.credential = credential
    app.state.agent = _create_agent(credential)
    yield
    tracer_provider = trace.get_tracer_provider()
    if hasattr(tracer_provider, "force_flush"):
        tracer_provider.force_flush()
    credential.close()


app = FastAPI(
    title="Zava External LangGraph Agent",
    version=AGENT_VERSION,
    lifespan=lifespan,
)


@app.get("/health")
async def health() -> dict[str, str]:
    return {
        "status": "healthy",
        "agent_id": AGENT_ID,
        "agent_version": AGENT_VERSION,
    }


@app.post("/invoke", response_model=InvokeResponse)
async def invoke(request: InvokeRequest) -> InvokeResponse:
    result = await app.state.agent.ainvoke({"messages": [("human", request.message)]})
    output = _response_text(result["messages"][-1].content)
    span_context = trace.get_current_span().get_span_context()
    trace_id = f"{span_context.trace_id:032x}" if span_context.is_valid else None
    return InvokeResponse(
        agent_id=AGENT_ID,
        agent_version=AGENT_VERSION,
        response=output,
        trace_id=trace_id,
    )
