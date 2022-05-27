param apiManagementServiceName string
param location1 string
param location2 string
param apiManagementServicePublisherName string
param apiManagementServicePublisherEmail string
param logAnalyticsWorkspaceName string
param trafficManagerName string
param keyVaultName string
param keyVaultSecretName string
param managedIdentityName string
param apiManagementServiceApiEndpoint string
param apiManagementServiceApiApplicationEndpoint string
param appInsightsName string

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

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
  location: location1
  sku: {
    capacity: 1
    name: 'Developer'
    //name: 'Premium'
  }
  properties: {
    publisherEmail: apiManagementServicePublisherEmail
    publisherName: apiManagementServicePublisherName
    // additionalLocations: [
    //   {
    //     location: location2
    //     sku: {
    //       capacity: 1
    //       name: 'Premium'
    //     }
    //     disableGateway: false
    //   }
    // ]
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }

  resource logger 'loggers@2021-08-01' = {
    name: appInsightsName
    properties: {
      loggerType: 'applicationInsights'
      credentials: {
        instrumentationKey: appInsights.properties.InstrumentationKey
      }
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
      path: apiManagementServiceApiEndpoint
      serviceUrl: 'http://${trafficManager.properties.dnsConfig.fqdn}/${apiManagementServiceApiEndpoint}'
      isCurrent: true
    }
    resource operation 'operations@2021-08-01' = {
      name: 'get'
      properties: {
        displayName: 'Get'
        method: 'GET'
        urlTemplate: '/${apiManagementServiceApiApplicationEndpoint}'
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
    resource logging 'diagnostics@2021-08-01' = {
      name: 'applicationinsights'
      properties: {
        loggerId: '/loggers/${logger.name}'
        alwaysLog: 'allErrors'
        sampling: {
          percentage: 100
          samplingType: 'fixed'
        }
        frontend: {
          request: {
            headers: []
            body: {}
          }
          response: {
            headers: []
            body: {}
          }
        }
        backend: {
          request: {
            headers: []
            body: {}
          }
          response: {
            headers: []
            body: {}
          }
        }
        httpCorrelationProtocol: 'W3C'
        operationNameFormat: 'Name'
        logClientIp: true
        verbosity: 'information'
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

resource subscription 'Microsoft.ApiManagement/service/subscriptions@2021-08-01' existing = {
  parent: apiManagementService
  name: apiSubscriptionName
}

output apiManagementServiceName string = apiManagementService.name
output apiManagementServiceEndpoint string = '${apiManagementService.properties.gatewayUrl}/${apiManagementServiceApiEndpoint}/${apiManagementServiceApiApplicationEndpoint}'
output apiManagementServiceSubscriptionKey string = subscription.listSecrets().primaryKey
