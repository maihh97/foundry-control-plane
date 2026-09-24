#!/usr/bin/env bash
# Foundry Control Plane demo kit — 07 Foundry governance as Azure Policy (agent-runnable)
# Derived from (README verbatim):
#   https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/05-custom-policy-definitions
#   "Azure Policy enables you to put guardrails on resource configurations and enable self-serve resource creation in your organization."
#   Files in the folder: deny-disallowed-connections.json, deny-disallowed-mcp-tools.json, deny-key-auth-connections.json,
#                        deny-non-foundry-resource-kinds.json
#   Roles: "For subscription-level policies: Owner or Resource Policy Contributor role at subscription level".
#
# IMPORTANT scope note (verified 24 Sep 2026, see AUTOMATION.md): this is NOT the Control Plane "guardrail policy".
#   The guardrail policy in Operate > Compliance > Create policy is Azure-Policy-backed ("Deleting a policy in the Foundry portal
#   also removes the associated policy assignment in Azure Policy") but Microsoft documents it ONLY through the Foundry portal
#   (https://learn.microsoft.com/en-us/azure/foundry/control-plane/quickstart-create-guardrail-policy) and publishes no
#   definition name or CLI recipe for it. Use this script to show the ADJACENT, official policy-as-code story for Foundry
#   (connections, MCP tools, key auth, resource kinds); use guardrail_policy_portal.md for the guardrail policy itself, and
#   rai_policy_put.sh for the guardrail CONFIGURATION that "Fix now" edits.
#
# Usage: SUBSCRIPTION_ID=<id> [ASSIGN=true] bash 07-guardrails/azure_policy_definitions.sh
set -euo pipefail

if [ -f "$(dirname "$0")/../.env" ]; then
  # shellcheck disable=SC1091
  set -a; . "$(dirname "$0")/../.env"; set +a
fi

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:?set SUBSCRIPTION_ID}"
ASSIGN="${ASSIGN:-false}"
CLONE_DIR="${CLONE_DIR:-./foundry-samples}"
POLICY_DIR="${CLONE_DIR}/infrastructure/infrastructure-setup-bicep/05-custom-policy-definitions"

if [ ! -d "${POLICY_DIR}" ]; then
  git clone https://github.com/microsoft-foundry/foundry-samples.git "${CLONE_DIR}"
fi

# README (verbatim): az login / az account set --subscription "<your-subscription-id>"
az account set --subscription "${SUBSCRIPTION_ID}"

# README "Alternative: Deploy using JSON policy definitions directly" — verbatim commands for the first definition.
az policy definition create \
  --name "deny-disallowed-connections" \
  --display-name "Foundry Developer Platform Connections Can only be AIService" \
  --description "Foundry Developer Platform Connections Can only be AIService" \
  --rules "${POLICY_DIR}/deny-disallowed-connections.json" \
  --mode "All"

# The MCP-tool definition (same pattern; display text is the kit's, the rules file is the official one).
az policy definition create \
  --name "deny-disallowed-mcp-tools" \
  --display-name "Foundry: deny disallowed MCP tools" \
  --description "Official sample definition deny-disallowed-mcp-tools.json from microsoft-foundry/foundry-samples" \
  --rules "${POLICY_DIR}/deny-disallowed-mcp-tools.json" \
  --mode "All"

if [ "${ASSIGN}" = "true" ]; then
  # README (verbatim): "Assign the policy (optional)"
  az policy assignment create \
    --name "deny-disallowed-connections-assignment" \
    --display-name "Assignment: Foundry Developer Platform Connections Can only be AIService" \
    --policy "deny-disallowed-connections" \
    --params '{"allowedCategories":{"value":["CognitiveSearch"]}}'
fi

echo
echo "README test (verbatim): 'Try to create a new connection with a category not in the allowed list. The operation should be denied with a policy violation message.'"
echo "Bicep alternative from the same README: az deployment sub create --location \"East US 2\" --template-file main.bicep --parameters main.bicepparam [--parameters assignPolicy=true]"
