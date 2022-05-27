param keyVaultName string
param location string
param functionAppKeySecretName string
@secure()
param functionAppKey string
param managedIdentityName string
param logAnalyticsWorkspaceName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: false
    accessPolicies: [
      {
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
        objectId: managedIdentity.properties.principalId
        tenantId: managedIdentity.properties.tenantId
      }
    ]
  }
  resource functionAppKeySecret 'secrets@2021-10-01' = {
    name: functionAppKeySecretName
    properties: {
      value: functionAppKey
    }
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = {
  name: 'Logging'
  scope: keyVault
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
      {
        category: 'AzurePolicyEvaluationDetails'
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

output keyVaultName string = keyVault.name
output functionAppKeyName string = functionAppKeySecretName
