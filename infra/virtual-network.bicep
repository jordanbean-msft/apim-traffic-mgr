param vNetName string
param applicationSubnetName string
param privateEndpointSubnetName string
param applicationGatewaySubnetName string
param location string

resource vNet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: applicationSubnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: [
            {
              name: 'Microsoft.Web.serverfarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: applicationGatewaySubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

output vNetName string = vNet.name
output applicationSubnetName string = applicationSubnetName
output applicationGatewaySubnetName string = applicationGatewaySubnetName
output privateEndpointSubnetName string = privateEndpointSubnetName
