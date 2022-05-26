param apiManagementServiceName string
param region1 string
param region2 string
param location string
param apiManagementServicePublisherName string
param apiManagementServicePublisherEmail string
param logAnalyticsWorkspaceName string
param trafficManagerName string
param keyVaultName string
param keyVaultSecretName string
param managedIdentityName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource trafficManager 'Microsoft.Network/trafficmanagerprofiles@2018-08-01' existing = {
  name: trafficManagerName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

var apiName = 'appApi'
var apiProductName = 'appProduct'
var apiSubscriptionName = 'appSubscription'
var apiPolicyName = 'policy'
var apiFunctionKeyNamedValueName = 'appFunctionKeyNamedValue'

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    capacity: 1
    name: 'Basic'
  }
  properties: {
    publisherEmail: apiManagementServicePublisherEmail
    publisherName: apiManagementServicePublisherName
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }

  resource api 'apis@2021-08-01' = {
    name: apiName
    properties: {
      displayName: 'App Api'
      apiRevision: '1.0.0.0'
      subscriptionRequired: true
      protocols: [
        'https'
      ]
      path: 'app'
      serviceUrl: 'http://${trafficManager.properties.dnsConfig.fqdn}/api'
      isCurrent: true
    }
    resource operation 'operations@2021-08-01' = {
      name: 'get'
      properties: {
        displayName: 'Get'
        method: 'GET'
        urlTemplate: '/application'
        templateParameters: []
        description: 'Get App'
        responses: []
      }
      resource policy 'policies@2021-08-01' = {
        name: apiPolicyName
        properties: {
          format: 'xml'
          value: '<policies><inbound><base /><set-query-parameter name="code" exists-action="override"><value>{{${apiFunctionKeyNamedValueName}}}</value></set-query-parameter></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
        }
      }
    }
  }

  resource product 'products@2021-08-01' = {
    name: apiProductName
    properties: {
      displayName: 'App Product'
      subscriptionRequired: true
      approvalRequired: false
      state: 'published'
      description: 'App Product Description'
      subscriptionsLimit: 1
    }
    resource api 'apis@2021-08-01' = {
      name: apiName
    }
  }

  resource subscription 'subscriptions@2021-08-01' = {
    name: apiSubscriptionName
    properties: {
      scope: resourceId('Microsoft.ApiManagement/service/products', apiManagementServiceName, product.name)
      displayName: 'App Subscription'
    }
  }

  resource functionKey 'namedValues@2021-08-01' = {
    name: apiFunctionKeyNamedValueName
    properties: {
      displayName: apiFunctionKeyNamedValueName
      secret: true
      keyVault: {
        secretIdentifier: '${keyVault.properties.vaultUri}secrets/${keyVaultSecretName}'
        identityClientId: managedIdentity.properties.clientId
      }
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Logging'
  scope: apiManagementService
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
      {
        category: 'WebSocketConnectionLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output apiManagementServiceName string = apiManagementService.name
