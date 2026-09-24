#!/usr/bin/env bash
# Foundry Control Plane demo kit — 02 second agent type: a HOSTED agent deployed with azd (Agent Framework "01-basic" sample)
# Derived from (verbatim command sequence):
#   https://learn.microsoft.com/en-us/azure/foundry/agents/quickstarts/quickstart-hosted-agent   (azd pivot)
#   https://github.com/microsoft-foundry/foundry-samples/tree/main/samples/python/hosted-agents  (README: azd >= 1.27.1 + Foundry AI extension)
#   Breaking change (azd extension README): "azd ai agent deploy [path] has been removed." -> use `azd deploy`.
# Prereqs: azd >= 1.27.1; `azd ext show azure.ai.agents` >= 1.0.0-beta.4 (`azd ext upgrade azure.ai.agents`);
#          roles: Foundry Project Manager (existing project) or Owner at RG scope (new project).
# Region note: the hosted-agent demo template restricts to eastus2/francecentral/northcentralus/swedencentral — pick a supported one
#          in the interactive prompts (project location / model gpt-5.4-mini default, SKU Standard or GlobalStandard, capacity 10).
# Observability variant: swap the manifest for .../agent-framework/responses/08-observability/azure.yaml
#          ("Because the observability exporters are managed by Foundry, this sample must be run using azd ai agent run.")
# Usage: bash 02-agents/hosted_agent_azd.sh          (interactive; run at T-60 min, not live)
set -euo pipefail

MANIFEST="${MANIFEST:-https://github.com/microsoft-foundry/foundry-samples/blob/main/samples/python/hosted-agents/agent-framework/responses/01-basic/azure.yaml}"

azd auth login

# Scaffold from the official manifest; --deploy-mode code => "azd packages the source as a ZIP file and uploads it to Foundry.
# Foundry resolves dependencies, builds the hosted agent remotely, and deploys it"
azd ai agent init -m "${MANIFEST}" --deploy-mode code

# Default agent name from the prompts is agent-framework-agent-basic-responses; override with AGENT_DIR if you changed it.
cd "${AGENT_DIR:-agent-framework-agent-basic-responses}"

# Provision Foundry resources for the azd environment (or bind to an existing project chosen in the prompts)
azd provision

# Local run: "creates a virtual environment, installs dependencies, launches the agent by using the startupCommand defined in
# azure.yaml, and opens the agent inspector in your browser" (inspector on port 8087; agent on 8088)
azd ai agent run

# Deploy to Foundry (NOT `azd ai agent deploy` — removed)
azd deploy
# Expected output shape:
#   Done: Deploying service basic-agent
#   - Agent playground (portal): https://ai.azure.com/.../build/agents/basic-agent/build?version=1
#   - Agent endpoint: https://ai-account-<name>.services.ai.azure.com/api/projects/<project>/agents/basic-agent/versions/1

# Invoke the remote agent ("Remote Hosted Agent azd ai agent invoke calls using Responses or Invocations request platform latency
# diagnostics by default" -> prints Client elapsed / Platform latency)
azd ai agent invoke "A customer asks how to return a jumper that arrived in the wrong size. Draft a short, friendly reply."

# Stream container logs (reads agent name/version from the azd service entry; SSE max 30 min, idle timeout 2 min)
azd ai agent monitor --follow

# Clean-up (NOT during the demo): azd down
#   "If the current azd environment created the Foundry project, azd down permanently deletes the project's resource group and everything in it."
