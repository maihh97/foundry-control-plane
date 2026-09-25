<!--
Foundry Control Plane demo kit — 03 register the LangGraph agent as a CUSTOM agent (gateway-proxied, Preview)
Derived from (verbatim wizard table, paths and troubleshooting):
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/register-custom-agent
  https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/control-plane/register-custom-agent.md
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-agents  (Assets pane, 15-minute propagation)
-->
# 03 · Register the LangGraph agent as a custom agent (Preview)

> **Automation status.** The optional Foundry **Register asset** step remains portal-only. The runtime, managed identity, Container Apps hosting, stable APIM gateway, throttling, backend isolation, and telemetry are deployed as code before this wizard is used.

Prerequisite (verbatim): "An AI gateway configured in your Foundry resource. Foundry uses Azure API Management to register agents as APIs." The Zava runtime is reachable through the stable APIM route documented in `EXTERNAL-RUNTIME.md`.

Verification checklist before registering (verbatim): "Your agent exposes an exclusive endpoint. The network where you deploy the Foundry resource can reach the agent's endpoint. The agent communicates by using one of the supported protocols: HTTP (general) or A2A (more specific). Your agent emits data by using the OpenTelemetry semantic conventions for generative AI solutions (or you don't need this capability). You can configure the endpoint that users use to communicate with the agent."

## ⚠ Order-of-operations trap (do this at T-60, in this order)

1. **Manage > AI Gateway** — gateway present; project enabled on it.
2. **Manage > Project details > Connected resources** — "Ensure that there's an associated resource in the **AppInsights** category" (else **Add connection > Application Insights**).
3. **Only then** register the custom agent.

Verbatim: "**If you configured Application Insights after you registered the custom agent, you need to unregister the agent and register it again.** Application Insights configuration isn't automatically updated after registration if you changed it."

## Register asset — wizard fields (verbatim table)

Path: toolbar **Operate** → **Overview** pane → **Register asset**.

| Property | Description | Required |
|---|---|---|
| Agent URL | The endpoint (URL) where your agent runs and receives requests. In general, but depending on your protocol, you indicate the base URL that your clients use. For example, if your agent uses the OpenAI Chat Completions API, you indicate `https://<host>/v1/` without `/chat/completions` because clients generally add it. | Yes |
| Protocol | The communication protocol that your agent supports. Use HTTP in general. Or if your agent supports A2A more specifically, indicate that one. | Yes |
| A2A agent card URL | The path to the agent card's JSON specification. If you don't specify it, the system uses the default `/.well-known/agent-card.json`. | Yes, when Protocol is A2A |
| OpenTelemetry agent ID | The agent ID that your agent uses to emit traces according to OpenTelemetry semantic conventions for generative AI. Traces indicate it in the `gen_ai.agent.id` attribute for spans with the operation name `create_agent`. If you don't specify this value, the system uses the Agent name value to find traces and logs that this new agent reports. | No |
| Admin portal URL | The administration portal URL where you can perform further administration operations for this agent. Foundry can store this value for convenience. Foundry doesn't have any access to perform operations directly to this portal. | No |
| Project | The project where you register the agent... You can select only projects that have an AI gateway enabled in their resources. | Yes |
| Agent name | The name of the agent as you want it to appear in Foundry. | Yes |
| Description | A clear description about this agent. | No |

**Values for this demo**

| Field | Value |
|---|---|
| Agent URL | `https://zava-apim-mh2609.azure-api.net/agents/zava-returns-langgraph/` |
| Protocol | HTTP |
| OpenTelemetry agent ID | `zava-returns-langgraph` (must equal `agent_id` in `langgraph_agent.py`) |
| Project | the gateway-enabled demo project |
| Agent name | `Zava Returns Assistant (LangGraph)` |
| Description | LangGraph returns agent hosted on Azure Container Apps and governed through Azure API Management |

## Verify and copy the new URL

1. Left pane **Assets** → "To show only custom agents, use the **Source** filter and select **Custom**."
2. UI gotcha (verbatim): "select the radio button next to the custom agent's name to open the information pane. Don't select the agent name itself, because that link navigates away from the Assets pane."
3. In the pane, under **Agent URL**, select **Copy** → paste into `.env` as `APIM_URL`. Clients must switch to this URL: "Foundry Control Plane generates a new URL. Clients and users must use this URL" → run `client_via_gateway.py`.
4. Auth (verbatim): "Although Foundry acts as a proxy for incoming requests for your agent, the original authorization and authentication schema in the original endpoint still applies."

## Seeing traces (Operate > Assets > agent > Traces)

- "Metrics and traces are collected only for runs that occur after configuration. Past runs aren't retroactively captured. Wait up to 15 minutes for data to propagate after the first post-configuration run." → generate traffic with `04-traffic/send_traffic.py` / `client_via_gateway.py` before the session.
- Troubleshoot traces checklist (verbatim): "The project where you register your agent has Application Insights configured… You configured the agent (running on its infrastructure) to send traces to Application Insights, and you're using the same Application Insights resource that your project uses. Instrumentation complies with OpenTelemetry semantic conventions for generative AI. Traces include spans with attribute `gen_ai.operation.name="create_agent"` and `gen_ai.agent.id="<agent-id>"` (or `gen_ai.agent.name="<agent-id>"`)."
- Monitoring dashboard for custom agents: "In Foundry Control Plane, go to the **Asset** page and select your agent. Select the **Monitor** tab."

## What you get vs the External-agent alternative

| | Custom agent (this page) | External agent (`external_agent_register.py`) |
|---|---|---|
| Traffic | "Foundry uses API Management to act as a proxy for communications to your agent" | Runtime traffic uses the independently deployed stable APIM route; Foundry stores registration metadata and correlates telemetry. |
| Gateway | Foundry AI gateway required | Stable APIM gateway is deployed independently and verified end to end. |
| Control | Block/unblock (Operate > Assets > Update status) | Observability + trace-based evaluation only (no Block, no red teaming) |
| Status | Operate panes = Preview | "(preview)"; header `Foundry-Features: ExternalAgents=V1Preview` / `allow_preview=True` |
