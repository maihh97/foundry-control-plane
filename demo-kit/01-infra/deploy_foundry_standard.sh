#!/usr/bin/env bash
# Foundry Control Plane demo kit — 01 stand up Foundry account + project + Application Insights (Bicep, standard setup)
# Derived from:
#   https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/41-standard-agent-setup
#   README (verbatim): "By default (deployApplicationInsights = true) this template also: Deploys a Log Analytics workspace and a
#   workspace-based Application Insights component and connects Application Insights to the Foundry account, so hosted agents export
#   OpenTelemetry traces. Grants the project managed identity read access on the Application Insights component so evaluation can
#   read the agent traces — including GenAI prompt/response content: Log Analytics Reader … Privileged Monitoring Data Reader …"
#   Required permissions (README): "Foundry Account Owner", "Role Based Access Administrator".
# Usage:
#   bash 01-infra/deploy_foundry_standard.sh what-if
#   bash 01-infra/deploy_foundry_standard.sh apply
# Override defaults with RG, LOCATION, AI_SERVICES, PROJECT_NAME, MODEL_NAME,
# MODEL_VERSION, MODEL_SKU, MODEL_CAPACITY, or CLONE_DIR.
set -euo pipefail

case "$(uname -s)" in
  MINGW*|MSYS*) export MSYS_NO_PATHCONV=1 ;;
esac

ACTION="${1:-what-if}"
RG="${RG:-rg-foundry-control-plane}"
LOCATION="${LOCATION:-francecentral}"
AI_SERVICES="${AI_SERVICES:-zavaai}"
PROJECT_NAME="${PROJECT_NAME:-zava-returns}"
MODEL_NAME="${MODEL_NAME:-gpt-4.1}"
MODEL_VERSION="${MODEL_VERSION:-2025-04-14}"
MODEL_SKU="${MODEL_SKU:-GlobalStandard}"
MODEL_CAPACITY="${MODEL_CAPACITY:-40}"
DEPLOYMENT_SEED="${DEPLOYMENT_SEED:-zava-control-plane-v1}"
AI_SEARCH_RESOURCE_ID="${AI_SEARCH_RESOURCE_ID:-}"
CLONE_DIR="${CLONE_DIR:-./foundry-samples}"
TEMPLATE_DIR="${CLONE_DIR}/infrastructure/infrastructure-setup-bicep/41-standard-agent-setup"

if [ "${ACTION}" != "what-if" ] && [ "${ACTION}" != "apply" ]; then
  echo "Usage: $0 [what-if|apply]" >&2
  exit 2
fi

if [ ! -d "${CLONE_DIR}/.git" ]; then
  git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/microsoft-foundry/foundry-samples.git "${CLONE_DIR}"
  git -C "${CLONE_DIR}" sparse-checkout set \
    infrastructure/infrastructure-setup-bicep/41-standard-agent-setup
fi

if [ "$(az group exists --name "${RG}")" != "true" ]; then
  az group create --name "${RG}" --location "${LOCATION}"
fi

deployment_args=(
  --resource-group "${RG}"
  --template-file "${TEMPLATE_DIR}/main.bicep"
  --parameters
    location="${LOCATION}"
    aiServices="${AI_SERVICES}"
    firstProjectName="${PROJECT_NAME}"
    displayName="Zava Returns Assistant"
    projectDescription="Fictional Zava control-plane demonstration"
    modelName="${MODEL_NAME}"
    modelFormat="OpenAI"
    modelVersion="${MODEL_VERSION}"
    modelSkuName="${MODEL_SKU}"
    modelCapacity="${MODEL_CAPACITY}"
    deployApplicationInsights=true
    deploymentTimestamp="${DEPLOYMENT_SEED}"
    aiSearchResourceId="${AI_SEARCH_RESOURCE_ID}"
)

if [ "${ACTION}" = "what-if" ]; then
  az deployment group what-if "${deployment_args[@]}"
  echo
  echo "What-if completed. Review the changes, then run:"
  echo "  bash 01-infra/deploy_foundry_standard.sh apply"
  exit 0
fi

az deployment group create \
  --name "zava-foundry-standard" \
  "${deployment_args[@]}"

echo
echo "Next:"
echo " 1. Foundry portal (new) > Manage > Project details > Connected resources: verify a resource in the AppInsights category."
echo " 2. Manage > AI Gateway > Add AI Gateway > Create new (Basic v2, 'typically provision within 5-10 minutes')  -> see 01-infra/ai-gateway.md"
echo " 3. Only AFTER App Insights is connected: register the custom agent (03-custom-agent/register_custom_agent.md)."
