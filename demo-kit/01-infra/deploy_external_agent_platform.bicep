targetScope = 'resourceGroup'

@description('Azure region for the external-agent hosting resources.')
param location string = resourceGroup().location

@description('Existing Microsoft Foundry account used by the external agent.')
param foundryAccountName string

@description('User-assigned identity name for the external-agent runtime.')
param managedIdentityName string = 'id-zava-external-agent'

@description('Azure Container Registry name. Must be globally unique.')
param containerRegistryName string = 'zavaext${uniqueString(subscription().id, resourceGroup().id)}'

@description('Azure Container Apps managed environment name.')
param containerEnvironmentName string = 'cae-zava-external'

var acrPullRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)
var cognitiveServicesUserRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'a97b65f3-24c7-4388-baec-2e87135dc908'
)
var managedIdentityResourceId = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentityName)

module runtimeIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.6.0' = {
  params: {
    name: managedIdentityName
    location: location
    tags: {
      scenario: 'zava-control-plane'
      workload: 'external-agent'
    }
  }
}

module registry 'br/public:avm/res/container-registry/registry:0.13.1' = {
  params: {
    name: containerRegistryName
    location: location
    acrSku: 'Basic'
    acrAdminUserEnabled: false
    anonymousPullEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleSetDefaultAction: 'Allow'
    tags: {
      scenario: 'zava-control-plane'
      workload: 'external-agent'
    }
  }
}

module managedEnvironment 'br/public:avm/res/app/managed-environment:0.16.0' = {
  params: {
    name: containerEnvironmentName
    location: location
    appLogsConfiguration: {
      destination: 'azure-monitor'
    }
    publicNetworkAccess: 'Enabled'
    zoneRedundant: false
    tags: {
      scenario: 'zava-control-plane'
      workload: 'external-agent'
    }
  }
}

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: foundryAccountName
}

resource registryResource 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource registryPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: registryResource
  name: guid(registryResource.id, managedIdentityResourceId, acrPullRoleDefinitionId)
  properties: {
    principalId: runtimeIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleDefinitionId
  }
  dependsOn: [
    registry
  ]
}

resource foundryInferenceRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: foundryAccount
  name: guid(foundryAccount.id, managedIdentityResourceId, cognitiveServicesUserRoleDefinitionId)
  properties: {
    principalId: runtimeIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
  }
}

output containerRegistryName string = containerRegistryName
output containerRegistryLoginServer string = '${containerRegistryName}.azurecr.io'
output managedEnvironmentId string = managedEnvironment.outputs.resourceId
output managedIdentityClientId string = runtimeIdentity.outputs.clientId
output managedIdentityId string = runtimeIdentity.outputs.resourceId
