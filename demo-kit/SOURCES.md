<!-- Foundry Control Plane demo kit — official URLs grouped by module. -->
# Sources by module

## Cross-cutting (README, roles, status line)
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/overview
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/control-plane/overview.md
- https://learn.microsoft.com/en-us/azure/foundry/concepts/general-availability (Feature readiness table)
- https://blogs.microsoft.com/blog/2026/03/16/microsoft-at-nvidia-gtc-new-solutions-for-microsoft-foundry-azure-ai-infrastructure-and-physical-ai/
- https://azure.microsoft.com/en-us/products/ai-foundry/observability
- https://azure.microsoft.com/en-us/products/ai-foundry/control-plane
- https://learn.microsoft.com/en-us/azure/foundry/how-to/disable-preview-features
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-agents
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/control-plane/how-to-manage-agents.md
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/monitoring-across-fleet
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/control-plane/monitoring-across-fleet.md
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/includes/control-plane-prereqs.md
- https://learn.microsoft.com/en-us/azure/foundry/guardrails/guardrails-overview (role rename notice)
- https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/traces-sensitive-content (AppGenAIContent, 30 Sept 2026)
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/observability/how-to/traces-sensitive-content.md
- https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/CHANGELOG.md (2.7.0; Python 3.10 floor)
- https://github.com/Azure/agentops (AgentOps Accelerator, v0.15.1)
- https://devblogs.microsoft.com/foundry/whats-new-in-microsoft-foundry-oct-nov-2025/ (Ignite 2025 announcement)
- https://devblogs.microsoft.com/foundry/whats-new-in-microsoft-foundry-july-august-2026/ (Hosted Agents GA)

## 00-prereqs
- https://learn.microsoft.com/en-us/azure/foundry/agents/quickstarts/quickstart-hosted-agent (azd ≥ 1.27.1; azure.ai.agents ≥ 1.0.0-beta.4; roles)
- https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/manage-hosted-agent (az ≥ 2.80)
- https://learn.microsoft.com/en-us/azure/foundry/how-to/disable-preview-features (AZML_DISABLE_PREVIEW_FEATURE)
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-compliance-security (roles)
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-enforce-limits-models (APIM Service Contributor)
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/govern-agent-infrastructure-entra-admin (role tables, scope guidance)
- https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/agent-insights (Insights roles)
- https://learn.microsoft.com/en-us/entra/agent-id/manage-agent-identities-admin (Entra roles)

## 01-infra
- https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep
- https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/41-standard-agent-setup
- https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-bicep/01-connections/connection-application-insights.bicep
- https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/01-connections
- https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/01-connections/project-ai-gateway
- https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/01-connections/ai-gateway-tier
- https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/16-private-network-standard-agent-apim-setup
- https://learn.microsoft.com/en-us/azure/foundry/configuration/enable-ai-api-management-gateway-portal
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/configuration/enable-ai-api-management-gateway-portal.md
- https://learn.microsoft.com/en-us/azure/api-management/genai-gateway-capabilities
- https://learn.microsoft.com/en-us/azure/foundry/how-to/configure-private-link (portal-created gateway on private Foundry is public)
- https://github.com/Azure-Samples/get-started-with-ai-agents
- https://github.com/Azure-Samples/get-started-with-ai-agents/blob/main/docs/observability.md

## 02-agents
- https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/agents/sample_agent_basic.py
- https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/ai/azure-ai-projects/samples/agents
- https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/manage-hosted-agent (version_selector PATCH; disable/enable; identity)
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/agents/how-to/manage-hosted-agent.md
- https://learn.microsoft.com/en-us/azure/foundry/agents/quickstarts/quickstart-hosted-agent
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/agents/quickstarts/quickstart-hosted-agent.md
- https://github.com/microsoft-foundry/foundry-samples/tree/main/samples/python/hosted-agents (README)
- https://github.com/microsoft-foundry/foundry-samples/blob/main/samples/python/hosted-agents/agent-framework/responses/01-basic/azure.yaml
- https://github.com/microsoft-foundry/foundry-samples/blob/main/samples/python/hosted-agents/agent-framework/responses/08-observability/azure.yaml
- https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/cli-agent-development (azd extension; `azd ai agent deploy` removed)
- https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/development-lifecycle (immutable versions)
- https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/migrate-agent-applications (version_selector, stable endpoint)

## 03-custom-agent
- https://github.com/microsoft/opentelemetry-distro-python
- https://github.com/microsoft/opentelemetry-distro-python/tree/main/samples/langchain
- https://github.com/microsoft/opentelemetry-distro-python/blob/main/samples/langchain/sample_langchain_instrumentation.py
- https://learn.microsoft.com/en-us/python/api/opentelemetry-python/opentelemetry-overview
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/register-custom-agent
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/control-plane/register-custom-agent.md
- https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/register-external-agent
- https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/agents/sample_external_agents_crud.py
- https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/trace-agent-framework (LangChain/LangGraph pip line; MAF distro snippet)
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/how-to/develop/langchain-traces.md
- https://github.com/microsoft-foundry/foundry-samples/tree/main/samples/python/hosted-agents/langgraph (hosted LangGraph, sample 08 Observability)
- https://github.com/microsoft/agent-framework/blob/main/python/samples/02-agents/observability/foundry_tracing.py
- https://github.com/Azure-Samples/AI-Gateway/tree/main/labs/ai-foundry-hosted-agents

## 04-traffic
- https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/agents/sample_agent_basic.py
- https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/agents/telemetry/sample_agent_basic_with_azure_monitor_tracing.py
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-agents (15-minute propagation)
- https://github.com/Azure-Samples/foundry-hosted-agentframework-demos (README lists send_requests.py / locustfile.py — not verified in tree)

## 05-evaluation
- https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/ai/azure-ai-projects/samples/evaluations
- https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/evaluations/sample_continuous_evaluation_rule.py
- https://learn.microsoft.com/en-us/python/api/azure-ai-projects/azure.ai.projects.models.continuousevaluationruleaction?view=azure-python
- https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/evaluations/sample_scheduled_evaluations.py
- https://ai.azure.com/api-reference/llm/schedules/create-or-update.md
- https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/evaluations/sample_redteam_evaluations.py
- https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/red_team/sample_red_team.py
- https://ai.azure.com/api-reference/redteams/create/
- https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/evaluations/sample_agent_evaluation.py (evaluator ids)
- https://github.com/Azure-Samples/get-started-with-ai-agents/blob/main/tests/test_red_teaming.py
- https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/agent-insights
- https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/ai/azure-ai-projects/samples/agent_insights
- https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/how-to-monitor-agents-dashboard
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/observability/how-to/how-to-monitor-agents-dashboard.md
- https://learn.microsoft.com/en-us/azure/defender-for-cloud/ai-threat-protection
- https://devblogs.microsoft.com/foundry/build-2026-from-observability-to-roi-for-ai-agents-on-any-framework/

## 06-cost
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-enforce-limits-models
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/control-plane/how-to-enforce-limits-models.md
- https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy
- https://learn.microsoft.com/en-us/azure/api-management/llm-emit-token-metric-policy
- https://github.com/Azure-Samples/AI-Gateway
- https://github.com/Azure-Samples/AI-Gateway/blob/main/labs/token-rate-limiting/policy.xml
- https://github.com/Azure-Samples/AI-Gateway/blob/main/labs/token-metrics-emitting/policy.xml
- https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/model-router
- https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/add-hosted-agent-guardrails (raw responses endpoint used for the curl alternative)

## 07-guardrails
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/quickstart-create-guardrail-policy
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/control-plane/quickstart-create-guardrail-policy.md
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-compliance-security
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/control-plane/how-to-manage-compliance-security.md
- https://learn.microsoft.com/en-us/azure/foundry/guardrails/guardrails-overview
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/guardrails/how-to-create-guardrails.md
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/guardrails/intervention-points.md
- https://learn.microsoft.com/en-us/rest/api/aiservices/accountmanagement/rai-policies/create-or-update?view=rest-aiservices-accountmanagement-2024-10-01
- https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/add-hosted-agent-guardrails
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/agents/how-to/add-hosted-agent-guardrails.md
- https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/default-safety-policies
- https://github.com/microsoft-foundry/foundry-samples (samples/python/hosted-agents/agent-framework/responses/16-content-safety-guardrail)
- https://learn.microsoft.com/en-us/azure/api-management/llm-content-safety-policy
- https://learn.microsoft.com/en-us/azure/defender-for-cloud/ai-onboarding
- https://learn.microsoft.com/en-us/purview/ai-azure-foundry

## 08-cicd
- https://github.com/microsoft/ai-agent-evals
- https://github.com/microsoft/ai-agent-evals/blob/main/action.yml
- https://github.com/microsoft/ai-agent-evals/blob/main/samples/workflows/multiple-agents.yml
- https://github.com/microsoft/ai-agent-evals/blob/main/samples/workflows/ado-multiple-agents.yml
- https://github.com/microsoft/ai-agent-evals/blob/main/samples/data/dataset-tiny.json
- https://github.com/microsoft/ai-agent-evals/blob/main/overview.md
- https://github.com/microsoft/ai-agent-evals/blob/main/vss-extension.json
- https://github.com/microsoft/ai-agent-evals/releases
- https://learn.microsoft.com/en-us/azure/foundry/how-to/evaluation-github-action
- https://learn.microsoft.com/en-us/azure/foundry/how-to/evaluation-azure-devops
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/how-to/evaluation-azure-devops.md
- https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/azure-developer-cli-evaluation
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/observability/how-to/azure-developer-cli-evaluation.md
- https://learn.microsoft.com/en-us/azure/foundry/observability/quickstarts/quickstart-evaluate-hosted-agent
- https://github.com/microsoft-foundry/agent-optimization-workshop (threshold-gate pattern; WIP)

## 09-identity-killswitch
- https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/manage-hosted-agent
- https://ai.azure.com/api-reference/agent-versions/get-agent-version/
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/govern-agent-infrastructure-entra-admin
- https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/control-plane/govern-agent-infrastructure-entra-admin.md
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-agents (Block/Unblock; Entra ID column)
- https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/agent-identity
- https://learn.microsoft.com/en-us/entra/agent-id/manage-agent-identities-admin
- https://github.com/MicrosoftDocs/entra-docs/blob/main/docs/agent-id/manage-agent-identities-admin.md
- https://learn.microsoft.com/en-us/entra/agent-id/create-blueprint
- https://learn.microsoft.com/en-us/microsoft-365/admin/manage/agent-registry?view=o365-worldwide
- https://learn.microsoft.com/en-us/microsoft-agent-365/admin/connected-platforms
- Defender for Cloud AI agent inventory / Defender XDR "Security for AI Agents" licensing pages

## AUTOMATION.md and the 24 Sep 2026 verification (portal-only vs. code)
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/overview ("You can currently access these features through the Foundry portal only.")
- https://learn.microsoft.com/en-us/azure/foundry/configuration/enable-ai-api-management-gateway-portal (account-level Add AI Gateway — portal)
- https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/01-connections/project-ai-gateway (project-level enablement — Bicep; used by `01-infra/enable_project_ai_gateway.sh`)
- https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/01-connections/ai-gateway-tier (AI Gateway tier — Bicep, preview)
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/register-custom-agent (Register asset, Block/Unblock — portal)
- https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/register-external-agent (external agent — SDK alternative)
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-enforce-limits-models (Token management pane — portal; links to APIM policy)
- https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy (429/403 enforcement as APIM policy)
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/quickstart-create-guardrail-policy (guardrail policy — portal-only)
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-compliance-security (Azure Policy backing; roles)
- https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/05-custom-policy-definitions (official Foundry Azure Policy samples; used by `07-guardrails/azure_policy_definitions.sh`)
- https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-agents (lifecycle operations — portal)
- https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/manage-hosted-agent (`:disable` / `:enable` REST)
- https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/how-to-monitor-agents-dashboard (Alerts (preview) — portal; evaluation SDK)
