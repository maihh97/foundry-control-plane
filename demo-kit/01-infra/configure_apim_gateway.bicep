targetScope = 'resourceGroup'

@description('Name of the existing API Management service.')
param apimName string

@description('Azure region for API Management.')
param location string = resourceGroup().location

@description('Publisher email used by API Management.')
param publisherEmail string = 'noreply@zava.example'

@description('Publisher organization used by API Management.')
param publisherName string = 'Zava'

@description('Name of the existing Microsoft Foundry account that hosts the model.')
param foundryAccountName string

@description('OpenAI model deployment name.')
param modelDeploymentName string = 'gpt-4.1'

@description('Product and subscription name for the Zava demo.')
param productName string = 'zava-ai'

@description('Existing Log Analytics workspace name for APIM diagnostics.')
param logAnalyticsWorkspaceName string = '5geiloganalytics'

var cognitiveServicesUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'a97b65f3-24c7-4388-baec-2e87135dc908'
)

module apimService 'br/public:avm/res/api-management/service:0.14.4' = {
  name: 'apim-${uniqueString(apimName)}'
  params: {
    name: apimName
    location: location
    managedIdentities: {
      systemAssigned: true
    }
    publisherEmail: publisherEmail
    publisherName: publisherName
    sku: 'Developer'
  }
}

resource apim 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimName
}

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: foundryAccountName
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource gatewayInferenceRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: foundryAccount
  name: guid(foundryAccount.id, apim.id, cognitiveServicesUserRoleId)
  properties: {
    principalId: apimService.outputs.systemAssignedMIPrincipalId!
    principalType: 'ServicePrincipal'
    roleDefinitionId: cognitiveServicesUserRoleId
  }
}

resource openAiApi 'Microsoft.ApiManagement/service/apis@2024-05-01' = {
  parent: apim
  name: 'zava-openai'
  properties: {
    apiType: 'http'
    displayName: 'Zava OpenAI Responses'
    path: 'openai'
    protocols: [
      'https'
    ]
    serviceUrl: 'https://${foundryAccountName}.openai.azure.com/openai'
    subscriptionRequired: true
  }
}

resource responsesOperation 'Microsoft.ApiManagement/service/apis/operations@2024-05-01' = {
  parent: openAiApi
  name: 'responses'
  properties: {
    displayName: 'Create response'
    method: 'POST'
    urlTemplate: '/v1/responses'
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-05-01' = {
  parent: openAiApi
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: loadTextContent('../06-cost/apim-policies/zava-openai-gateway.xml')
  }
}

resource product 'Microsoft.ApiManagement/service/products@2024-05-01' = {
  parent: apim
  name: productName
  properties: {
    approvalRequired: false
    displayName: 'Zava AI'
    state: 'published'
    subscriptionRequired: true
  }
}

resource productApi 'Microsoft.ApiManagement/service/products/apis@2024-05-01' = {
  parent: product
  name: openAiApi.name
}

resource subscription 'Microsoft.ApiManagement/service/subscriptions@2024-05-01' = {
  parent: apim
  name: 'zava-demo'
  properties: {
    allowTracing: true
    displayName: 'Zava demo runtime'
    scope: product.id
    state: 'active'
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: apim
  name: 'zava-gateway-logs'
  properties: {
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
      {
        category: 'GatewayLlmLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalytics.id
  }
}

output apiUrl string = '${apim.properties.gatewayUrl}/${openAiApi.properties.path}/v1/responses'
output modelDeploymentName string = modelDeploymentName
output subscriptionName string = subscription.name
