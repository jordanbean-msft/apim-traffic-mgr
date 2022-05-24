param appName string
param environment string
param region1 string
param region2 string
param location1 string = resourceGroup().location
param location2 string
param apiManagementServicePublisherEmail string
param apiManagementServicePublisherName string
param shouldEnablePrivateEndpoint bool

module names 'resource-names.bicep' = {
  name: 'resource-names'
  params: {
    appName: appName
    region1: region1
    region2: region2
    env: environment
  }
}

module loggingDeployment 'logging.bicep' = {
  name: 'logging-deployment'
  params: {
    logAnalyticsWorkspaceName: names.outputs.logAnalyticsWorkspaceName
    location: location1
    appInsightsName: names.outputs.appInsightsName
    functionAppRegion1Name: names.outputs.region1FunctionName
    functionAppRegion2Name: names.outputs.region2FunctionName
  }
}

module storageRegion1Deployment 'storage.bicep' = {
  name: 'storage-${region1}-deployment'
  params: {
    location: location1
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    storageAccountName: names.outputs.region1StorageAccountName
  }
}

module storageRegion2Deployment 'storage.bicep' = {
  name: 'storage-${region2}-deployment'
  params: {
    location: location2
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    storageAccountName: names.outputs.region2StorageAccountName
  }
}

module virtualNetworkRegion1Deployment 'virtual-network.bicep' = {
  name: 'virtual-network-${region1}-deployment'
  params: {
    applicationGatewaySubnetName: names.outputs.applicationGatewaySubnetName
    applicationSubnetName: names.outputs.applicationSubnetName
    location: location1
    privateEndpointSubnetName: names.outputs.privateEndpointSubnetName
    vNetName: names.outputs.region1vNetName
  }
}

module virtualNetworkRegion2Deployment 'virtual-network.bicep' = {
  name: 'virtual-network-${region2}-deployment'
  params: {
    applicationGatewaySubnetName: names.outputs.applicationGatewaySubnetName
    applicationSubnetName: names.outputs.applicationSubnetName
    location: location2
    privateEndpointSubnetName: names.outputs.privateEndpointSubnetName
    vNetName: names.outputs.region2vNetName
  }
}

module dnsZoneDeployment 'dns.bicep' = {
  name: 'dns-zone-deployment'
  params: {
    privateDnsZoneName: names.outputs.privateDnsZoneName
    region1vNetName: virtualNetworkRegion1Deployment.outputs.vNetName
    region2vNetName: virtualNetworkRegion2Deployment.outputs.vNetName
  }
}

module functionRegion1Deployment 'function.bicep' = {
  name: 'function-${region1}-deployment'
  params: {
    applicationSubnetName: virtualNetworkRegion1Deployment.outputs.applicationSubnetName
    appServicePlanName: names.outputs.region1AppServicePlanName
    functionAppApplicationEndpointName: names.outputs.region1functionAppApplicationEndpointName
    functionAppHealthProbeEndpointName: names.outputs.region1functionAppHealthProbeEndpointName
    functionAppName: names.outputs.region1FunctionName
    functionAppNetworkInterfaceName: names.outputs.region1functionAppNetworkInterfaceName
    functionAppPrivateEndpointName: names.outputs.region1functionAppPrivateEndpointName
    location: location1
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    privateEndpointSubnetName: virtualNetworkRegion1Deployment.outputs.privateEndpointSubnetName
    vNetName: virtualNetworkRegion1Deployment.outputs.vNetName
    privateDnsZoneName: dnsZoneDeployment.outputs.privateDnsZoneName
    storageAccountName: storageRegion1Deployment.outputs.storageAccountName
    appInsightsName: loggingDeployment.outputs.appInsightsName
    shouldEnablePrivateEndpoint: shouldEnablePrivateEndpoint
  }
}

module functionRegion2Deployment 'function.bicep' = {
  name: 'function-${region2}-deployment'
  params: {
    applicationSubnetName: virtualNetworkRegion2Deployment.outputs.applicationSubnetName
    appServicePlanName: names.outputs.region2AppServicePlanName
    functionAppApplicationEndpointName: names.outputs.region2functionAppApplicationEndpointName
    functionAppHealthProbeEndpointName: names.outputs.region2functionAppHealthProbeEndpointName
    functionAppName: names.outputs.region2FunctionName
    functionAppNetworkInterfaceName: names.outputs.region2functionAppNetworkInterfaceName
    functionAppPrivateEndpointName: names.outputs.region2functionAppPrivateEndpointName
    location: location2
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    privateEndpointSubnetName: virtualNetworkRegion2Deployment.outputs.privateEndpointSubnetName
    vNetName: virtualNetworkRegion2Deployment.outputs.vNetName
    privateDnsZoneName: dnsZoneDeployment.outputs.privateDnsZoneName
    storageAccountName: storageRegion1Deployment.outputs.storageAccountName
    appInsightsName: loggingDeployment.outputs.appInsightsName
    shouldEnablePrivateEndpoint: shouldEnablePrivateEndpoint
  }
}

module applicationGatewayRegion1Deployment 'application-gateway.bicep' = {
  name: 'application-gateway-${region1}-deployment'
  params: {
    applicationGatewayName: names.outputs.region1ApplicationGatewayName
    applicationGatewaySubnetName: virtualNetworkRegion1Deployment.outputs.applicationGatewaySubnetName
    functionAppHealthProbeEndpointName: functionRegion1Deployment.outputs.functionAppHealthProbeEndpointName
    functionAppName: functionRegion1Deployment.outputs.functionAppName
    location: location1
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    publicIpName: names.outputs.region1PublicIpName
    vNetName: virtualNetworkRegion1Deployment.outputs.vNetName
  }
}

module applicationGatewayRegion2Deployment 'application-gateway.bicep' = {
  name: 'application-gateway-${region2}-deployment'
  params: {
    applicationGatewayName: names.outputs.region2ApplicationGatewayName
    applicationGatewaySubnetName: virtualNetworkRegion2Deployment.outputs.applicationGatewaySubnetName
    functionAppHealthProbeEndpointName: functionRegion2Deployment.outputs.functionAppHealthProbeEndpointName
    functionAppName: functionRegion2Deployment.outputs.functionAppName
    location: location2
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    publicIpName: names.outputs.region2PublicIpName
    vNetName: virtualNetworkRegion2Deployment.outputs.vNetName
  }
}

module apiManagementDeployment 'api-management.bicep' = {
  name: 'api-management-deployment'
  params: {
    apiManagementServiceName: names.outputs.apiManagementServiceName
    apiManagementServicePublisherEmail: apiManagementServicePublisherEmail
    apiManagementServicePublisherName: apiManagementServicePublisherName
    location: location1
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    region1: region1
    region2: region2
  }
}

module frontDoorDeployment 'front-door.bicep' = {
  name: 'front-door-deployment'
  params: {
    apiManagementServiceName: apiManagementDeployment.outputs.apiManagementServiceName
    frontDoorName: names.outputs.frontDoorName
    frontDoorWafPolicyName: names.outputs.frontDoorWafPolicyName
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
  }
}

module trafficManagerDeployment 'traffic-manager.bicep' = {
  name: 'traffic-manager-deployment'
  params: {
    trafficManagerName: names.outputs.trafficManagerName
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    applicationGatewayRegion1Name: applicationGatewayRegion1Deployment.outputs.applicationGatewayName
    applicationGatewayRegion2Name: applicationGatewayRegion2Deployment.outputs.applicationGatewayName
    publicIpRegion1Name: applicationGatewayRegion1Deployment.outputs.publicIpName
    publicIpRegion2Name: applicationGatewayRegion2Deployment.outputs.publicIpName
  }
}
