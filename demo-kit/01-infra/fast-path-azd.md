<!--
Foundry Control Plane demo kit — 01 fast path with azd
Derived from:
  https://github.com/Azure-Samples/get-started-with-ai-agents            (README + docs/observability.md)
  https://github.com/Azure-Samples/get-started-with-ai-agents/blob/main/docs/observability.md
-->
# 01 · Fast path — `Azure-Samples/get-started-with-ai-agents` (azd template)

Use this if the Bicep route (`deploy_foundry_standard.sh`) is not an option. It gives you a Foundry project, a model deployment, a deployed sample agent, Application Insights (optional resource) and **continuous evaluation switched on by default** — i.e. the fleet view (module 01) and the eval story (module 05) light up with almost no code.

Deploy options (README verbatim): "Option A: azd up (7–15 minutes)"; "Option B: Copilot-assisted /up (~40 minutes) ⚠️ Important: The /up skill only works in the Copilot CLI terminal (launched via the copilot command)."

```bash
# Turn on Azure Monitor tracing BEFORE deploying, then deploy (verbatim toggle from docs/observability.md)
azd env set ENABLE_AZURE_MONITOR_TRACING true
azd up
```

If you already ran `azd up` without the toggle:

```bash
azd env set ENABLE_AZURE_MONITOR_TRACING true
azd deploy
```

## What you get (verbatim highlights)

- "Built-in Monitoring and Tracing — Integrated monitoring capabilities, including Azure Monitor and Application Insights…"
- "During container startup, continuous evaluation is enabled by default and pre-configured with a sample evaluator set to evaluate up to 5 agent responses per hour. Continuous evaluation does not generate test inputs—instead, it evaluates real user conversations as they occur."
  - Customize: portal → **Build > Agents > Monitor** → choose agent → **Settings** → "Select evaluators and adjust maximal number of runs per hour".
- Env vars: "azd writes them to .azure/<your-azd-environment-name>/.env". Agent ID format: "{agent_name}:{agent_version} (e.g., agent-template-assistant:1)" — find it under **Build > Agents**.
- Console logs: `azd show` → resource group → container app → **Monitoring > Log Stream** → "Application" radio button. Agent traces: agent under project → **'Tracing'**.

## Pre-deployment tests shipped in the repo (Pytest — run locally, optional)

```bash
python -m pip install -r src/requirements.txt
pytest tests/test_evaluation.py -s
pytest tests/test_red_teaming.py -s
```

Env vars used by the tests: `AZURE_EXISTING_AIPROJECT_ENDPOINT`, `AZURE_EXISTING_AGENT_ID` ("with fallback logic to look up the latest version by name using AZURE_AI_AGENT_NAME"), `AZURE_AI_AGENT_DEPLOYMENT_NAME` ("The judge model deployment name used by evaluators").

## Caveats

- Resource table marks Application Insights and Log Analytics Workspace as "Optional" — keep the tracing toggle on for this demo.
- The sample agent is a generic assistant (default model gpt-5-mini). To make it the "Zava Returns & Refunds Assistant", change the agent instructions in the portal (**Build > Agents**) or run `02-agents/prompt_agent_versions.py` against the same project — that also demonstrates versioning.
- Cost note (README): "AI Red Teaming Agent: Leverages Azure AI Risk and Safety Evaluations to assess attack success… Users are billed based on the consumption of Risk and Safety Evaluations".
- Clean-up: `azd down` (warning from the hosted-agent quickstart: "If the current azd environment created the Foundry project, azd down permanently deletes the project's resource group and everything in it.").
