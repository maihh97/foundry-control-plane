#!/usr/bin/env bash
# Foundry Control Plane demo kit — 00 pre-flight checks
# Derived from:
#   https://learn.microsoft.com/en-us/azure/foundry/agents/quickstarts/quickstart-hosted-agent   (azd >= 1.27.1; azd ext show azure.ai.agents >= 1.0.0-beta.4)
#   https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/manage-hosted-agent            (Azure CLI 2.80 or later)
#   https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/CHANGELOG.md (Python >= 3.10 since 2.5.0)
#   https://learn.microsoft.com/en-us/azure/foundry/how-to/disable-preview-features             (AZML_DISABLE_PREVIEW_FEATURE tag)
#   https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-agents           (roles table)
# Usage: bash 00-prereqs/check_prereqs.sh   (reads ACCOUNT_NAME / AZURE_RESOURCE_GROUP_NAME from .env if present)
set -u

if [ -f "$(dirname "$0")/../.env" ]; then
  # shellcheck disable=SC1091
  set -a; . "$(dirname "$0")/../.env"; set +a
fi

echo "== Tool versions (floors from the docs: az >= 2.80, azd >= 1.27.1, azure.ai.agents >= 1.0.0-beta.4, Python >= 3.10) =="
echo "-- az version --";      az version --output tsv 2>/dev/null || echo "az not found"
echo "-- azd version --";     azd version 2>/dev/null || echo "azd not found"
echo "-- azd ext show azure.ai.agents --"; azd ext show azure.ai.agents 2>/dev/null || echo "azure.ai.agents extension not installed (azd ext install azure.ai.agents)"
echo "-- python --version --"; python --version 2>/dev/null || python3 --version 2>/dev/null || echo "python not found"
echo "   Upgrade path from the quickstart troubleshooting: azd ext upgrade azure.ai.agents"

echo
echo "== Signed-in Azure context =="
az account show

echo
echo "== Preview-feature tag reminder =="
echo "Operate panes, Monitoring and Alerts are Preview and are hidden when the resource/subscription carries AZML_DISABLE_PREVIEW_FEATURE=true"
echo "or a custom RBAC role blocks preview operations."
if [ -n "${ACCOUNT_NAME:-}" ] && [ -n "${AZURE_RESOURCE_GROUP_NAME:-}" ]; then
  echo "-- tags on Microsoft.CognitiveServices/accounts/${ACCOUNT_NAME} --"
  az resource show --name "${ACCOUNT_NAME}" --resource-group "${AZURE_RESOURCE_GROUP_NAME}" \
    --resource-type "Microsoft.CognitiveServices/accounts" --query tags --output json
else
  echo "Set ACCOUNT_NAME and AZURE_RESOURCE_GROUP_NAME in .env to print the account tags."
fi

echo
echo "== Roles reminder (see 00-prereqs/roles.md) =="
echo " * Foundry Project Manager (existing project) or Owner at RG scope (new project)  - hosted-agent quickstart"
echo " * API Management Service Contributor (or Owner) on the APIM instance             - AI Gateway / token limits"
echo " * Owner or Resource Policy Contributor at subscription/RG                        - guardrail policies"
echo " * Log Analytics Reader + Privileged Monitoring Data Reader on App Insights       - users AND the project managed identity"
echo " * Cost Management Reader on the subscription                                     - Estimated cost column"
echo " * Foundry User (was Azure AI User) for the project managed identity              - continuous evaluation"
echo
echo "Portal reminder: use the Microsoft Foundry (new) portal; hub-based projects are not supported by Control Plane."
