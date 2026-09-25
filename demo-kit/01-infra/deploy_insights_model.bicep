targetScope = 'resourceGroup'

@description('Existing Microsoft Foundry account name.')
param foundryAccountName string

@description('GPT-5 or newer model deployment used by Agent Insights.')
param deploymentName string = 'gpt-5-mini'

@description('Model version available in the account region.')
param modelVersion string = '2025-08-07'

@description('GlobalStandard capacity in thousands of tokens per minute.')
param capacity int = 10

resource account 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: foundryAccountName
}

resource insightsModel 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: account
  name: deploymentName
  sku: {
    capacity: capacity
    name: 'GlobalStandard'
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-5-mini'
      version: modelVersion
    }
  }
}

output deploymentName string = insightsModel.name
