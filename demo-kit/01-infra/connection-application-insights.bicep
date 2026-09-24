// Foundry Control Plane demo kit — 01 App Insights connection on an EXISTING Foundry account + project (verbatim key parts)
// Source: https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-bicep/01-connections/connection-application-insights.bicep
// Verify against source before running: the official file is longer; this sample keeps the parameters and two
// connection resources and the role assignments verbatim, but ELIDED the `existing` account/project references and the optional
// Microsoft.Insights/components@2020-02-02 creation block. Fetch the full file from the URL above — do not run this excerpt as-is.
// Header comment (verbatim): "It creates the connection on both the Microsoft Foundry account and the project, and assigns the
// project's system-assigned managed identity read access on the Application Insights component so evaluation can read the agent
// traces (Privileged Monitoring Data Reader is required to read GenAI content). Only one application insights can be set on a
// project at a time."

param aiFoundryName string = '<your-account-name>'
@description('Name of the project (sub-resource of the AI Foundry account) to create the connection on.')
param aiProjectName string = '<your-project-name>'
param connectedResourceName string = 'appi${aiFoundryName}'
param location string = 'westus'
// Share connection with all users
param isSharedToAll bool = true
// Whether to create a new Azure Application Insights resource
@allowed([
  'new'
  'existing'
])
param newOrExisting string = 'new'
// Log Analytics Reader + Privileged Monitoring Data Reader (latter required to read GenAI content)
param roleDefinitionGuids array = [
  '73c42c96-874c-492b-b04d-ab87d138a893'
  'dbc9c667-e97f-4491-aee6-90b9cf960190'
]

// ... (existing account/project refs and optional Microsoft.Insights/components@2020-02-02 creation elided, see URL)
//     The elided block declares: `aiFoundry` (existing Microsoft.CognitiveServices/accounts), `aiProject` (existing
//     .../projects with system-assigned identity), `newAppInsights` (conditional on newOrExisting == 'new') and `appInsights`.

// Creates the Azure Foundry account-level connection to your Application Insights resource
resource accountConnection 'Microsoft.CognitiveServices/accounts/connections@2025-04-01-preview' = {
  name: '${aiFoundryName}-appinsights'
  parent: aiFoundry
  properties: {
    category: 'AppInsights'
    target: appInsights.id
    authType: 'ApiKey'
    isSharedToAll: isSharedToAll
    credentials: {
      key: appInsights.properties.ConnectionString
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: appInsights.id
    }
  }
  dependsOn: [
    newAppInsights
  ]
}
// Creates the project-level connection to your Application Insights resource
resource projectConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = {
  name: connectedResourceName
  parent: aiProject
  properties: {
    category: 'AppInsights'
    target: appInsights.id
    authType: 'ApiKey'
    isSharedToAll: isSharedToAll
    credentials: {
      key: appInsights.properties.ConnectionString
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: appInsights.id
    }
  }
  dependsOn: [
    newAppInsights
  ]
}
resource appInsightsReaderRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleGuid in roleDefinitionGuids: {
  scope: appInsights
  name: guid(aiProject.id, roleGuid, appInsights.id)
  properties: {
    principalId: aiProject.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleGuid)
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    newAppInsights
  ]
}]
