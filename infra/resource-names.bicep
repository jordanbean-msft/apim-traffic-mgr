param appName string
param region1 string
param region2 string
param env string

output appInsightsName string = 'ai-${appName}-${region1}-${env}'
output logAnalyticsWorkspaceName string = 'la-${appName}-${region1}-${env}'
output region1StorageAccountName string = toLower('sa${appName}${region1}${env}')
output region2StorageAccountName string = toLower('sa${appName}${region2}${env}')
output frontDoorName string = 'fd-${appName}-${region1}-${env}'
output frontDoorWafPolicyName string = 'fdwaf${appName}${region1}${env}'
output apiManagementServiceName string = 'apim-${appName}-${region1}-${env}'
output trafficManagerName string = 'tm-${appName}-${region1}-${env}'
output applicationSubnetName string = 'application'
output privateEndpointSubnetName string = 'privateEndpoints'
output applicationGatewaySubnetName string = 'applicationGateway'
output region1vNetName string = 'vnet-${appName}-${region1}-${env}'
output region2vNetName string = 'vnet-${appName}-${region2}-${env}'
output region1FunctionName string = 'func-${appName}-${region1}-${env}'
output region1AppServicePlanName string = 'asp-${appName}-${region1}-${env}'
output region2FunctionName string = 'func-${appName}-${region2}-${env}'
output region2AppServicePlanName string = 'asp-${appName}-${region2}-${env}'
output region1ApplicationGatewayName string = 'ag-${appName}-${region1}-${env}'
output region2ApplicationGatewayName string = 'ag-${appName}-${region2}-${env}'
output privateDnsZoneName string = 'privatelink.azurewebsites.net'
output region1functionAppApplicationEndpointName string = 'application'
output region2functionAppApplicationEndpointName string = 'application'
output region1functionAppHealthProbeEndpointName string = 'health'
output region2functionAppHealthProbeEndpointName string = 'health'
output region1functionAppNetworkInterfaceName string = 'nic-${appName}-${region1}-${env}'
output region2functionAppNetworkInterfaceName string = 'nic-${appName}-${region2}-${env}'
output region1functionAppPrivateEndpointName string = 'pe-${appName}-${region1}-${env}'
output region2functionAppPrivateEndpointName string = 'pe-${appName}-${region2}-${env}'
output region1PublicIpName string = 'ip-${appName}-${region1}-${env}'
output region2PublicIpName string = 'ip-${appName}-${region2}-${env}'
