param applicationGatewayName string
param location string
param logAnalyticsWorkspaceName string
param applicationGatewaySubnetName string
param vNetName string
param publicIpName string
param functionAppName string
param functionAppHealthProbeEndpointName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  name: '${vNetName}/${applicationGatewaySubnetName}'
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower(applicationGatewayName)
      fqdn: '${applicationGatewayName}.${location}.cloudapp.azure.com'
    }
  }
}

var gatewayIpConfigurationName = 'default'
var frontendIpConfigurationName = 'appGwPublicFrontendIp'
var frontendPortName = 'http'
var backendAddressPoolName = functionAppName
var backendHttpSettingsCollectionName = 'backendHttpSettings'
var httpListenerName = 'httpListener'
var requestRoutingRuleName = 'rule1'
var probeName = 'probe1'

resource applicationGateway 'Microsoft.Network/applicationGateways@2021-08-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: gatewayIpConfigurationName
        properties: {
          subnet: {
            id: gatewaySubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontendIpConfigurationName
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendPortName
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendAddressPoolName
        properties: {
          backendAddresses: [
            {
              fqdn: '${functionAppName}.azurewebsites.net'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: backendHttpSettingsCollectionName
        properties: {
          port: 443
          protocol: 'Https'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
          probe: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/probes/${probeName}'
          }
        }
      }
    ]
    httpListeners: [
      {
        name: httpListenerName
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/frontendIPConfigurations/${frontendIpConfigurationName}'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/frontendPorts/${frontendPortName}'
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: requestRoutingRuleName
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/httpListeners/${httpListenerName}'
          }
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/backendAddressPools/${backendAddressPoolName}'
          }
          backendHttpSettings: {
            id: '${resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)}/backendHttpSettingsCollection/${backendHttpSettingsCollectionName}'
          }
        }
      }
    ]
    probes: [
      {
        name: probeName
        properties: {
          protocol: 'Https'
          host: '${functionAppName}.azurewebsites.net'
          port: 443
          path: '/api/${functionAppHealthProbeEndpointName}'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
        }
      }
    ]
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Logging'
  scope: applicationGateway
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
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

output applicationGatewayName string = applicationGateway.name
output publicIpName string = publicIp.name
