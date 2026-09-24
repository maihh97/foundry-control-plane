#!/usr/bin/env bash
# Foundry Control Plane demo kit — 09 Entra Agent ID: read the agent's own identity principal and grant it a scoped role
# Derived from (verbatim):
#   https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/manage-hosted-agent
#     "Extract the agent identity principal ID" -> instance_identity.principal_id; "Use --assignee-object-id with --assignee-principal-type
#      ServicePrincipal to avoid Microsoft Graph lookup issues with agent identity service principals."
#   https://ai.azure.com/api-reference/agent-versions/get-agent-version/   (instance_identity / blueprint: AgentIdentity principal_id, client_id, status active|disabled; agent_guid)
#   https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/agent-identity   ("Newly created agents receive a unique Entra Agent Blueprint and Entra Agent
#      Identity by default." Legacy agents (instance_identity null) use the shared project identity. Example: az role assignment create --assignee "<agentIdentityId>" --role "Storage Blob Data Contributor" ...)
# Demo flow: Operate > Assets > Agents -> Entra ID column ("The Microsoft Entra Agent ID application and object ID associated with the agent")
#            -> this script prints the same principal -> Entra admin center > Entra ID > Agents > Agent identities (see entra_and_agent365_paths.md)
# Usage: bash 09-identity-killswitch/agent_identity_rbac.sh [--assign]
#   default: print the principal id only.  --assign: grant the documented example role (Azure AI Developer) at PROJECT scope.
# ENV: ACCOUNT_NAME, PROJECT_NAME, AGENT_NAME, AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP_NAME
set -euo pipefail

if [ -f "$(dirname "$0")/../.env" ]; then
  # shellcheck disable=SC1091
  set -a; . "$(dirname "$0")/../.env"; set +a
fi

ACCOUNT_NAME="${ACCOUNT_NAME:?set ACCOUNT_NAME}"
PROJECT_NAME="${PROJECT_NAME:?set PROJECT_NAME}"
AGENT_NAME="${AGENT_NAME:-zava-returns-assistant}"
BASE_URL="https://${ACCOUNT_NAME}.services.ai.azure.com/api/projects/${PROJECT_NAME}"
API_VERSION="v1"
RESOURCE="https://ai.azure.com"

AGENT_IDENTITY=$(az rest --method GET \
  --url "${BASE_URL}/agents/${AGENT_NAME}?api-version=${API_VERSION}" \
  --resource "${RESOURCE}" \
  --query "instance_identity.principal_id" \
  --output tsv)
echo "Agent identity principal ID: ${AGENT_IDENTITY}"

if [ -z "${AGENT_IDENTITY}" ] || [ "${AGENT_IDENTITY}" = "None" ]; then
  echo "instance_identity is null -> legacy agent using the shared project identity (migrate-agent-applications). Nothing to assign."
  exit 0
fi

echo "Full identity block (principal_id, client_id, status):"
az rest --method GET \
  --url "${BASE_URL}/agents/${AGENT_NAME}?api-version=${API_VERSION}" \
  --resource "${RESOURCE}" \
  --query "instance_identity"

if [ "${1:-}" = "--assign" ]; then
  SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:?set AZURE_SUBSCRIPTION_ID}"
  RESOURCE_GROUP="${AZURE_RESOURCE_GROUP_NAME:?set AZURE_RESOURCE_GROUP_NAME}"
  echo "Granting 'Azure AI Developer' to the agent identity at project scope (documented example) ..."
  az role assignment create \
    --assignee-object-id "$AGENT_IDENTITY" \
    --assignee-principal-type ServicePrincipal \
    --role "Azure AI Developer" \
    --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.CognitiveServices/accounts/${ACCOUNT_NAME}/projects/${PROJECT_NAME}"
  echo "Role assignment changes can take up to 10 minutes to propagate."
else
  echo
  echo "Dry run. Re-run with --assign to create the role assignment. Other documented example (agent-identity concept page):"
  echo '  az role assignment create --assignee "<agentIdentityId>" --role "Storage Blob Data Contributor" --scope "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Storage/storageAccounts/<storage-account>"'
fi

echo
echo "Talking point: tools that authenticate with the agent identity today are MCP and A2A (connection auth type AgenticIdentityToken)."
echo "Entra controls on that identity: Conditional Access for agents, ID Protection (risky agents), owners/sponsors, disable at identity/blueprint/tenant scope."
