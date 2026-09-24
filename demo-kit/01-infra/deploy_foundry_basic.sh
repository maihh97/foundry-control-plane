#!/usr/bin/env bash
# Deploy Microsoft Foundry Basic Agent Setup using the official template.
# Basic setup uses Microsoft-managed multitenant agent state and avoids
# customer-managed Cosmos DB, Storage, and AI Search dependencies.
# Usage:
#   bash 01-infra/deploy_foundry_basic.sh what-if
#   bash 01-infra/deploy_foundry_basic.sh apply
set -euo pipefail

case "$(uname -s)" in
  MINGW*|MSYS*) export MSYS_NO_PATHCONV=1 ;;
esac

ACTION="${1:-what-if}"
RG="${RG:-rg-foundry-control-plane}"
LOCATION="${LOCATION:-swedencentral}"
AI_SERVICES="${AI_SERVICES:-zavabasic}"
PROJECT_NAME="${PROJECT_NAME:-zava-control}"
MODEL_NAME="${MODEL_NAME:-gpt-4.1}"
MODEL_VERSION="${MODEL_VERSION:-2025-04-14}"
MODEL_SKU="${MODEL_SKU:-GlobalStandard}"
MODEL_CAPACITY="${MODEL_CAPACITY:-40}"
DEPLOYMENT_SEED="${DEPLOYMENT_SEED:-zava-basic-v1}"
CLONE_DIR="${CLONE_DIR:-./foundry-samples}"
TEMPLATE_DIR="${CLONE_DIR}/infrastructure/infrastructure-setup-bicep/40-basic-agent-setup"

if [ "${ACTION}" != "what-if" ] && [ "${ACTION}" != "apply" ]; then
  echo "Usage: $0 [what-if|apply]" >&2
  exit 2
fi

if [ ! -d "${CLONE_DIR}/.git" ]; then
  git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/microsoft-foundry/foundry-samples.git "${CLONE_DIR}"
fi
git -C "${CLONE_DIR}" sparse-checkout add \
  infrastructure/infrastructure-setup-bicep/40-basic-agent-setup

if [ "$(az group exists --name "${RG}")" != "true" ]; then
  az group create --name "${RG}" --location "${LOCATION}"
fi

deployment_args=(
  --resource-group "${RG}"
  --template-file "${TEMPLATE_DIR}/main.bicep"
  --parameters
    location="${LOCATION}"
    aiServicesName="${AI_SERVICES}"
    projectName="${PROJECT_NAME}"
    projectDisplayName="Zava Control Plane"
    projectDescription="Fictional Zava control-plane demonstration"
    modelName="${MODEL_NAME}"
    modelFormat="OpenAI"
    modelVersion="${MODEL_VERSION}"
    modelSkuName="${MODEL_SKU}"
    modelCapacity="${MODEL_CAPACITY}"
    deploymentTimestamp="${DEPLOYMENT_SEED}"
)

if [ "${ACTION}" = "what-if" ]; then
  az deployment group what-if "${deployment_args[@]}"
  echo
  echo "What-if completed. Review the changes, then run:"
  echo "  bash 01-infra/deploy_foundry_basic.sh apply"
  exit 0
fi

az deployment group create \
  --name "zava-foundry-basic" \
  "${deployment_args[@]}"

echo
echo "Basic Agent Setup deployed."
echo "Next: connect Application Insights, assign Foundry roles, then create agents."
