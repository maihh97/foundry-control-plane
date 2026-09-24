# Foundry Control Plane demo kit — 03 (alternative) register the LangGraph agent as an EXTERNAL agent (Preview, no gateway)
# Derived from (verbatim API usage):
#   https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/agents/sample_external_agents_crud.py
#   Docstring (verbatim): "External Agents are a preview feature. They register third-party agents hosted outside Microsoft Foundry.
#   Registration is metadata-only: Foundry uses the OpenTelemetry agent identifier to light up traces and evaluations for spans
#   emitted by your external agent."
# Use this when you cannot host the LangGraph server behind the AI Gateway (see HOSTING-GAP.md). You get observability and
# trace-based evaluations but NO Block/Unblock and NO red teaming.
# Changes vs the sample: agent name / otel id set to the Returns Assistant; the final delete is REMOVED so the agent stays registered
# (the initial delete-if-exists is kept so the script is re-runnable).
# Requires: pip install "azure-ai-projects>=2.2.0" python-dotenv  (kit pins 2.7.0); client needs allow_preview=True.
#
# USAGE: python 03-custom-agent/external_agent_register.py

import os

from dotenv import load_dotenv

from azure.core.exceptions import ResourceNotFoundError
from azure.identity import DefaultAzureCredential

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    ExternalAgentDefinition,
)

load_dotenv()

endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]


with (
    DefaultAzureCredential() as credential,
    AIProjectClient(endpoint=endpoint, credential=credential, allow_preview=True) as project_client,
):
    agent_name = "zava-returns-langgraph"
    otel_agent_id = "zava-returns-langgraph"  # must match agent_id in langgraph_agent.py (gen_ai.agent.id)

    try:
        project_client.agents.delete(agent_name, force=True)
        print(f"External agent `{agent_name}` deleted")
    except ResourceNotFoundError:
        pass

    created = project_client.agents.create_version(
        agent_name=agent_name,
        definition=ExternalAgentDefinition(otel_agent_id=otel_agent_id),
        description="Zava Returns & Refunds Assistant (LangGraph) registered as an external agent for observability and evaluations.",
        metadata={"sample": "external_agents_crud", "demo": "zava-returns", "status": "created"},
    )
    print(f"Created external agent: {created.name} version={created.version} otel_agent_id={otel_agent_id}")

    fetched_agent = project_client.agents.get(agent_name)
    print(f"Retrieved external agent: {fetched_agent.name} latest_version={fetched_agent.versions.latest.version}")

    fetched_version = project_client.agents.get_version(agent_name=agent_name, agent_version=created.version)
    print(f"Retrieved external agent version: {fetched_version.name} version={fetched_version.version}")

    external_agents = list(project_client.agents.list(kind="external", limit=10))
    print(f"Found {len(external_agents)} external agents or more")
    for external_agent in external_agents:
        print(f" - {external_agent.name} ({external_agent.id})")

    print()
    print("Portal alternative: Build > Agents > New agent > Link external agent (name, description, OpenTelemetry ID).")
    print("Traces from the instrumented LangGraph agent show up in 'typically 2-5 minutes' (register-external-agent).")
