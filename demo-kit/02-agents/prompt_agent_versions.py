# Foundry Control Plane demo kit — 02 prompt agent with two versions + traffic pinned to v2
# Derived from (verbatim API usage, adapted instructions):
#   https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/agents/sample_agent_basic.py
#   https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/manage-hosted-agent
#     ("Traffic splitting between agent versions isn't supported. Configure one FixedRatio rule with traffic_percentage set to 100")
# Changes vs the sample: create_version is called twice (v1 basic, v2 improved instructions), the endpoint is pinned to v2,
# and the sample's `finally:` cleanup block is REMOVED so both versions stay visible in Operate > Assets.
# Scenario text below is demo prompt content only — it invents no facts about Zava systems.
#
# USAGE:
#   pip install -r requirements.txt   (azure-ai-projects==2.7.0, Python >= 3.10)
#   python 02-agents/prompt_agent_versions.py
# ENV (see .env.example): FOUNDRY_PROJECT_ENDPOINT, FOUNDRY_MODEL_NAME, FOUNDRY_AGENT_NAME (default zava-returns-assistant)

import os
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    AgentEndpointConfig,
    FixedRatioVersionSelectionRule,
    PromptAgentDefinition,
    ProtocolConfiguration,
    ResponsesProtocolConfiguration,
    VersionSelector,
)

load_dotenv()

endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
agent_name = os.environ.get("FOUNDRY_AGENT_NAME") or "zava-returns-assistant"
model = os.environ["FOUNDRY_MODEL_NAME"]

INSTRUCTIONS_V1 = (
    "You are the Zava Returns & Refunds Assistant. Answer customer questions about returning items "
    "and getting refunds. Be brief and polite."
)

INSTRUCTIONS_V2 = (
    "You are the Zava Returns & Refunds Assistant, a customer-service agent for an online fashion retailer.\n"
    "Goals: help the customer start a return, understand refund timing, and choose a return method.\n"
    "Rules:\n"
    "- Ask for the order number before giving order-specific guidance; never guess order details.\n"
    "- Do not state return windows, fees or refund timelines as facts unless the customer provides them or a tool returns them; "
    "otherwise say you will confirm the exact policy and point them to the official returns page in their account.\n"
    "- Never ask for full card numbers or passwords.\n"
    "- If the customer is upset, acknowledge it first, then give the next concrete step.\n"
    "- Keep answers under 120 words and end with one clear next action."
)

with (
    DefaultAzureCredential() as credential,
    AIProjectClient(endpoint=endpoint, credential=credential) as project_client,
):
    # --- v1: basic instructions ---
    v1 = project_client.agents.create_version(
        agent_name=agent_name,
        definition=PromptAgentDefinition(
            model=model,
            instructions=INSTRUCTIONS_V1,
        ),
    )
    print(f"Agent created (id: {v1.id}, name: {v1.name}, version: {v1.version})")

    # --- v2: improved instructions (same name => new immutable version) ---
    v2 = project_client.agents.create_version(
        agent_name=agent_name,
        definition=PromptAgentDefinition(
            model=model,
            instructions=INSTRUCTIONS_V2,
        ),
    )
    print(f"Agent created (id: {v2.id}, name: {v2.name}, version: {v2.version})")

    # --- pin 100% of endpoint traffic to v2 (one FixedRatio rule, traffic_percentage=100) ---
    endpoint_config = AgentEndpointConfig(
        version_selector=VersionSelector(
            version_selection_rules=[
                FixedRatioVersionSelectionRule(agent_version=v2.version, traffic_percentage=100),
            ]
        ),
        protocol_configuration=ProtocolConfiguration(responses=ResponsesProtocolConfiguration()),
    )
    project_client.agents.update_details(agent_name=agent_name, agent_endpoint=endpoint_config)
    print(f"Agent endpoint configured for version {v2.version}")

    # --- smoke test through the agent endpoint (OpenAI Responses via the project client) ---
    with project_client.get_openai_client(agent_name=agent_name) as openai_client:
        conversation = openai_client.conversations.create(
            items=[{"type": "message", "role": "user", "content": "Hi, I want to return a pair of trainers I bought last week. What do I do?"}],
        )
        print(f"Created conversation with initial user message (id: {conversation.id})")

        response = openai_client.responses.create(
            conversation=conversation.id,
        )
        print(f"Response output: {response.output_text}")

    print()
    print("Now open Foundry (new) portal > Operate > Assets > Agents: both versions are listed; Version column shows the pinned one.")
    print(f"Roll back with: bash 02-agents/pin_or_rollback_version.sh {v1.version}")
