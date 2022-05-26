param trafficManagerName string
param applicationGatewayRegion1Name string
param publicIpRegion1Name string
param applicationGatewayRegion2Name string
param publicIpRegion2Name string
param logAnalyticsWorkspaceName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource publicIpRegion1 'Microsoft.Network/publicIPAddresses@2021-08-01' existing = {
  name: publicIpRegion1Name
}

resource publicIpRegion2 'Microsoft.Network/publicIPAddresses@2021-08-01' existing = {
  name: publicIpRegion2Name
}

resource trafficManager 'Microsoft.Network/trafficmanagerprofiles@2018-08-01' = {
  name: trafficManagerName
  location: 'Global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Performance'
    dnsConfig: {
      relativeName: trafficManagerName
      ttl: 60
    }
    monitorConfig: {
      profileMonitorStatus: 'Online'
      protocol: 'HTTP'
      port: 80
      path: '/'
      toleratedNumberOfFailures: 3
      intervalInSeconds: 30
      timeoutInSeconds: 10
    }
    endpoints: [
      {
        name: applicationGatewayRegion1Name
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          target: publicIpRegion1.properties.dnsSettings.fqdn
          targetResourceId: publicIpRegion1.id
          weight: 1
          priority: 1
          endpointLocation: publicIpRegion1.location
        }
      }
      {
        name: applicationGatewayRegion2Name
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          target: publicIpRegion2.properties.dnsSettings.fqdn
          targetResourceId: publicIpRegion2.id
          weight: 1
          priority: 2
          endpointLocation: publicIpRegion2.location
        }
      }
    ]
    trafficViewEnrollmentStatus: 'Enabled'
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Logging'
  scope: trafficManager
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'ProbeHealthStatusEvents'
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

output trafficManagerName string = trafficManager.name
