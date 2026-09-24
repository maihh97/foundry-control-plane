#!/usr/bin/env bash
# Foundry Control Plane demo kit — 07 guardrail as code: create an RAI (content filter) policy on the Foundry account via ARM, then verify
# Derived from (verbatim):
#   https://learn.microsoft.com/en-us/rest/api/aiservices/accountmanagement/rai-policies/create-or-update?view=rest-aiservices-accountmanagement-2024-10-01
#     PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CognitiveServices/accounts/{accountName}/raiPolicies/{raiPolicyName}?api-version=2024-10-01
#     (body below is the documented sample request, verbatim; responses 200 "Create/Update the Content Filters successfully", 201 "Create the Content Filters successfully")
#   https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/add-hosted-agent-guardrails   (attach via azure.yaml `policies:` / rai_config; fail-open warning; HTTP 400 content_filter)
#   https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/default-safety-policies       ("HTTP 400 error with a content_filter code, or the response's finish_reason is content_filter")
# Note: this 2024-10-01 ARM schema has no fields for agent intervention points (tool call / tool response) or network egress — those are
#   portal-only in the agent-guardrail wizard. Scope caveat: agent guardrails apply only to Foundry Agent Service agents.
# Usage: bash 07-guardrails/rai_policy_put.sh            (creates/updates the policy)
#        VERIFY_AGENT=<hosted-agent-name> bash 07-guardrails/rai_policy_put.sh   (also sends a prompt you expect to be blocked)
# ENV: AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP_NAME, ACCOUNT_NAME, PROJECT_NAME, RAI_POLICY_NAME
set -euo pipefail

if [ -f "$(dirname "$0")/../.env" ]; then
  # shellcheck disable=SC1091
  set -a; . "$(dirname "$0")/../.env"; set +a
fi

SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:?set AZURE_SUBSCRIPTION_ID}"
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP_NAME:?set AZURE_RESOURCE_GROUP_NAME}"
ACCOUNT_NAME="${ACCOUNT_NAME:?set ACCOUNT_NAME}"
RAI_POLICY_NAME="${RAI_POLICY_NAME:-zava-returns-guardrail}"

POLICY_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.CognitiveServices/accounts/${ACCOUNT_NAME}/raiPolicies/${RAI_POLICY_NAME}"

echo "PUT raiPolicies/${RAI_POLICY_NAME} on account ${ACCOUNT_NAME}"
# Body = the documented sample request (verbatim). mode "Asynchronous_filter": "Please use 'Asynchronous_filter' after 2024-10-01. It is the same as 'Deferred' in previous version."
az rest --method PUT \
  --url "https://management.azure.com${POLICY_ID}?api-version=2024-10-01" \
  --headers "Content-Type=application/json" \
  --body '{
  "properties": {
    "basePolicyName": "Microsoft.Default",
    "mode": "Asynchronous_filter",
    "contentFilters": [
      { "name": "Hate", "blocking": false, "enabled": false, "severityThreshold": "High", "source": "Prompt" },
      { "name": "Hate", "blocking": true, "enabled": true, "severityThreshold": "Medium", "source": "Completion" },
      { "name": "Sexual", "blocking": true, "enabled": true, "severityThreshold": "High", "source": "Prompt" },
      { "name": "Sexual", "blocking": true, "enabled": true, "severityThreshold": "Medium", "source": "Completion" },
      { "name": "Selfharm", "blocking": true, "enabled": true, "severityThreshold": "High", "source": "Prompt" },
      { "name": "Selfharm", "blocking": true, "enabled": true, "severityThreshold": "Medium", "source": "Completion" },
      { "name": "Violence", "blocking": true, "enabled": true, "severityThreshold": "Medium", "source": "Prompt" },
      { "name": "Violence", "blocking": true, "enabled": true, "severityThreshold": "Medium", "source": "Completion" },
      { "name": "Jailbreak", "blocking": true, "source": "Prompt", "enabled": true },
      { "name": "Protected Material Text", "blocking": true, "source": "Completion", "enabled": true },
      { "name": "Protected Material Code", "blocking": true, "source": "Completion", "enabled": true },
      { "name": "Profanity", "blocking": true, "source": "Prompt", "enabled": true }
    ]
  }
}'

echo
echo "Policy ARM id (use this FULL id as rai_policy_name — 'Always use the full ARM resource ID for rai_policy_name, not the bare policy name.'):"
echo "  ${POLICY_ID}"
echo
echo "Attach to a HOSTED agent (verbatim options from add-hosted-agent-guardrails):"
echo "  azure.yaml (azd ext >= 1.0.0-beta.1 uses a 'policies:' list, camelCased raiPolicyName, mapped to rai_config on deploy):"
echo "    policies:"
echo "      - type: rai_policy"
echo "        raiPolicyName: ${POLICY_ID}"
echo "  Python SDK: rai_config=RaiConfig(rai_policy_name=\"${POLICY_ID}\") inside HostedAgentDefinition(...)  (allow_preview=True)"
echo
echo "############################################################################################################"
echo "# FAIL-OPEN WARNING (verbatim): 'Don't rely on deploy-time validation to catch a bad policy ID. On many        #"
echo "# subscriptions an agent that references a policy that doesn't exist is created successfully and reports       #"
echo "# active, but no content filtering is applied - the guardrail fails open and harmful prompts reach the agent.  #"
echo "# Confirm the policy exists on the account, then test the guardrail before you rely on the agent's content     #"
echo "# safety.'                                                                                                       #"
echo "############################################################################################################"

echo
echo "Confirm the policy exists on the account:"
az rest --method GET --url "https://management.azure.com${POLICY_ID}?api-version=2024-10-01" --query "name" --output tsv

if [ -n "${VERIFY_AGENT:-}" ]; then
  PROJECT_NAME="${PROJECT_NAME:?set PROJECT_NAME}"
  BASE_URL="https://${ACCOUNT_NAME}.services.ai.azure.com/api/projects/${PROJECT_NAME}"
  API_VERSION="v1"
  TOKEN=$(az account get-access-token --resource https://ai.azure.com --query accessToken -o tsv)

  echo
  echo "1) Confirm the agent version carries the policy (.definition.rai_config):"
  curl -s -X GET "$BASE_URL/agents/${VERIFY_AGENT}/versions/1?api-version=$API_VERSION" \
    -H "Authorization: Bearer $TOKEN" | jq '.definition.rai_config'

  echo
  echo "2) Send a prompt your policy is configured to block — expect HTTP 400 with code content_filter:"
  echo '   {"error": {"code": "content_filter", "message": "The request was blocked due to content safety policy violation at input stage.", "type": "content_safety_error"}}'
  curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE_URL/agents/${VERIFY_AGENT}/endpoint/protocols/openai/responses?api-version=$API_VERSION" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"input":"<a prompt that your policy is configured to block>","store":true}'
  echo "   ('The guardrail applies to streaming requests too. By using \"stream\": true, a violating prompt is rejected with the same HTTP 400 before any event is emitted.')"
fi
