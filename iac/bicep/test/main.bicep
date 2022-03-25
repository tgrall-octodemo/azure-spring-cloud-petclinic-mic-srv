@maxLength(20)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'petclinic${uniqueString(resourceGroup().id)}'

param location string = 'centralindia '
// param rgName string = 'rg-${appName}'

@description('The Azure Spring Cloud Resource Provider ID')
param azureSpringCloudRp string

@maxLength(24)
@description('The name of the KV, must be UNIQUE.  A vault name must be between 3-24 alphanumeric characters.')
param kvName string // = 'kv-${appName}'

@description('The name of the KV RG')
param kvRGName string

param setKVAccessPolicies bool = false

@description('Is KV Network access public ?')
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'enabled'

@description('The KV SKU name')
@allowed([
  'premium'
  'standard'
])
param kvSkuName string = 'standard'

@description('Specifies all KV secrets {"secretName":"","secretValue":""} wrapped in a secure object.')
@secure()
param secretsObject object

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

@description('The MySQL DB Admin Login.')
param administratorLogin string = 'mys_adm'

@secure()
@description('The MySQL DB Admin Password.')
param administratorLoginPassword string

@description('Allow client workstation to MySQL for local Dev/Test only')
param clientIPAddress string

@description('Allow Azure Spring Cloud from Apps subnet to access MySQL DB')
param startIpAddress string = '10.42.1.0'

@description('Allow Azure Spring Cloud from Apps subnet to access MySQL DB')
param endIpAddress string = '10.42.1.15'

param vnetName string = 'vnet-azure-spring-cloud'
param vnetCidr string = '10.42.0.0/21 '

@description('The name or ID of an existing subnet in "vnet" into which to deploy the Spring Cloud app. Required when deploying into a Virtual Network. Smaller subnet sizes are supported, please refer: https://aka.ms/azure-spring-cloud-smaller-subnet-vnet-docs.')
param appSubnetCidr string = '10.42.1.0/28'

@description('The name or ID of an existing subnet in "vnet" into which to deploy the Spring Cloud service runtime. Required when deploying into a Virtual Network.')
param serviceRuntimeSubnetCidr string = '10.42.2.0/28'

@description('Comma-separated list of IP address ranges in CIDR format. The IP ranges are reserved to host underlying Azure Spring Cloud infrastructure, which should be 3 at least /16 unused IP ranges, must not overlap with any Subnet IP ranges. Addresses 10.2.0.0/16 matching the format *.*.*.0 or *.*.*.255 are reserved and cannot be used')
param serviceCidr string = '10.0.0.1/16,10.1.0.1/16,10.2.0.1/16' // Addresses 10.2.0.0/16 matching the format *.*.*.0 or *.*.*.255 are reserved and cannot be used
param serviceRuntimeSubnetName string = 'snet-svc-run'
param appSubnetName string = 'snet-app'
param zoneRedundant bool = false

@description('The resource group where all network resources for apps will be created in')
param appNetworkResourceGroup string 

@description('The resource group where all network resources for Azure Spring Cloud service runtime will be created in')
param serviceRuntimeNetworkResourceGroup string 

@description('The Log Analytics workspace name used by Azure Spring Cloud instance')
param logAnalyticsWorkspaceName string = 'log-${appName}'

param appInsightsName string = 'appi-${appName}'
param appInsightsDiagnosticSettingsName string = 'dgs-${appName}-send-logs-and-metrics-to-log-analytics'

@description('The Azure Spring Cloud instance name')
param azureSpringCloudInstanceName string = 'asc-${appName}'

// Check SKU REST API : https://docs.microsoft.com/en-us/rest/api/azurespringcloud/skus/list#code-try-0
@description('The Azure Spring Cloud SKU Capacity, ie Max App instances')
@minValue(8)
@maxValue(25)
param azureSpringCloudSkuCapacity int = 25

@description('The Azure Spring Cloud SKU name')
@allowed([
  'BO'
  'S0'
  'E0'
])
param azureSpringCloudSkuName string = 'S0'

@allowed([
  'Basic'
  'Standard'
  'Enterprise'
])
@description('The Azure Spring Cloud SKU Tier')
param azureSpringCloudTier string = 'Standard'

@description('The Azure Spring Cloud Git Config Server name')
@allowed([
  'default'
])
param configServerName string = 'default'

@description('The Azure Spring Cloud monitoring Settings name')
@allowed([
  'default'
])
param monitoringSettingsName string = 'default'

@description('The Azure Spring Cloud Service Registry name. only "default" is supported')
@allowed([
  'default'
])
param serviceRegistryName string = 'default' // The resource name 'Azure Spring Cloud Service Registry' is not valid

@description('The Azure Spring Cloud Config Server Git URI (The repo must be public).')
param gitConfigURI string


// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scope-extension-resources
module roleAssignments 'roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    vnetName: vnetName
    subnetName: appSubnetName
    kvName: kvName
    kvRGName: kvRGName
    networkRoleType: 'Owner'
    kvRoleType: 'KeyVaultReader'
    azureSpringCloudRp: azureSpringCloudRp
  }
}

module azurespringcloud 'asc.bicep' = {
  name: 'azurespringcloud'
  // scope: resourceGroup(rg.name)
  params: {
    appName: appName
    location: location
    azureSpringCloudInstanceName: azureSpringCloudInstanceName
    azureSpringCloudSkuCapacity: azureSpringCloudSkuCapacity
    azureSpringCloudSkuName: azureSpringCloudSkuName
    azureSpringCloudTier: azureSpringCloudTier
    appNetworkResourceGroup: appNetworkResourceGroup
    monitoringSettingsName: monitoringSettingsName
    serviceRuntimeNetworkResourceGroup: serviceRuntimeNetworkResourceGroup
    configServerName: configServerName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
    appInsightsDiagnosticSettingsName: appInsightsDiagnosticSettingsName
    zoneRedundant: zoneRedundant
  }
  dependsOn: [
    roleAssignments
  ]
}
