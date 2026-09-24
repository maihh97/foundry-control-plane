<!--
Foundry Control Plane demo kit — 05 Alerts (preview) + GAP G-2 (alerts -> Azure Monitor / on-call)
Derived from:
  https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/how-to-monitor-agents-dashboard   (Monitor settings gear; Alerts (preview))
  https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/observability/how-to/how-to-monitor-agents-dashboard.md (ms.date 09/03/2026)
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/monitoring-across-fleet                   (Active alerts pane)
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/overview                                   (Defender/Purview alerts on the dashboard)
  https://learn.microsoft.com/en-us/azure/defender-for-cloud/ai-threat-protection                         (Defender alerts -> Defender XDR)
  https://devblogs.microsoft.com/foundry/build-2026-from-observability-to-roi-for-ai-agents-on-any-framework/ (3 Jun 2026)
-->
# 05 · Alerts (preview) — what exists, and the G-2 gap

> **Automation status (verified 24 Sep 2026 — see `AUTOMATION.md`).** **Portal-only, confirmed.** The Agent Monitoring Dashboard article gives SDK code for continuous and scheduled *evaluations* (Python, .NET; JavaScript for continuous rules only) but none for **Alerts (preview)**, and documents no route to Azure Monitor alert rules or action groups. What a coding agent *can* set up from code: `continuous_eval_rule.py`, `scheduled_eval_and_redteam.py`, `agent_insights.py`. Turn Alerts on by hand (**Build > agent > Monitor > gear > Alerts (preview)**) before the session so there is traffic to evaluate.

Status line for the slide: **Monitoring and Alerts are Preview** ("Monitoring, alerting, and some networking experiences remain in preview." — Foundry GA overview).

## Where alerts are configured (portal, verbatim)

**Build >** select the agent **> Monitor** tab → "To access Monitor settings, select the gear icon on the Monitor tab" → **Alerts (preview)**:

> "Alerts (preview) — Detects performance anomalies, evaluation failures, and security risks. — Configure alerts for latency, token usage, evaluation scores, or red team findings"

The same settings panel also holds **Recurring evaluations (preview)** and **Red team scans (preview)** (settings-panel alt-text: "operational metrics, continuous evaluation, scheduled evaluations, red team scans, and alerts configuration").

Demo suggestion: set an evaluation-score alert on the continuous-eval rule from `continuous_eval_rule.py` (task adherence) and a token-usage alert before running `04-traffic/send_traffic.py --burst`.

## Where alerts surface in Control Plane (verbatim)

- **Operate > Overview**: "shows fleet-level health scores, alert summaries, active agent counts, error rates, and compliance metrics".
- **Operate > Assets** → agent pane → "**Active alerts**: View policy, security, and evaluation alerts grouped by severity and take action." · "**Anomaly detection**: Identify cost spikes, performance degradation, and emerging issues through trend analysis."
- Overview article: "Correlate alerts, evaluation results, and trace data to identify problems quickly." · "View Defender and Microsoft Purview alerts directly on the Foundry Control Plane dashboard."
- SecOps route: Defender for Cloud AI threat protection → "centralize AI workload alerts in the Defender XDR portal" (jailbreak / prompt-attack detections appear as Defender alerts).

## ⚠ GAP G-2 — routing Foundry alerts to Azure Monitor action groups / on-call

No Microsoft Learn page maps Foundry **Alerts (preview)** to Azure Monitor alert rules or action groups, and no alert KQL is documented. Any statement that Foundry alerts create Azure Monitor alert rules or fire action groups is therefore unsupported and must be presented as inference.

**So this kit provides no code for alert routing.** What you *can* say, all grounded:

1. In-portal Alerts (preview) are configured from the Monitor gear icon (above) and appear in Operate.
2. Security alerts flow to **Defender XDR** via Defender for Cloud AI threat protection.
3. Foundry telemetry lands in Application Insights / Log Analytics ("Monitoring and tracing billed as Azure logs"), so **generic Azure Monitor alerting on those tables is possible** — but the Foundry docs do not publish alert KQL for it, and from **30 September 2026** the seven sensitive `gen_ai.*` content attributes move to the `AppGenAIContent` table ("Update any custom queries, alert rules, dashboards, workbooks, or reports that read the affected attribute values from AppDependencies, AppTraces, or AppEvents.").
4. Build 2026 devblog framing (verbatim): "Monitor — real-time issue detection with alerts and dashboards via Azure Monitor" and "All of it on the same Foundry control plane, with Azure Monitor for alerts and infrastructure signals, and OpenTelemetry as the common language underneath." Quote it as vision, not as a documented procedure.

If Zava asks "can it page our on-call?": answer honestly — "the portal alerts exist in preview; action-group routing isn't documented yet; the data is in Azure Monitor so standard log alerts are the bridge today." Then offer a follow-up rather than demoing an unverified path.

## Verify (verbatim)

"the evaluation runs list shows entries with status **Completed**." (Agent Monitoring Dashboard) · Fleet metrics: "Metrics might take a few minutes to populate."
