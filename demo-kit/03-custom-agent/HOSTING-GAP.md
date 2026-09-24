<!--
Foundry Control Plane demo kit — 03 HOSTING GAP (G-1) — clearly labelled: no code is provided for this step on purpose
Derived from:
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/register-custom-agent
  https://github.com/microsoft-foundry/foundry-samples/tree/main/samples/python/hosted-agents/langgraph  (README)
  https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/agents/sample_external_agents_crud.py
  https://github.com/microsoft/agent-framework/blob/main/python/samples/02-agents/observability/foundry_tracing.py
-->
# ⚠ GAP G-1 — hosting a LangGraph *server* as the backend of "Register asset"

## The documented gap

No official sample deploys a LangGraph *server* to Azure as the backend for **Register asset** (gateway-proxied custom agent). Supported alternatives are to host LangGraph as a Foundry hosted agent or register it as an External agent, which does not use the gateway or support Block.

Every building block for step 3 is official (the distro instrumentation sample, the wizard table, the `langgraph_sdk` client snippet), but **no single Microsoft sample stands up the LangGraph server itself** (e.g. on Container Apps) that `Register asset` proxies. The docs only require that "Your agent exposes an exclusive endpoint" and that "The network where you deploy the Foundry resource can reach the agent's endpoint." **This kit therefore deliberately ships no hosting code for the server** — anything we wrote would be invented, not grounded.

## What to do for the Zava demo — pick one

### Option A (recommended for the live demo) — host the LangGraph agent *in Foundry* as a hosted agent

Official sample set: `foundry-samples/samples/python/hosted-agents/langgraph` — "Use the configuration-driven langchain_azure_ai.agents.hosting.run entrypoint by default." Sample **8 Observability**: "A LangGraph agent with GenAI OpenTelemetry tracing enabled via enable_auto_tracing(), emitting spans, metrics, and logs to Application Insights." Foundry injects `FOUNDRY_PROJECT_ENDPOINT`, `AZURE_AI_MODEL_DEPLOYMENT_NAME` and `APPLICATIONINSIGHTS_CONNECTION_STRING`.

```bash
azd ext install azure.ai.agents
azd auth login
mkdir hosted-langgraph-agent && cd hosted-langgraph-agent
# Initialize from the manifest (replace with the sample you want to try)
azd ai agent init -m https://github.com/microsoft-foundry/foundry-samples/blob/main/samples/python/hosted-agents/langgraph/responses/01-langgraph-chat/azure.yaml
azd provision   # creates rg-[project_name]-dev: Foundry instance, project + model deployment, Application Insights, container registry
azd ai agent run
azd ai agent invoke --local "Hello!"
curl -X POST http://localhost:8088/responses -H "Content-Type: application/json" -d '{"input": "Hello!"}'
azd deploy
```

Trade-off: it is then a **Foundry hosted agent** (Start/Stop lifecycle, guardrails via `policies:`/`rai_config`, red teaming caveat in 05), not a *custom* agent — so it does **not** demonstrate Register asset / Block. Say so explicitly. The LangGraph → Foundry tracing story still lands because the same OpenTelemetry semantic conventions are used.

### Option B — register as an **External agent** (no gateway)

Run `external_agent_register.py` (from `sample_external_agents_crud.py`). The agent keeps its existing endpoint wherever you run it (even a laptop) and "shares only OpenTelemetry telemetry". You get **traces + trace-based evaluation**, but "No AI Gateway is required" also means **no Block/Unblock and no red teaming**. Good fallback for the fleet-view story if the gateway is not ready.

### Option C — bring your own host and register it as a custom agent

If Zava (or you) already run a LangGraph server on your own infrastructure, register it with `register_custom_agent.md` and point `client_via_gateway.py` at the APIM URL. The only official statements about the host are the checklist quoted above plus the network reachability requirement; **do not present any specific hosting recipe as "the Microsoft way"**.

## Related official pointers (not LangGraph-server samples, but useful context)

- MAF equivalent showing Control Plane "Register agent" with OTel id `weather-agent`: `microsoft/agent-framework` `python/samples/02-agents/observability/foundry_tracing.py` (Part B3).
- Azure-Samples/AI-Gateway lab `ai-foundry-hosted-agents` deploys a *hosted agent to Azure Container Apps* with APIM in front for **inference routing**, not agent registration.
- Distro alternative tracer for LangGraph: `pip install -U langchain-azure-ai[opentelemetry]` → `AzureAIOpenTelemetryTracer(connection_string=..., enable_content_recording=True)` → `.with_config({"callbacks": [tracer]})` (register-custom-agent article).

## What to say on stage (one sentence)

"Foundry registers *any* agent that has its own endpoint and emits GenAI OpenTelemetry — today we host this LangGraph agent in Foundry to keep the demo self-contained; in production Zava would keep running it wherever it lives and register the URL."
