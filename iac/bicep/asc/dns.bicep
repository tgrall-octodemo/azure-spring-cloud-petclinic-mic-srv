@description('A UNIQUE name')
@maxLength(20)
param appName string = '101-${uniqueString(deployment().name)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

param vnetName string = 'vnet-azure-spring-cloud'

@description('The Azure Spring Cloud instance name')
param azureSpringCloudInstanceName string = 'asc-${appName}'

resource azurespringcloud 'Microsoft.AppPlatform/Spring@2022-01-01-preview' existing =  {
  name: azureSpringCloudInstanceName
}

@description('The resource group where all network resources for apps will be created in')
param appNetworkResourceGroup string = 'rg-asc-apps-petclinic'

@description('The resource group where all network resources for Azure Spring Cloud service runtime will be created in')
param serviceRuntimeNetworkResourceGroup string = 'rg-asc-svc-run-petclinic'

resource ascPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'private.azuremicroservices.io'
  location:location
  // properties: {}
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing =  {
  name: vnetName
}
output vnetId string = vnet.id

resource dnsLinklnkASC 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'dns-lnk-asc-petclinic'
  location: location
  parent: ascPrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

output private_dns_link_id string = dnsLinklnkASC.id


resource appNetworkRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: appNetworkResourceGroup
  scope: subscription()
}

resource serviceRuntimeNetworkRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: serviceRuntimeNetworkResourceGroup
  scope: subscription()
}

resource appsAksLb 'Microsoft.Network/loadBalancers@2021-05-01' existing = {
  scope: appNetworkRG
  name: 'kubernetes-internal'
}
output appsAksLbFrontEndIpConfigId string = appsAksLb.properties.frontendIPConfigurations[0].id
output appsAksLbFrontEndIpConfigName string = appsAksLb.properties.frontendIPConfigurations[0].name
output appsAksLbFrontEndIpPrivateIpAddress string = appsAksLb.properties.frontendIPConfigurations[0].properties.privateIPAddress

resource ascServiceRuntime_AksLb 'Microsoft.Network/loadBalancers@2021-05-01' existing = {
  scope: serviceRuntimeNetworkRG
  name: 'kubernetes-internal'
}
output ascServiceRuntime_AksLbFrontEndIpConfigId string = ascServiceRuntime_AksLb.properties.frontendIPConfigurations[0].id
output ascServiceRuntime_AksLbFrontEndIpConfigName string = ascServiceRuntime_AksLb.properties.frontendIPConfigurations[0].name


resource ascAppsRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: azureSpringCloudInstanceName
  parent: ascPrivateDnsZone
  properties: {
    aRecords: [
      {
        ipv4Address: appsAksLb.properties.frontendIPConfigurations[0].properties.privateIPAddress
      }
    ]
    cnameRecord: {
      cname: azureSpringCloudInstanceName
    }
    ttl: 360
  }
}

resource ascAppsTestRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${azureSpringCloudInstanceName}.test'
  parent: ascPrivateDnsZone
  properties: {
    aRecords: [
      {
        ipv4Address: appsAksLb.properties.frontendIPConfigurations[0].properties.privateIPAddress
      }
    ]
    cnameRecord: {
      cname: azureSpringCloudInstanceName
    }
    ttl: 360
  }
}
