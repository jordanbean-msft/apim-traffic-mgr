param frontDoorName string
param frontDoorWafPolicyName string
param logAnalyticsWorkspaceName string
param apiManagementServiceName string

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagementServiceName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

var backendPoolName = '${apiManagementService.name}-backend-pool'
var backendPoolSettingName = '${apiManagementService.name}-backend-pool-settings'
var frontendEndpointName = '${apiManagementService.name}-frontend-endpoint'
var healthProbeSettingName = '${apiManagementService.name}-health-probe-setting'
var loadBalancingSettingName = '${apiManagementService.name}-load-balancing-setting'
var routingRuleName = '${apiManagementService.name}-routing-rule'

resource frontDoor 'Microsoft.Network/frontDoors@2020-05-01' = {
  name: frontDoorName
  location: 'Global'
  properties: {
    backendPools: [
      {
        name: backendPoolName
        properties: {
          backends: [
            {
              httpPort: 80
              httpsPort: 443
              backendHostHeader: replace(apiManagementService.properties.gatewayUrl, 'https://', '')
              address: replace(apiManagementService.properties.gatewayUrl, 'https://', '')
              priority: 1
              weight: 1
            }
          ]
          healthProbeSettings: {
            id: '${resourceId('Microsoft.Network/frontDoors', frontDoorName)}/healthProbeSettings/${healthProbeSettingName}'
          }
          loadBalancingSettings: {
            id: '${resourceId('Microsoft.Network/frontDoors', frontDoorName)}/loadBalancingSettings/${loadBalancingSettingName}'
          }
        }
      }
    ]
    backendPoolsSettings: {
      enforceCertificateNameCheck: 'Disabled'
    }
    frontendEndpoints: [
      {
        name: frontendEndpointName
        properties: {
          hostName: '${frontDoorName}.azurefd.net'
          sessionAffinityEnabledState: 'Disabled'
          sessionAffinityTtlSeconds: 0
        }
      }
    ]
    healthProbeSettings: [
      {
        name: healthProbeSettingName
        properties: {
          path: '/'
          protocol: 'Http'
          intervalInSeconds: 30
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: loadBalancingSettingName
        properties: {
          sampleSize: 3
          successfulSamplesRequired: 3
        }
      }
    ]
    routingRules: [
      {
        name: routingRuleName
        properties: {
          acceptedProtocols: [
            'Https'
          ]
          enabledState: 'Enabled'
          frontendEndpoints: [
            {
              id: '${resourceId('Microsoft.Network/frontDoors', frontDoorName)}/frontendEndpoints/${frontendEndpointName}'
            }
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            backendPool: {
              id: '${resourceId('Microsoft.Network/frontDoors', frontDoorName)}/backendPools/${backendPoolName}'
            }
            forwardingProtocol: 'HttpsOnly'
          }
          // webApplicationFirewallPolicyLink: {
          //   id: frontDoorWafPolicy.id
          // }
        }
      }
    ]
  }
}

resource frontDoorWafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2020-11-01' = {
  name: frontDoorWafPolicyName
  location: 'Global'
  properties: {
    policySettings: {
      mode: 'Detection'
      enabledState: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetVersion: '1.0'
          ruleSetType: 'DefaultRuleSet'
        }
      ]
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Logging'
  scope: frontDoor
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'FrontdoorAccessLog'
        enabled: true
      }
      {
        category: 'FrontdoorWebApplicationFirewallLog'
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

output frontDoorName string = frontDoor.name
output frontDoorEndpoint string = 'https://${frontDoor.properties.frontendEndpoints[0].properties.hostName}'
