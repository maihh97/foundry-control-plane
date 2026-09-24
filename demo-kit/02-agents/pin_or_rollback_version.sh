#!/usr/bin/env bash
# Foundry Control Plane demo kit — 02 pin (or roll back) the agent endpoint to a specific version over REST
# Derived from (verbatim az rest pattern):
#   https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/manage-hosted-agent  — "Configure agent endpoint routing"
#   "Traffic splitting between agent versions isn't supported. Configure one FixedRatio rule with traffic_percentage set to 100"
#   "Important: The --resource parameter is required for all az rest calls to Foundry Agent Service data-plane endpoints."
# Usage: bash 02-agents/pin_or_rollback_version.sh <agent_version>      e.g.  bash 02-agents/pin_or_rollback_version.sh 1
# ENV (see .env.example): ACCOUNT_NAME, PROJECT_NAME, AGENT_NAME
set -euo pipefail

if [ -f "$(dirname "$0")/../.env" ]; then
  # shellcheck disable=SC1091
  set -a; . "$(dirname "$0")/../.env"; set +a
fi

TARGET_VERSION="${1:?usage: $0 <agent_version>}"

ACCOUNT_NAME="${ACCOUNT_NAME:?set ACCOUNT_NAME}"
PROJECT_NAME="${PROJECT_NAME:?set PROJECT_NAME}"
AGENT_NAME="${AGENT_NAME:?set AGENT_NAME}"
BASE_URL="https://${ACCOUNT_NAME}.services.ai.azure.com/api/projects/${PROJECT_NAME}"
API_VERSION="v1"
RESOURCE="https://ai.azure.com"

echo "Pinning ${AGENT_NAME} endpoint -> version ${TARGET_VERSION} (100%)"
az rest --method PATCH \
  --url "${BASE_URL}/agents/${AGENT_NAME}?api-version=${API_VERSION}" \
  --resource "${RESOURCE}" \
  --headers "Content-Type=application/merge-patch+json" \
  --body '{
    "agent_endpoint": {
      "version_selector": {
        "version_selection_rules": [
          {"agent_version": "'"${TARGET_VERSION}"'", "traffic_percentage": 100, "type": "FixedRatio"}
        ]
      },
      "protocol_configuration": {
        "responses": {}
      }
    }
  }'

echo
echo "Verify (Get agent details — 'The response includes the agent's latest version, status, and definition.'):"
az rest --method GET \
  --url "${BASE_URL}/agents/${AGENT_NAME}?api-version=${API_VERSION}" \
  --resource "${RESOURCE}" \
  --query "agent_endpoint.version_selector"
