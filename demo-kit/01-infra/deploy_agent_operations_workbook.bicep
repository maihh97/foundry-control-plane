@description('Name of the existing Application Insights component that receives Foundry telemetry.')
param applicationInsightsName string

@description('Display name of the shared Azure Monitor workbook.')
param workbookDisplayName string = 'Zava Agent Operations'

@description('Azure region used to store the workbook resource.')
param location string = resourceGroup().location

var applicationInsightsResourceId = resourceId('Microsoft.Insights/components', applicationInsightsName)

var workbookContent = {
  version: 'Notebook/1.0'
  items: [
    {
      type: 1
      name: 'overview'
      content: {
        json: '''
## Zava Agent Operations

This workbook is the reliable operational-insights surface for the Zava Foundry demo.

- **Live data:** Application Insights traces for prompt, hosted, and external agents.
- **Security evidence:** Defender for AI Services Standard, prompt evidence, model scanning, and Purview sharing are enabled.
- **Data protection:** `Zava AI sensitive data protection` is scoped only to Microsoft Foundry and runs in simulation mode.
- **Behavioral risk:** the prompt-agent red-team run produced 72 failed attack items for investigation.

> Foundry Agent Insights is a public-preview feature. The configured GPT-5 mini monitor currently returns `ServiceUnavailable` from a required Microsoft-managed dependency. Use this workbook for live operational evidence until that preview dependency recovers.
'''
      }
    }
    {
      type: 3
      name: 'agent-coverage'
      content: {
        version: 'KqlItem/1.0'
        title: 'Agent and version trace coverage - last 7 days'
        query: '''
union AppDependencies, AppRequests, AppTraces
| where TimeGenerated > ago(7d)
| extend AgentId = tostring(Properties["gen_ai.agent.id"])
| extend AgentName = tostring(Properties["gen_ai.agent.name"])
| extend AgentVersion = tostring(Properties["gen_ai.agent.version"])
| extend ConversationId = tostring(Properties["gen_ai.conversation.id"])
| extend Agent = case(
    isnotempty(AgentName), AgentName,
    isnotempty(AgentId), tostring(split(AgentId, ":")[0]),
    AppRoleName
  )
| where Agent startswith "zava-"
| summarize
    Records = count(),
    Conversations = dcountif(ConversationId, isnotempty(ConversationId)),
    Latest = max(TimeGenerated)
  by Agent, AgentVersion, AppRoleName
| order by Latest desc
'''
        size: 0
        queryType: 0
        resourceType: 'microsoft.insights/components'
        timeContext: {
          durationMs: 604800000
        }
      }
    }
    {
      type: 3
      name: 'prompt-health'
      content: {
        version: 'KqlItem/1.0'
        title: 'Prompt-agent request health - last 24 hours'
        query: '''
AppDependencies
| where TimeGenerated > ago(24h)
| extend AgentId = tostring(Properties["gen_ai.agent.id"])
| where AgentId startswith "zava-returns-assistant:"
| summarize
    Calls = count(),
    Failures = countif(Success == false),
    AverageDurationMs = round(avg(DurationMs), 1),
    P95DurationMs = round(percentile(DurationMs, 95), 1),
    Conversations = dcount(tostring(Properties["gen_ai.conversation.id"])),
    Latest = max(TimeGenerated)
  by AgentId
'''
        size: 0
        queryType: 0
        resourceType: 'microsoft.insights/components'
        timeContext: {
          durationMs: 86400000
        }
      }
    }
    {
      type: 3
      name: 'operational-findings'
      content: {
        version: 'KqlItem/1.0'
        title: 'Operational findings - failures and high latency'
        query: '''
AppDependencies
| where TimeGenerated > ago(7d)
| extend AgentId = tostring(Properties["gen_ai.agent.id"])
| where AgentId startswith "zava-"
| extend Finding = case(
    Success == false, "Failed dependency",
    DurationMs > 5000, "High latency (>5 seconds)",
    "Healthy"
  )
| summarize Occurrences = count(), Latest = max(TimeGenerated) by AgentId, Finding
| order by Finding asc, Occurrences desc
'''
        size: 0
        queryType: 0
        resourceType: 'microsoft.insights/components'
        timeContext: {
          durationMs: 604800000
        }
      }
    }
    {
      type: 3
      name: 'trace-timeline'
      content: {
        version: 'KqlItem/1.0'
        title: 'Agent telemetry volume - last 24 hours'
        query: '''
union AppDependencies, AppRequests, AppTraces
| where TimeGenerated > ago(24h)
| extend AgentId = tostring(Properties["gen_ai.agent.id"])
| extend AgentName = tostring(Properties["gen_ai.agent.name"])
| extend Agent = case(
    isnotempty(AgentName), AgentName,
    isnotempty(AgentId), tostring(split(AgentId, ":")[0]),
    AppRoleName
  )
| where Agent startswith "zava-"
| summarize Records = count() by bin(TimeGenerated, 15m), Agent
| render timechart
'''
        size: 0
        queryType: 0
        resourceType: 'microsoft.insights/components'
        timeContext: {
          durationMs: 86400000
        }
      }
    }
  ]
  styleSettings: {}
  '$schema': 'https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json'
}

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: guid(resourceGroup().id, workbookDisplayName)
  location: location
  kind: 'shared'
  tags: {
    scenario: 'zava-control-plane'
    workload: 'microsoft-foundry'
  }
  properties: {
    category: 'workbook'
    description: 'Live prompt, hosted, and external agent telemetry with security and governance evidence.'
    displayName: workbookDisplayName
    serializedData: string(workbookContent)
    sourceId: applicationInsightsResourceId
    version: 'Notebook/1.0'
  }
}

output workbookId string = workbook.id
output workbookName string = workbook.name
output portalUrl string = 'https://portal.azure.com/#@${tenant().tenantId}/resource${workbook.id}'
