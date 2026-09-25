# Full control-plane demo route

Use the public showcase as the narrative layer and the Foundry and Azure portals as evidence layers:

<https://maihh97.github.io/foundry-control-plane/>

## Before the meeting

1. Open the showcase, Microsoft Foundry, Azure portal, Application Insights, API Management, and the GitHub Actions run.
2. Verify these resources are healthy:
   - Foundry project `zava-control`
   - Prompt agent `zava-returns-assistant` version 2
   - Hosted agent `zava-hosted-returns` version 2
   - External agent `zava-returns-langgraph` version 1
   - API Management `zava-apim-mh2609`
3. Do not display `.env`, APIM subscription keys, GitHub secrets, connection credentials, or raw prompt content from real users.

## Presenter flow

### 1. Explain the architecture

Start on the showcase architecture. Establish the boundaries:

- Prompt agent: Foundry owns model, instructions, endpoint, identity, and versions.
- Hosted agent: Foundry hosts the runtime, but source control owns the full manifest and Python code.
- External agent: Foundry owns inventory metadata and trace correlation only; the runtime stays external.

### 2. Show the fleet

In Microsoft Foundry:

1. Open **Operate > Assets > Agents**.
2. Point out type, state, latest version, identity, traces, evaluations, and alerts.
3. Explain that a fleet view standardizes operations without pretending every agent has the same runtime model.
4. Use the showcase operations matrix to set expectations for experiences that differ by agent type.

### 3. Open the prompt agent

Show:

- gpt-4.1 model reference
- version 1 and version 2
- 100 percent endpoint selection for version 2
- privacy and non-invention instructions
- unique Entra blueprint and instance identity

Rollback story: pin traffic back to version 1 without deleting either version.

### 4. Open the hosted agent

The portal shows deployed runtime metadata, not the full code. Use these files for anatomy:

- `02-agents/zava-hosted-returns/zava-hosted-returns/azure.yaml`
- `02-agents/zava-hosted-returns/zava-hosted-returns/src/agent-framework-agent-basic-responses/main.py`

Explain:

- Direct-code remote build
- Python 3.13
- Responses protocol
- CPU and memory
- managed identity
- RAI policy
- immutable deployed version

### 5. Show the external agent

Open `zava-returns-langgraph` and explain:

- Registration is metadata-only.
- `zava-returns-langgraph` is the OpenTelemetry correlation ID.
- Five current traces appear because the external LangGraph runtime emitted matching spans.
- There is no Foundry-hosted compute or endpoint to inspect.

### 6. Demonstrate the gateway

In API Management, open the `zava-openai` API:

- Caller authentication: APIM subscription key
- Backend authentication: system-assigned managed identity
- Backend role: Cognitive Services User
- Policy: 100 tokens per minute
- Diagnostics: GatewayLogs, GatewayLlmLogs, AllMetrics

Successful responses return:

- `consumed-tokens`
- `remaining-tokens`

The burst test should transition from HTTP 200 to HTTP 429.

### 7. Demonstrate guardrails

Open the hosted agent RAI policy and show the configured controls:

- Harm categories
- Jailbreak
- Protected material
- Profanity
- Purview
- Defender for AI
- Indirect attack signals

Replay the jailbreak input and show HTTP 400 `content_filter`.

### 8. Demonstrate data security

Open **Operate > Compliance** and use each tab deliberately:

- **Policies**: show prompt-injection and healthcare policies, compliance percentages, total assets, and violations.
- **Guardrails**: compare guardrail coverage across model deployments.
- **Security posture**: select `zavabasicjhca` and show Defender for Cloud recommendations. The current healthy result is **No recommendations found**.
- **Data security and governance**: show the enabled Microsoft Purview toggle and the linked subscription.

Then show the underlying Defender configuration:

- Defender for AI Services pricing tier: Standard
- AI model scanner: enabled
- AI prompt evidence: enabled
- AI prompt sharing with Purview: enabled

Purview status:

- Tenant integration enabled in Foundry
- Pay-as-you-go linked to `zava-purview-billing`
- Foundry DLP location entitlement can take a few hours to propagate
- Create the Zava audit-first DLP policy only after Microsoft Foundry becomes selectable

Also explain the architecture caveat:

- Foundry local authentication is disabled.
- Basic Agent Setup uses Microsoft-managed multitenant agent state.
- The project endpoint is public but requires Entra authentication.
- APIM model access uses managed identity.
- Trace access requires Log Analytics Reader and Privileged Monitoring Data Reader.
- GitHub uses a project-scoped credential stored only in GitHub Secrets.

Production hardening recommendation:

- Private-network or managed-VNet Foundry setup
- OIDC for GitHub Actions
- Higher-availability APIM tier
- Purview and Defender licensing validation
- Formal Azure Policy compliance assignments

### 9. Demonstrate observability

In Application Insights and Log Analytics, show:

- requests
- dependencies
- events
- traces
- exceptions
- APIM gateway and LLM logs

Then open:

- prompt continuous evaluation
- hosted smoke evaluation
- the completed prompt-agent red-team report with 72 failed attack items
- Agent Insights monitor configuration using the `gpt-5-mini` judge deployment
- GitHub Actions evaluation gate

Show the fresh attribution evidence:

- prompt version 2: 12 spans across 6 conversations
- hosted version 2: 191 trace events
- external LangGraph agent: 5 spans with `gen_ai.agent.id=zava-returns-langgraph`

Explain the service boundary honestly: continuous evaluation rules support prompt agents, but Foundry rejects those rules for hosted and external agents. Use generated evaluation plus trace-based monitoring for the hosted agent, and runtime-owned evaluation plus matching OpenTelemetry spans for the external agent.

The Agent Insights monitor and its 6-hour schedule are configured. The first run completed before fresh prompt traces arrived and analyzed zero traces; three fresh reruns later reached the monitor but failed with the same Foundry `ServiceUnavailable` dependency error. Treat this as a current preview-service outage, not a missing model, role, trace, or monitor configuration.

### 10. Demonstrate lifecycle response

Disable the prompt agent:

```bash
bash 09-identity-killswitch/disable_enable_agent.sh disable
```

Expected: HTTP 403 `AgentDisabled`.

Re-enable:

```bash
bash 09-identity-killswitch/disable_enable_agent.sh enable
```

Expected: successful traffic without recreating the endpoint or versions.

## Honest limitations

- Foundry account-level AI Gateway and some Operate experiences are preview.
- The stable APIM gateway is functional but is not represented as the Foundry portal's account-level AI Gateway preview.
- External-agent registration alone does not create a runnable LangGraph service.
- Basic Agent Setup is public-network, Entra-authenticated; it is not the final production network-isolation design.
- Foundry alerts do not currently have a documented direct route to Azure Monitor action groups.
