# Microsoft Foundry control-plane demo

This repository contains a deployment and operations demo for managing a fictional **Zava Returns & Refunds Assistant** fleet with Microsoft Foundry.

The demo covers:

- Foundry account and project provisioning
- Prompt, hosted, and external/custom agent patterns
- Application Insights tracing and agent evaluation
- Azure API Management as an AI gateway
- Token limits and token metrics
- Guardrails and Azure Policy examples
- Agent identity, disable/enable controls, and rollback
- A GitHub Actions evaluation gate

> The repository uses a fictional organization and synthetic scenarios. It does not describe a real customer's systems, policies, or production architecture.

## Repository layout

All deployable assets are under [`demo-kit/`](demo-kit/):

| Path | Purpose |
|---|---|
| `00-prereqs/` | Tooling, Azure context, and role checks |
| `01-infra/` | Standard Foundry deployment and AI Gateway setup |
| `02-agents/` | Prompt and hosted-agent versioning |
| `03-custom-agent/` | LangGraph tracing and supported registration options |
| `04-traffic/` | Controlled demo traffic |
| `05-evaluation/` | Continuous/scheduled evaluation, red teaming, and alerts guidance |
| `06-cost/` | Token limits, metrics, and burst validation |
| `07-guardrails/` | Guardrail, content-safety, and Azure Policy examples |
| `08-cicd/` | Evaluation datasets and CI examples |
| `09-identity-killswitch/` | Identity inspection and agent disable/enable controls |

The active GitHub Actions workflow is [`/.github/workflows/agent-eval-gate.yml`](.github/workflows/agent-eval-gate.yml).

## Interactive demo website

The agent anatomy, security posture, end-to-end flow, and presenter checklist are published at:

<https://maihh97.github.io/foundry-control-plane/>

The site explains why hosted-agent source configuration is not fully visible in the portal and links back to the authoritative `azure.yaml`, Python source, policies, and runbooks.

Use [`demo-kit/DEMO-RUNBOOK.md`](demo-kit/DEMO-RUNBOOK.md) for the complete presenter route and [`demo-kit/07-guardrails/DEFENDER-PURVIEW-DEMO.md`](demo-kit/07-guardrails/DEFENDER-PURVIEW-DEMO.md) for the Defender and Purview-specific story.

## Target environment

The included deployment plan targets:

- Azure region: `swedencentral`
- Resource group: `rg-foundry-control-plane`
- Scenario prefix: `zava`

Resource names that must be globally unique should be selected during deployment rather than hardcoded in source.

This deployment uses Microsoft Foundry **Basic Agent Setup** because the target tenant enforces private access on customer-managed Cosmos DB. Basic setup uses Microsoft-managed multitenant agent state and avoids weakening that policy. The standard setup remains available for subscriptions where its customer-managed dependencies are reachable.

## Prerequisites

- Azure CLI 2.80 or later
- Azure Developer CLI 1.27.1 or later
- `azure.ai.agents` azd extension 1.0.0-beta.4 or later
- Python 3.10 or later
- Bash-compatible shell for the supplied scripts
- Permission to create resources and role assignments in the target subscription
- API Management and policy permissions for gateway and governance modules

Review the complete role matrix in [`demo-kit/00-prereqs/roles.md`](demo-kit/00-prereqs/roles.md).

## Local setup

```bash
cd demo-kit
cp .env.example .env
python -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements.txt
bash 00-prereqs/check_prereqs.sh
```

Populate `.env` with deployment outputs and local secrets. The file is ignored by Git and must never be committed.

## Deployment sequence

1. Run the prerequisite checks.
2. Validate the Basic Agent Setup deployment with `bash 01-infra/deploy_foundry_basic.sh what-if`.
3. After reviewing the preview, provision the Foundry account, project, and model deployment with `bash 01-infra/deploy_foundry_basic.sh apply`.
4. Connect Application Insights and assign the documented trace/evaluation roles.
5. Deploy or select an API Management service and apply
   [`configure_apim_gateway.bicep`](demo-kit/01-infra/configure_apim_gateway.bicep)
   to configure managed-identity model access, a protected Responses API, and
   the 100-TPM demo limit.
6. Use the Foundry portal account-level AI Gateway flow when that preview is
   enabled for the target tenant; otherwise use the stable APIM endpoint.
7. Create and version the prompt agent; optionally deploy the hosted agent.
8. Register the external/custom agent using one of the supported patterns.
9. Generate traffic and validate traces.
10. Configure evaluation, token controls, guardrails, and identity controls.
11. Configure GitHub repository variables and secrets, then run the evaluation workflow manually.

Detailed commands and limitations are documented in [`demo-kit/README.md`](demo-kit/README.md) and [`demo-kit/AUTOMATION.md`](demo-kit/AUTOMATION.md).

The deployable hosted-agent project is under
[`demo-kit/02-agents/zava-hosted-returns/zava-hosted-returns/`](demo-kit/02-agents/zava-hosted-returns/zava-hosted-returns/).
Before redeploying it, set the active azd environment's `RAI_POLICY_RESOURCE_ID`
to the full ARM ID of the RAI policy created by
[`demo-kit/07-guardrails/rai_policy_put.sh`](demo-kit/07-guardrails/rai_policy_put.sh).

## Portal-only operations

Current Microsoft documentation requires portal interaction for these control-plane experiences:

- Account-level **Add AI Gateway**
- **Register asset** for a true custom agent
- Foundry Token management UI
- Guardrail policy creation
- Custom-agent Block/Unblock
- Alerts configuration

Where Microsoft publishes an API, SDK, Bicep, or APIM policy equivalent, the repository links to that alternative.

For environments where the Foundry account-level AI Gateway preview is not
available, this repository includes a stable APIM alternative. It uses
system-assigned managed identity for the model backend and requires an APIM
subscription key from callers.

## GitHub Actions configuration

The workflow uses Azure service-principal credentials stored in the `AZURE_CREDENTIALS` GitHub secret. It also expects these repository variables:

- `AZURE_AI_PROJECT_ENDPOINT`
- `DEPLOYMENT_NAME`

`AZURE_CREDENTIALS` must contain the JSON object accepted by `azure/login`. Scope the service principal to the smallest Azure scope that supports the evaluation workflow, rotate the secret regularly, and migrate to workload identity federation when practical.

## Validation

Before treating the deployment as complete, verify:

- Foundry project and model deployment are available.
- Application Insights receives agent traces.
- Prompt and hosted agents can be invoked.
- Gateway-routed requests succeed.
- Continuous evaluation completes.
- Token-limit tests produce the expected 429/403 behavior.
- Guardrail tests block the intended unsafe request.
- Agent disable/enable operations reject and restore traffic.
- The GitHub Actions evaluation gate completes successfully.

## Cleanup and rollback

Use version selection or pinning to roll agents back. Remove or raise APIM limits to undo throttling, disable project gateway linkage to remove gateway routing, and use the agent enable endpoint to recover from a kill-switch test.

Do not run broad teardown commands without reviewing the target resource group. In particular, `azd down` can delete the resource group created by its environment.

API Management Developer is a continuously billed demo resource. Remove it
after the demonstration if the stable gateway is no longer needed.

## Important limitations

- Several Foundry control-plane and monitoring experiences are preview features.
- The repository does not invent an unsupported LangGraph server-hosting pattern for custom-agent registration.
- Foundry Alerts do not currently have a documented direct mapping to Azure Monitor action groups.
- Evaluation and red-team runs can incur model and safety-evaluation charges.

See [`demo-kit/SOURCES.md`](demo-kit/SOURCES.md) for official Microsoft references.
