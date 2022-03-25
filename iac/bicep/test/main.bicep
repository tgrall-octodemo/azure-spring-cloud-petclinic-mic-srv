@maxLength(20)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'petclinic${uniqueString(resourceGroup().id)}'

param location string = 'centralindia '
// param rgName string = 'rg-${appName}'

@description('The Azure Spring Cloud Resource Provider ID')
param azureSpringCloudRp string

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

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

@description('The Azure Spring Cloud monitoring Settings name')
@allowed([
  'default'
])
param monitoringSettingsName string = 'default'

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
    monitoringSettingsName: monitoringSettingsName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
    appInsightsDiagnosticSettingsName: appInsightsDiagnosticSettingsName
    zoneRedundant: zoneRedundant
  }
}
