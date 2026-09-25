targetScope = 'resourceGroup'

@description('Azure region for the external-agent runtime.')
param location string = resourceGroup().location

@description('Existing Microsoft Foundry account used by the external agent.')
param foundryAccountName string

@description('Existing model deployment used by the external agent.')
param modelDeploymentName string = 'gpt-4.1'

@description('Existing Application Insights component connected to the Foundry project.')
param applicationInsightsName string = '5geiappinsights'

@description('Existing API Management service used as the external-agent gateway.')
param apimName string

@description('Existing API Management product that grants caller subscriptions.')
param apimProductName string = 'zava-ai'

@description('Existing user-assigned identity for the external-agent runtime.')
param managedIdentityName string = 'id-zava-external-agent'

@description('Existing Azure Container Registry name.')
param containerRegistryName string

@description('Existing Azure Container Apps managed environment name.')
param containerEnvironmentName string = 'cae-zava-external'

@description('Container image including registry server and tag.')
param containerImage string

@description('Container App name for the external LangGraph runtime.')
param containerAppName string = 'ca-zava-returns-langgraph'

@description('CIDR allowed to call the Container App backend. Use the stable APIM public IP.')
param apimOutboundCidr string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerEnvironmentName
}

resource runtimeIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource apim 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimName
}

resource product 'Microsoft.ApiManagement/service/products@2024-05-01' existing = {
  parent: apim
  name: apimProductName
}

module containerApp 'br/public:avm/res/app/container-app:0.23.0' = {
  params: {
    name: containerAppName
    location: location
    environmentResourceId: managedEnvironment.id
    managedIdentities: {
      userAssignedResourceIds: [
        runtimeIdentity.id
      ]
    }
    registries: [
      {
        identity: runtimeIdentity.id
        server: '${containerRegistryName}.azurecr.io'
      }
    ]
    secrets: [
      {
        name: 'applicationinsights-connection-string'
        value: applicationInsights.properties.ConnectionString
      }
    ]
    containers: [
      {
        name: 'zava-returns-langgraph'
        image: containerImage
        env: [
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            secretRef: 'applicationinsights-connection-string'
          }
          {
            name: 'AZURE_CLIENT_ID'
            value: runtimeIdentity.properties.clientId
          }
          {
            name: 'AZURE_OPENAI_ENDPOINT'
            value: 'https://${foundryAccountName}.openai.azure.com'
          }
          {
            name: 'FOUNDRY_MODEL_NAME'
            value: modelDeploymentName
          }
          {
            name: 'OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT'
            value: 'SPAN_AND_EVENT'
          }
          {
            name: 'OTEL_SEMCONV_STABILITY_OPT_IN'
            value: 'gen_ai_latest_experimental'
          }
        ]
        probes: [
          {
            type: 'Startup'
            httpGet: {
              path: '/health'
              port: 8000
            }
            failureThreshold: 30
            periodSeconds: 5
          }
          {
            type: 'Liveness'
            httpGet: {
              path: '/health'
              port: 8000
            }
            initialDelaySeconds: 10
            periodSeconds: 30
          }
          {
            type: 'Readiness'
            httpGet: {
              path: '/health'
              port: 8000
            }
            initialDelaySeconds: 5
            periodSeconds: 10
          }
        ]
        resources: {
          cpu: json('0.5')
          memory: '1Gi'
        }
      }
    ]
    activeRevisionsMode: 'Single'
    ingressAllowInsecure: false
    ingressExternal: true
    ingressTargetPort: 8000
    ingressTransport: 'auto'
    ipSecurityRestrictions: [
      {
        action: 'Allow'
        description: 'Only the stable Zava APIM gateway can call the external-agent backend.'
        ipAddressRange: apimOutboundCidr
        name: 'apim-only'
      }
    ]
    scaleSettings: {
      minReplicas: 1
      maxReplicas: 2
      rules: [
        {
          name: 'http-concurrency'
          http: {
            metadata: {
              concurrentRequests: '10'
            }
          }
        }
      ]
    }
    tags: {
      scenario: 'zava-control-plane'
      workload: 'external-agent'
    }
  }
}

module externalAgentApi 'br/public:avm/res/api-management/service/api:0.2.2' = {
  params: {
    apiManagementServiceName: apimName
    name: 'zava-external-agent'
    displayName: 'Zava External LangGraph Agent'
    description: 'Managed gateway for the Zava external LangGraph returns agent.'
    path: 'agents/zava-returns-langgraph'
    protocols: [
      'https'
    ]
    serviceUrl: 'https://${containerApp.outputs.fqdn}'
    subscriptionRequired: true
    policies: [
      {
        format: 'rawxml'
        value: loadTextContent('../06-cost/apim-policies/zava-external-agent-gateway.xml')
      }
    ]
    operations: [
      {
        name: 'health'
        displayName: 'Health check'
        method: 'GET'
        urlTemplate: '/health'
        responses: [
          {
            statusCode: 200
            description: 'Runtime is healthy.'
          }
        ]
      }
      {
        name: 'invoke'
        displayName: 'Invoke external agent'
        method: 'POST'
        urlTemplate: '/invoke'
        responses: [
          {
            statusCode: 200
            description: 'Agent response.'
          }
        ]
      }
    ]
  }
}

resource externalAgentApiResource 'Microsoft.ApiManagement/service/apis@2024-05-01' existing = {
  parent: apim
  name: 'zava-external-agent'
}

resource productApi 'Microsoft.ApiManagement/service/products/apis@2024-05-01' = {
  parent: product
  name: externalAgentApiResource.name
  dependsOn: [
    externalAgentApi
  ]
}

output backendUrl string = 'https://${containerApp.outputs.fqdn}'
output gatewayHealthUrl string = '${apim.properties.gatewayUrl}/agents/zava-returns-langgraph/health'
output gatewayInvokeUrl string = '${apim.properties.gatewayUrl}/agents/zava-returns-langgraph/invoke'
