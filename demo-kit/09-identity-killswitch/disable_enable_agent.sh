#!/usr/bin/env bash
# Foundry Control Plane demo kit — 09 KILL SWITCH for a Foundry agent (REST) + ARM stop/start for a published agent application
# Derived from (verbatim az rest commands):
#   https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/manage-hosted-agent   (":disable" / ":enable"; api-version v1; --resource https://ai.azure.com)
#     "Disable an agent to take its endpoint offline without deleting the agent or any of its versions. While disabled, the agent rejects
#      requests, but its configuration and versions remain intact."  Not available in JS/TS SDK or as an azd standalone command — "Use the REST API."
#     "Important: The --resource parameter is required for all az rest calls to Foundry Agent Service data-plane endpoints. Without it,
#      az rest can't derive the correct Azure AD audience from the URL and authentication fails."
#   https://learn.microsoft.com/en-us/azure/foundry/control-plane/govern-agent-infrastructure-entra-admin  (agentdeployments list/stop/start; api-version 2025-10-01-preview)
#     "Disable and Enable take a Foundry agent's endpoint offline or bring it back online… while disabled the agent rejects requests across
#      all channels (Teams, Microsoft 365 Copilot, Foundry, APIs)." "Always prefer Stop over Delete."
#     Roles: Foundry agent Disable/enable -> Foundry User (project scope); Stop/start an agent deployment -> Azure AI Owner (= Foundry Owner).
#   https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-agents  (custom agents: Operate > Assets > Update status > Block/Unblock)
# Kill switch by agent type:
#   Custom agent  -> portal: Operate > Assets > [radio button] > Update status > Block  (then Unblock). "The operation might take a few minutes to complete."
#   Foundry agent -> this script: disable | enable            (prompt agent from 02; also hosted agents)
#   Agent application (published) -> this script: list-deployments | stop | start   (ARM)
# Usage: bash 09-identity-killswitch/disable_enable_agent.sh {disable|enable|status|list-deployments|stop|start}
# ENV: ACCOUNT_NAME, PROJECT_NAME, AGENT_NAME; for ARM: AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP_NAME, APPLICATION_NAME, DEPLOYMENT_NAME
set -euo pipefail

if [ -f "$(dirname "$0")/../.env" ]; then
  # shellcheck disable=SC1091
  set -a; . "$(dirname "$0")/../.env"; set +a
fi

if [ "$#" -lt 1 ]; then
  echo "usage: $0 {disable|enable|status|list-deployments|stop|start}" >&2
  exit 2
fi
ACTION="$1"

ACCOUNT_NAME="${ACCOUNT_NAME:?set ACCOUNT_NAME}"
PROJECT_NAME="${PROJECT_NAME:?set PROJECT_NAME}"
AGENT_NAME="${AGENT_NAME:-zava-returns-assistant}"
BASE_URL="https://${ACCOUNT_NAME}.services.ai.azure.com/api/projects/${PROJECT_NAME}"
API_VERSION="v1"
RESOURCE="https://ai.azure.com"

case "${ACTION}" in
  disable)
    echo "Disabling Foundry agent ${AGENT_NAME} (endpoint goes offline; versions kept) ..."
    az rest --method POST \
      --url "${BASE_URL}/agents/${AGENT_NAME}:disable?api-version=${API_VERSION}" \
      --resource "${RESOURCE}"
    echo "Now re-run 04-traffic/send_traffic.py --count 1 -> the request is rejected. Portal: Operate > Assets shows the status change (refresh)."
    ;;
  enable)
    echo "Enabling Foundry agent ${AGENT_NAME} ..."
    az rest --method POST \
      --url "${BASE_URL}/agents/${AGENT_NAME}:enable?api-version=${API_VERSION}" \
      --resource "${RESOURCE}"
    ;;
  status)
    # "The response includes the agent's latest version, status, and definition."
    az rest --method GET \
      --url "${BASE_URL}/agents/${AGENT_NAME}?api-version=${API_VERSION}" \
      --resource "${RESOURCE}"
    ;;
  list-deployments|stop|start)
    SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:?set AZURE_SUBSCRIPTION_ID}"
    RESOURCE_GROUP="${AZURE_RESOURCE_GROUP_NAME:?set AZURE_RESOURCE_GROUP_NAME}"
    APPLICATION_NAME="${APPLICATION_NAME:?set APPLICATION_NAME (published agent application)}"
    ARM_APP="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.CognitiveServices/accounts/${ACCOUNT_NAME}/projects/${PROJECT_NAME}/applications/${APPLICATION_NAME}"
    if [ "${ACTION}" = "list-deployments" ]; then
      # List deployments for an agent application
      az rest --method get \
        --uri "${ARM_APP}/agentdeployments?api-version=2025-10-01-preview"
    else
      DEPLOYMENT_NAME="${DEPLOYMENT_NAME:?set DEPLOYMENT_NAME (run list-deployments first)}"
      echo "${ACTION} deployment ${DEPLOYMENT_NAME} of application ${APPLICATION_NAME} ..."
      # "Stopping a deployment releases the underlying compute, but the deployment and application continue to exist and can be restarted later."
      az rest --method post \
        --uri "${ARM_APP}/agentdeployments/${DEPLOYMENT_NAME}/${ACTION}?api-version=2025-10-01-preview"
    fi
    ;;
  *)
    echo "unknown action: ${ACTION}"; exit 1 ;;
esac

# NOT included on purpose: DELETE. "Caution: Deleting a deployment permanently removes the Azure resource… Always prefer stopping a deployment over deleting it."
