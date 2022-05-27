param privateDnsZoneName string
param region1vNetName string
param region2vNetName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource vNetRegion1 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: region1vNetName
}

resource vNetRegion2 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: region2vNetName
}

resource privateDnsZoneLinkRegion1 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZone.name}/${privateDnsZoneName}-${region1vNetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNetRegion1.id
    }
  }
}

resource privateDnsZoneLinkRegion2 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZone.name}/${privateDnsZoneName}-${region2vNetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNetRegion2.id
    }
  }
}

output privateDnsZoneName string = privateDnsZone.name
