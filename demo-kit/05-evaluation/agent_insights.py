# Foundry Control Plane demo kit — 05 (optional) Insights in Foundry (preview): production trace analysis, on-demand run + 6-hourly schedule
# Derived from (verbatim Python blocks on the Learn page):
#   https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/agent-insights   (Last updated 09/22/2026; preview)
# The SDK sample files samples/agent_insights/sample_agent_insights_scheduled.py / sample_agent_insights_on_demand.py exist
# (azure-ai-projects 2.6.1 changelog), but this file follows the Learn article
# instead. Verify against source before running: https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/agent-insights
# Prereqs (verbatim): "A Foundry project with a GPT-5 or newer GPT model deployment and a connected Azure Monitor Application Insights
#   resource." Roles: prompt agent -> Foundry User; "The Monitoring Reader role on the connected Application Insights resource for both the
#   interactive user and the Foundry project's managed identity. If the AppGenAIContent table is protected, the Privileged Monitoring Data
#   Reader role for each identity that reads protected content, including the project's managed identity." "The project's managed identity
#   needs access to the model deployment used for analysis."
# Install: python -m pip install "azure-ai-projects>=2.6.1" azure-identity   (kit pins 2.7.0); client needs allow_preview=True.
# Portal: Build > Agents > agent > Insights tab > Configuration > Judge model > Run scan now; schedule via Settings > Insights.
# "The first analysis uses a 7-day lookback window" — on-demand run below uses lookback_hours=3 as in the article.
#
# USAGE: python 05-evaluation/agent_insights.py
# ENV: FOUNDRY_PROJECT_ENDPOINT, FOUNDRY_AGENT_NAME, INSIGHTS_MODEL_DEPLOYMENT (optional, defaults to gpt-5-mini),
#      INSIGHTS_MONITOR_ID (optional, reuses an existing monitor)

import os
import time
import uuid
from dotenv import load_dotenv
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    AgentInsightMonitorCreate,
    AgentInsightMonitorUpdate,
    AgentInsightRunCreate,
)
from azure.core.exceptions import HttpResponseError
from azure.identity import AzureCliCredential

load_dotenv()

credential = AzureCliCredential(process_timeout=60)
project_client = AIProjectClient(
    endpoint=os.environ["FOUNDRY_PROJECT_ENDPOINT"],
    credential=credential,
    allow_preview=True,
)
monitor_operations = project_client.beta.agent_insight_monitors
model_deployment_name = os.environ.get("INSIGHTS_MODEL_DEPLOYMENT", "gpt-5-mini")

# 1) Reuse an existing monitor or create one with its schedule disabled
print(f"Using Insights judge deployment: {model_deployment_name}", flush=True)
monitor_id = os.environ.get("INSIGHTS_MONITOR_ID")
if monitor_id:
    monitor = monitor_operations.get(monitor_id)
    print(f"Reusing monitor ID: {monitor.id}", flush=True)
else:
    monitor = monitor_operations.create(
        AgentInsightMonitorCreate(
            agent_name=os.environ["FOUNDRY_AGENT_NAME"],
            model_deployment_name=model_deployment_name,
            enabled=False,
        )
    )
    print(f"Created monitor ID: {monitor.id}", flush=True)

# 2) On-demand run over the last 3 hours of production traces
run_result = None
run_id = ""
for attempt in range(1, 4):
    poller = monitor_operations.begin_create_run(
        monitor.id,
        AgentInsightRunCreate(lookback_hours=3),
        operation_id=str(uuid.uuid4()),
    )
    run_id = poller.details["run_id"]
    print(f"Run ID: {run_id} (attempt {attempt}/3)", flush=True)
    try:
        run_result = poller.result()
        break
    except HttpResponseError as exc:
        error_code = getattr(getattr(exc, "error", None), "code", None)
        is_dependency_unavailable = exc.status_code == 503 or error_code == "ServiceUnavailable"
        if not is_dependency_unavailable or attempt == 3:
            raise
        print("Agent Insights dependency unavailable; retrying in 30 seconds.", flush=True)
        time.sleep(30)

if run_result is None:
    raise RuntimeError("Agent Insights run did not return a result.")

completed_run = monitor_operations.get_run(monitor.id, run_id)
print(f"Run status: {completed_run.status}")
print(f"Traces in window: {run_result.traces_in_window}")
print(f"Traces analyzed: {run_result.traces_analyzed}")
print(f"Insights created: {run_result.insights_created}")
print(f"Insights updated: {run_result.insights_updated}")
print(f"Insights reopened: {run_result.insights_reopened}")
print(f"Total tokens: {run_result.token_usage.total_tokens}")

# 3) List insights with details (title, severity, status, linked traces, proposed fix)
insights = list(
    monitor_operations.list_insights(monitor.id, include_details=True)
)
print(f"Insights available: {len(insights)}")
for insight in insights:
    print(f"{insight.id}: {insight.title}")
    print(f"Severity: {insight.severity}; status: {insight.status}")
    print(f"Linked traces: {insight.trace_count}")
    if insight.details:
        print(insight.details.recommended_actions.proposed_fix.text)

# 4) Turn on the 6-hourly schedule
scheduled_monitor = monitor_operations.update(
    monitor.id,
    AgentInsightMonitorUpdate(enabled=True, run_interval_hours=6),
)
print(f"Schedule enabled: {scheduled_monitor.enabled}")
print(f"Run interval hours: {scheduled_monitor.run_interval_hours}")

# To resolve an insight after review (verbatim pattern from the article):
#   from azure.ai.projects.models import AgentInsightStatus, AgentInsightUpdate
#   resolved_insight = monitor_operations.update_insight(monitor.id, "<insight-id>", AgentInsightUpdate(status=AgentInsightStatus.RESOLVED))
