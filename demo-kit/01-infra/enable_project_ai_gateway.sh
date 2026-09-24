#!/usr/bin/env bash
# Foundry Control Plane demo kit — 01 enable the AI Gateway on a project with Bicep (agent-runnable)
# Derived from (README verbatim):
#   https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/01-connections/project-ai-gateway
#   "This sample creates a new Azure AI Foundry project under an existing, already AI-Gateway-enabled Foundry account and
#    enables the AI Gateway on the new project by default."
#   Deploys: Project (Microsoft.CognitiveServices/accounts/projects); APIM Product (subscriptionRequired: true, state: 'published');
#   Product <-> API association; APIM Subscription; "ARM resource link (Microsoft.Resources/links) from the project to the product.
#   The presence of this link is what marks the project as Enabled on the gateway."
#   Prerequisites: "An existing Azure AI Foundry account that already fronts an AI Gateway (i.e. an APIM service)."
#                  "The full ARM resource id of the APIM service that backs the account gateway."
# Automation status (verified 24 Sep 2026, see AUTOMATION.md): the ACCOUNT-level "Add AI Gateway" is documented only in the
#   Foundry portal (https://learn.microsoft.com/en-us/azure/foundry/configuration/enable-ai-api-management-gateway-portal).
#   Do that once by hand; this script then enables further PROJECTS on that gateway from code.
# Usage: FOUNDRY_RG=<foundry-rg> ACCOUNT_NAME=<account> PROJECT_NAME=<new-project> APIM_RESOURCE_ID=</subscriptions/.../Microsoft.ApiManagement/service/<name>> \
#        bash 01-infra/enable_project_ai_gateway.sh
set -euo pipefail

if [ -f "$(dirname "$0")/../.env" ]; then
  # shellcheck disable=SC1091
  set -a; . "$(dirname "$0")/../.env"; set +a
fi

FOUNDRY_RG="${FOUNDRY_RG:?set FOUNDRY_RG}"
ACCOUNT_NAME="${ACCOUNT_NAME:?set ACCOUNT_NAME (existing, gateway-enabled Foundry account)}"
PROJECT_NAME="${PROJECT_NAME:?set PROJECT_NAME (new project to create)}"
APIM_RESOURCE_ID="${APIM_RESOURCE_ID:?set APIM_RESOURCE_ID (ARM id of the APIM service backing the account gateway)}"
CLONE_DIR="${CLONE_DIR:-./foundry-samples}"
TEMPLATE_DIR="${CLONE_DIR}/infrastructure/infrastructure-setup-bicep/01-connections/project-ai-gateway"

if [ ! -d "${TEMPLATE_DIR}" ]; then
  git clone https://github.com/microsoft-foundry/foundry-samples.git "${CLONE_DIR}"
fi

# README step 1: "Edit samples/parameters.json with your account name, project name, and APIM resource id"
# Written here from environment variables instead of editing the sample file. Parameter names are the README's:
#   aiFoundryAccountName (Yes) · projectName (Yes) · apimResourceId (Yes) · projectDisplayName / projectDescription / location / sharedApiId (No)
PARAMS_FILE="$(mktemp)"
cat > "${PARAMS_FILE}" <<EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "aiFoundryAccountName": { "value": "${ACCOUNT_NAME}" },
    "projectName":          { "value": "${PROJECT_NAME}" },
    "apimResourceId":       { "value": "${APIM_RESOURCE_ID}" }
  }
}
EOF

# README step 2 (verbatim command shape): "Deploy into the resource group / subscription where the Foundry account lives"
az deployment group create \
  --resource-group "${FOUNDRY_RG}" \
  --template-file "${TEMPLATE_DIR}/project-ai-gateway.bicep" \
  --parameters @"${PARAMS_FILE}"

rm -f "${PARAMS_FILE}"

echo
echo "Outputs per README: projectResourceId, projectPrincipalId, productName, gatewayProductScope"
echo "Verify in the portal: Manage > AI Gateway > <gateway> > project list > Gateway status = Enabled"
echo "Verify traffic: APIM > Monitoring > Metrics > Requests  (or KQL: ApiManagementGatewayLogs | where TimeGenerated > ago(1h))"
