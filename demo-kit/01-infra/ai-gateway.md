<!--
Foundry Control Plane demo kit — 01 AI Gateway (Preview)
Derived from:
  https://learn.microsoft.com/en-us/azure/foundry/configuration/enable-ai-api-management-gateway-portal  (portal steps, verify, disable vs delete, troubleshooting)
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-enforce-limits-models              (APIM Service Contributor role; project-level limits)
  https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/01-connections/project-ai-gateway  (IaC)
  https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/01-connections/ai-gateway-tier     (optional hub-and-spoke tier, preview)
  https://learn.microsoft.com/en-us/azure/api-management/genai-gateway-capabilities                          ("AI gateway in Microsoft Foundry (preview)")
-->
# 01 · AI Gateway — enable it on the Foundry resource (Preview)

> **Automation status (verified 24 Sep 2026 — see `AUTOMATION.md`).** *Account-level* **Add AI Gateway** is documented only in the Foundry portal — the Learn article is "how to enable AI Gateway for a Microsoft Foundry resource by using the Foundry portal"; no REST/CLI/Bicep is published for it. *Project-level* enablement **is** official Bicep (`project-ai-gateway.bicep`, run by `01-infra/enable_project_ai_gateway.sh`), and the preview **AI Gateway tier** is fully Bicep (`ai-gateway-tier/main.bicep`). Sequence for a coding-agent hand-off: human adds the gateway once → agent enables projects from code.

**Why it matters for the demo:** the AI Gateway is the prerequisite for **registering custom agents** (03), **token limits → 429/403** (06) and **Block/Unblock** of custom agents (09). Status: **Manage > AI Gateway = Preview** (Foundry GA readiness table).

Learn (verbatim): "Agents: Register agents running anywhere - Azure, other clouds, or on-premises - into the Foundry control plane for centralized inventory and governance. View telemetry in Foundry or Application Insights, and apply policies such as throttling or content safety."

## Portal steps (pre-provision at T-60 min)

1. Foundry portal (new) → toolbar **Manage** → left pane **AI Gateway**.
2. **Add AI Gateway** → select the Foundry resource → **Create new** (creates an API Management **Basic v2** instance — "typically provision within 5-10 minutes") **or** **Use existing APIM** → **Add**.
   - Existing-APIM eligibility (verbatim): "The API Management instance is in the same Microsoft Entra tenant and the same subscription as the Foundry resource. You have at least the API Management Service Contributor role (or Owner) on the API Management instance. You can access the API Management instance from the Foundry portal. The API Management instance is created in one of the v2 tiers."
3. Projects: "New projects created in the Foundry resource have AI Gateway enabled by default. Existing projects must be enabled manually" → select the gateway → **Add project to gateway**.
4. Architecture note (verbatim): "All requests flow through the APIM instance once associated. Limits apply at the project level, so each project can have its own TPM and quota settings." · "You enable AI Gateway at the Foundry resource level, and all projects in that resource share the same gateway."

## Verify traffic is flowing through the gateway

Azure portal → the API Management instance:

- **Monitoring > Metrics** → Metric dropdown **Requests** (verbatim step).
- For logs: **Monitoring > Diagnostic settings > Add diagnostic setting** → "Select Logs related to ApiManagement Gateway, send the logs to a Log Analytics workspace, and select **Resource specific** as the destination table."
- **Monitoring > Logs** — KQL (verbatim):

```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
```

## IaC alternative (agent-runnable)

Run `bash 01-infra/enable_project_ai_gateway.sh` (env: `FOUNDRY_RG`, `ACCOUNT_NAME`, `PROJECT_NAME`, `APIM_RESOURCE_ID`). It wraps the official command below.

- **New project on an already gateway-enabled account:** `01-connections/project-ai-gateway` — "This sample creates a new Azure AI Foundry project under an existing, already AI-Gateway-enabled Foundry account and enables the AI Gateway on the new project by default." Deploys the project, an APIM Product, Product↔API association, an APIM Subscription and "ARM resource link (Microsoft.Resources/links) from the project to the product. The presence of this link is what marks the project as Enabled on the gateway." Params: `aiFoundryAccountName`, `projectName`, `apimResourceId` (required), `sharedApiId`.

  ```bash
  az deployment group create \
    --resource-group <foundry-rg> \
    --template-file project-ai-gateway.bicep \
    --parameters @samples/parameters.json
  ```

- **Optional hub-and-spoke tier:** `01-connections/ai-gateway-tier` — APIM **AIGateway SKU**, "release-gated public preview… currently East US 2 and Sweden Central". `tokensPerMinute` default `100` — "Low by default so a burst test visibly throttles (HTTP 429)." Not needed for the Zava demo; mention only if asked about central platform teams.

- **Private Foundry:** templates 15/16/18; note a portal-created AI Gateway on a private Foundry "is automatically public"; "use a Standard v2 or Premium v2 instance with a private endpoint, or a Premium v2 instance that's injected in a virtual network."

## Disable vs Delete (verbatim)

"**Disable** stops routing a single project's traffic through the gateway… **Delete** removes the gateway from the Foundry resource and, when you also delete the underlying API Management instance, fully removes the gateway and stops its charges." Steps: **Manage > AI Gateway** → gateway name → locate project → **Remove project from gateway**; then delete from the Foundry resource; then in the Azure portal "Delete the API Management instance that has the same name as the AI Gateway".

## Troubleshooting rows to have ready

| Problem | Action (verbatim) |
|---|---|
| API Management instance doesn't appear | "Refresh after a few minutes." |
| Limits aren't enforced | "Reopen settings and confirm that the enforcement toggle is on. Confirm that AI Gateway is enabled for the project and that correct limits are configured." |
| Latency is high after enablement | "Check API Management region versus resource region. Call the model directly and compare the result with the call proxied through AI Gateway" |
| 500 errors on model calls after gateway setup | "The auto-created APIM endpoints may not be fully provisioned… try removing and re-adding the project to the gateway." |
| Existing APIM does not appear | "Verify that the API Management instance is in the same tenant and uses a supported service tier" |

"If the AI Gateway pane is slow, retry after a brief interval."
