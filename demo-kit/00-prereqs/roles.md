<!--
Foundry Control Plane demo kit — roles table
Derived from (verbatim role names as documented):
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-agents
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/monitoring-across-fleet
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-compliance-security
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-enforce-limits-models
  https://learn.microsoft.com/en-us/azure/foundry/configuration/enable-ai-api-management-gateway-portal
  https://learn.microsoft.com/en-us/azure/foundry/agents/quickstarts/quickstart-hosted-agent
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/govern-agent-infrastructure-entra-admin
  https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-bicep/01-connections/connection-application-insights.bicep
  https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/agent-insights
  https://learn.microsoft.com/en-us/entra/agent-id/manage-agent-identities-admin
-->
# Roles needed for the Zava demo

> Role rename notice (verbatim): "Foundry User, Foundry Owner, Foundry Account Owner, and Foundry Project Manager were previously named Azure AI User, Azure AI Owner, Azure AI Account Owner, and Azure AI Project Manager… The role IDs and core permissions are unchanged by the rename." SDK sample docstrings still say "Azure AI User" (role id `53ca6127-db72-4b80-b1b0-d745d6d5456d`).

## Control Plane (Operate) — permissions model table (verbatim, how-to-manage-agents)

| Role | Scope | Capabilities |
|---|---|---|
| Reader | Resource, resource group, or subscription | View agent inventory and traces |
| Contributor | Resource, resource group, or subscription | View and perform lifecycle operations (start, stop, block) |
| Owner | Resource, resource group, or subscription | Full management, including permissions |

"These roles are the minimum requirements. Custom roles with equivalent permissions also work."

## Per task

| Task (demo module) | Minimum role as documented | Source |
|---|---|---|
| Create a new Foundry project with `azd ai agent init` (02) | "Owner role at resource group scope"; existing project: "Foundry Project Manager at project scope" | quickstart-hosted-agent |
| See fleet metrics, Estimated cost (01) | Read access to project + subscription; "Log Analytics Reader role or higher on the Application Insights resource"; "Cost Management Reader role" | monitoring-across-fleet |
| Read GenAI prompt/response content in traces & trace evaluations (03/05) | Log Analytics Reader (`73c42c96-874c-492b-b04d-ab87d138a893`) **plus** Privileged Monitoring Data Reader (`dbc9c667-e97f-4491-aee6-90b9cf960190`) on App Insights — for users **and** the project managed identity | connection-application-insights.bicep; traces-sensitive-content |
| Continuous evaluation rule (05) | Project managed identity: "Azure AI User" (= Foundry User) on the project | sample_continuous_evaluation_rule.py docstring |
| Insights (05, optional) | Prompt agent → Foundry User; hosted agent → Foundry Project Manager; Monitoring Reader on App Insights for user and project MI; Privileged Monitoring Data Reader if `AppGenAIContent` is protected | agent-insights |
| Enable AI Gateway / set token limits (01/06) | "API Management Service Contributor role (or Owner) on the Azure API Management resource"; creating a new APIM: Contributor or Owner on the target RG | how-to-enforce-limits-models; enable-ai-api-management-gateway-portal |
| Create/edit guardrail policies (07) | "Owner or Resource Policy Contributor at the Azure subscription or resource group level" | how-to-manage-compliance-security |
| Enable Defender for Cloud (optional) | "Security Admin role or the Owner role for a subscription" | how-to-manage-compliance-security |
| Configure Purview integration (optional) | "Foundry Account Owner role" | how-to-manage-compliance-security |
| Disable/enable a Foundry agent via REST (09) | Foundry agent tab: View → Foundry User (Reader isn't sufficient); Disable or enable → Foundry User; Delete → Foundry User | govern-agent-infrastructure-entra-admin (rendered 06/30/2026) |
| Stop/start an agent application deployment (09) | "Stop or start an agent deployment — Azure AI Owner"; "View deployments within an agent application — Azure AI User (Reader is not sufficient)" | govern-agent-infrastructure-entra-admin (02/27/2026 snapshot) |
| View agent identities in Entra admin center (09) | "No admin role needed for viewing"; manage → Agent ID Administrator or Cloud Application Administrator | manage-agent-identities-admin |

Scope guidance (verbatim): "For Foundry agents, assign the role over just the Foundry project resource you want to work with. For agent applications, assign the role at the application scope… Don't assign these roles at the subscription or management group scope."

Propagation: "Role assignment changes can take up to 10 minutes to propagate."
