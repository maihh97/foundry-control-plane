# Microsoft Foundry Control Plane — Zava demo kit

**Scenario:** a fictional "Zava Returns & Refunds Assistant" customer-service agent. The kit makes no claims about a real organization's systems or policies.

**Purpose.** Runnable code, config and short guides to show Foundry Control Plane managing a small *fleet* of AI agents in production: a prompt agent with two versions, a hosted agent, and a LangGraph custom agent — then observe them, evaluate them, cap their spend, guard them, gate their releases and switch them off.

**Automation map.** `AUTOMATION.md` states, step by step, what a coding agent can run unattended and which six steps are portal-only on the official record (account-level Add AI Gateway, Register asset, the Token management pane, Create guardrail policy, Block/Unblock for custom agents, Alerts) — with the official code-level equivalent where one exists (project-level gateway Bicep, APIM `llm-token-limit`, RAI policy ARM, `:disable`/`:enable` REST, evaluation-rule SDK).

**Grounding rule.** The implementation is based on the official Microsoft sources in `SOURCES.md`. Where public documentation leaves a gap, the kit ships a clearly labelled guide instead of invented code (`03-custom-agent/HOSTING-GAP.md`, `05-evaluation/alerts.md`). Files with abbreviated official samples carry `Verify against source before running: <URL>`.

## Status line (say it once, early)

> **Observability GA; Operate/Compliance/AI Gateway panes Preview.**
> Detail (Foundry GA readiness table, 08/14/2026): Operate Overview/Assets/Compliance = **Preview** · Manage AI Gateway = **Preview** · Build Tracing = "GA for prompt and hosted agents; Preview for workflow and external agents" · Evaluations = GA (some evaluators Preview) · Monitoring = **Preview** · Red teaming = GA · Guardrails — Models = GA; — Agents / Controls and intervention = **Preview**. "Observability in Foundry Control Plane is now generally available" (Microsoft blog, 16 Mar 2026). The Control Plane overview places all Operate "Key features" under the preview notice ("provided without a service-level agreement, and we don't recommend it for production workloads").

## 30-minute session plan

| Min | Module | What you show | Files |
|---|---|---|---|
| 0–3 | Intro | Status line; fleet slide; what Control Plane is vs Agent 365 ("Control Plane is for developers and AI engineers; Agent 365 is for IT and security admins") | — |
| 3–8 | **01 · Fleet view** (CORE) | **Operate > Overview** (scope project, date range) → **Operate > Assets > Agents**: Status, Version, Published as, Error rate, Estimated cost, Token usage, **Entra ID** columns; three agent sources (prompt, hosted, custom) | `01-infra/*`, `02-agents/*` (pre-run) |
| 8–14 | **03 · Custom agent + traces** (CORE) | LangGraph agent registered via **Register asset**; call it through the **APIM URL**; **Assets > [radio] > Traces** (Trace ID / Conversation ID); Monitor tab | `03-custom-agent/*`, `04-traffic/send_traffic.py` |
| 14–18 | **09 · Kill switch** (CORE) | Custom agent: **Update status > Block** → client fails → **Unblock**. Foundry agent: `az rest … :disable` → traffic rejected → `:enable`. Entra ID column → **Entra ID > Agents > Agent identities** | `09-identity-killswitch/*` |
| 18–23 | **06 · Token limits** (CORE) | **Manage > AI Gateway > Token management > + Set limit** → burst → **429**; lower quota → **403**. "Limits apply at the project level." "New limits apply immediately to subsequent requests." | `06-cost/*` |
| 23–28 | **05 · Continuous eval + alerts** (CORE) | Continuous eval rule on RESPONSE_COMPLETED; **Build > agent > Monitor** results; gear icon → **Alerts (preview)**; G-2 honesty line | `05-evaluation/continuous_eval_rule.py`, `alerts.md` |
| 28–30 | Wrap | Versions/rollback one-liner; CI gate slide; what's Preview; next steps | `02-agents/pin_or_rollback_version.sh`, `08-cicd/*` |

**OPTIONAL (if time / follow-up):** 02 hosted agent via azd (`hosted_agent_azd.sh`), 05 scheduled eval + red team (prompt agent only), 05 Insights, 07 guardrail policy → **Violations detected > Fix now** (pre-created), 07 RAI policy as code, 08 GitHub Action / ADO gate, 09 Agent 365 registry & licensing.

## Prerequisites

- Foundry **(new)** portal; project is **not** hub-based ("Classic agents and Azure OpenAI assistants aren't supported.").
- Tenant/subscription does **not** carry `AZML_DISABLE_PREVIEW_FEATURE=true` and no custom RBAC blocks preview operations (else Operate/Monitoring/Alerts are hidden). `00-prereqs/check_prereqs.sh` prints the account tags.
- Tooling: **az ≥ 2.80**, **azd ≥ 1.27.1** with **`azure.ai.agents` ≥ 1.0.0-beta.4** (`azd ext upgrade azure.ai.agents`), **Python ≥ 3.10**, `azure-ai-projects==2.7.0` (pinned in `requirements.txt`).
- Region: UK South supports projects and managed VNet; the hosted-agent demo template restricts to eastus2/francecentral/northcentralus/swedencentral; the AI Gateway *tier* preview is East US 2 / Sweden Central only. Check region before choosing.
- App Insights connected to the project (**Manage > Project details > Connected resources**, category **AppInsights**).
- AI Gateway on the Foundry resource (Basic v2 auto-created or existing v2 APIM), project enabled on it.

### Roles (short form — full table in `00-prereqs/roles.md`)

| Need | Role (documented) |
|---|---|
| New project via azd | Owner at RG scope (existing project: Foundry Project Manager) |
| AI Gateway / token limits | API Management Service Contributor (or Owner) on the APIM instance |
| Guardrail policies | Owner or Resource Policy Contributor at subscription/RG |
| Traces incl. GenAI content, trace evals | Log Analytics Reader **+ Privileged Monitoring Data Reader** on App Insights — users **and** project managed identity |
| Fleet cost column | Cost Management Reader on the subscription |
| Continuous evaluation | Project managed identity: Foundry User (was "Azure AI User") |
| Disable/enable a Foundry agent (REST) | Foundry User at project scope |
| Stop/start agent application deployment | Foundry Owner (was Azure AI Owner) |

## T-60 min pre-provisioning order (propagation timings are the docs' own)

1. `00-prereqs/check_prereqs.sh` (versions, `az account show`, tags, roles).
2. Infra: use `01-infra/deploy_foundry_basic.sh` when tenant policy prevents public customer-managed agent state, or `01-infra/deploy_foundry_standard.sh` when customer-managed Cosmos DB, Storage, and Search are reachable. Run `what-if`, review the preview, then run `apply`. Confirm **AppInsights** connection exists (or use the official full `connection-application-insights.bicep` source).
3. **AI Gateway**: use the portal account-level flow when available, or deploy the stable APIM fallback with `01-infra/configure_apim_gateway.bicep`; see `01-infra/ai-gateway.md`.
4. **Guardrail policy** (07) — create now: "Allow up to 30 minutes for the guardrail policy to appear".
5. Agents: `python 02-agents/prompt_agent_versions.py` (v1+v2, pinned to v2); optionally `02-agents/hosted_agent_azd.sh`.
6. **Register the custom agent AFTER App Insights** is connected (`03-custom-agent/register_custom_agent.md`) — "If you configured Application Insights after you registered the custom agent, you need to unregister the agent and register it again." Then copy the APIM URL into `.env`.
7. Traffic: `python 04-traffic/send_traffic.py --count 20` and `python 03-custom-agent/client_via_gateway.py` — "Wait up to 15 minutes for data to propagate after the first post-configuration run." Fleet metrics: "Metrics might take a few minutes to populate."
8. Continuous eval rule: `python 05-evaluation/continuous_eval_rule.py` (after granting the project MI Foundry User). Optional: `scheduled_eval_and_redteam.py`, `agent_insights.py`.
9. Dry-run the kill switch (`disable` → `enable`) and a token-limit burst; then **remove the limit** so the live run starts clean.

## Module index

| Folder | Files | Source of truth |
|---|---|---|
| `00-prereqs/` | `check_prereqs.sh`, `roles.md` | quickstart-hosted-agent, manage-hosted-agent, CHANGELOG, disable-preview-features, control-plane role tables |
| `01-infra/` | `deploy_foundry_basic.sh`, `deploy_foundry_standard.sh`, `connection-application-insights.bicep`, `configure_apim_gateway.bicep`, `ai-gateway.md`, `enable_project_ai_gateway.sh`, `fast-path-azd.md` | foundry-samples agent setup and connection templates; Azure Verified Modules API Management service; enable-ai-api-management-gateway-portal |
| `02-agents/` | `prompt_agent_versions.py`, `pin_or_rollback_version.sh`, `hosted_agent_azd.sh` | sample_agent_basic.py; manage-hosted-agent; quickstart-hosted-agent |
| `03-custom-agent/` | `langgraph_agent.py`, `register_custom_agent.md`, `client_via_gateway.py`, `external_agent_register.py`, `HOSTING-GAP.md` | opentelemetry-distro-python sample; register-custom-agent; sample_external_agents_crud.py; Gap G-1 |
| `04-traffic/` | `send_traffic.py` | sample_agent_basic.py / telemetry sample; how-to-manage-agents (15 min) |
| `05-evaluation/` | `continuous_eval_rule.py`, `scheduled_eval_and_redteam.py`, `red_team_prompt_agent.py`, `agent_insights.py`, `alerts.md` | sample_continuous_evaluation_rule.py; sample_scheduled_evaluations.py; sample_redteam_evaluations.py; agent-insights; monitor dashboard; Gap G-2 |
| `06-cost/` | `token_limit_demo.md`, `burst_test.py`, `apim-policies/zava-openai-gateway.xml`, `llm-token-limit.xml`, `llm-emit-token-metric.xml` | how-to-enforce-limits-models; AI-Gateway labs; llm-* policy references |
| `07-guardrails/` | `guardrail_policy_portal.md` (portal-only guardrail policy), `rai_policy_put.sh` (guardrail config as code), `azure_policy_definitions.sh` (official Foundry Azure Policy samples), `apim-policies/llm-content-safety.xml` | quickstart-create-guardrail-policy; how-to-manage-compliance-security; raiPolicies ARM; add-hosted-agent-guardrails; llm-content-safety |
| `08-cicd/` | `.github/workflows/agent-eval-gate.yml`, `data/dataset-tiny.json`, `eval.yaml`, `azure-devops-pipeline.yml` | microsoft/ai-agent-evals (v3-beta; AIAgentEvaluation@2); azure-developer-cli-evaluation |
| `09-identity-killswitch/` | `disable_enable_agent.sh`, `agent_identity_rbac.sh`, `entra_and_agent365_paths.md` | manage-hosted-agent; govern-agent-infrastructure-entra-admin; Entra agent-id admin; M365 agent registry |
| root | `.env.example`, `requirements.txt`, `SOURCES.md` | — |

## Run order (quick)

```bash
cp .env.example .env            # fill placeholders; never commit .env
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
bash 00-prereqs/check_prereqs.sh
python 02-agents/prompt_agent_versions.py
python 04-traffic/send_traffic.py --count 20
python 05-evaluation/continuous_eval_rule.py
python 06-cost/burst_test.py --count 15          # after setting a low TPM in Token management
bash 09-identity-killswitch/disable_enable_agent.sh disable && bash 09-identity-killswitch/disable_enable_agent.sh enable
```

## Known gaps you must not paper over

- **G-1** No official sample hosts a LangGraph *server* behind the AI Gateway → `03-custom-agent/HOSTING-GAP.md`.
- **G-2** No documented route from Foundry **Alerts (preview)** to Azure Monitor action groups → `05-evaluation/alerts.md`.
- **Red teaming hosted agents** is contradicted between sources → red-team the **prompt** agent only.
- **30 Sept 2026**: sensitive `gen_ai.*` content moves to the **`AppGenAIContent`** table — any custom KQL/alerts on AppDependencies/AppTraces/AppEvents break that week.
- **Agent 365 licensing** (effective 1 July 2026) gates agent discovery/security posture in Defender — see `09-identity-killswitch/entra_and_agent365_paths.md`.
