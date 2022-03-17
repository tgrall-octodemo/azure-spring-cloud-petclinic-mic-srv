// Bicep Templaytes availables at https://github.com/Azure/bicep/tree/main/docs/examples/2

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#uniquestring
// uniqueString: You provide parameter values that limit the scope of uniqueness for the result. You can specify whether the name is unique down to subscription, resource group, or deployment.
// The returned value isn't a random string, but rather the result of a hash function. The returned value is 13 characters long. It isn't globally unique

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#guid
//guid function: Returns a string value containing 36 characters, isn't globally unique
// Unique scoped to deployment for a resource group
// param appName string = 'demo${guid(resourceGroup().id, deployment().name)}'

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-string#newguid
// Returns a string value containing 36 characters in the format of a globally unique identifier. 
// /!\ This function can only be used in the default value for a parameter.

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-date#utcnow
// You can only use this function within an expression for the default value of a parameter.
@maxLength(20)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'petclinic${uniqueString(resourceGroup().id)}'

param location string = 'westus'
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
param appSubnetCidr string = '10.42.1.0/28'
param serviceRuntimeSubnetCidr string = '10.42.2.0/28'
param serviceCidr string = '10.42.3.0/28'
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
param configServerName string = 'Config-Server'

@description('The Azure Spring Cloud monitoring Settings name')
param monitoringSettingsName string = 'Monitoring'

@description('The Azure Spring Cloud Service Registry name')
param serviceRegistryName string = 'Azure Spring Cloud Service Registry'

@description('The Azure Spring Cloud Config Server Git URI (The repo must be public).')
param gitConfigURI string

/*
module rg 'rg.bicep' = {
  name: 'rg-bicep-${appName}'
  scope: subscription()
  params: {
    rgName: rgName
    location: location
  }
}
*/

// https://docs.microsoft.com/en-us/azure/spring-cloud/how-to-deploy-in-azure-virtual-network?tabs=azure-portal#virtual-network-requirements
module vnet 'vnet.bicep' = {
  name: 'vnet-azurespringcloud'
  // scope: resourceGroup(rg.name)
  params: {
     location: location
     vnetName: vnetName
     serviceRuntimeSubnetName: serviceRuntimeSubnetName
     serviceRuntimeSubnetCidr: serviceRuntimeSubnetCidr
     appSubnetName: appSubnetName
     appSubnetCidr: appSubnetCidr
     vnetCidr: vnetCidr
  }   
}


module mysql '../mysql/mysql.bicep' = {
  name: 'mysqldb'
  params: {
    appName: appName
    location: location
    clientIPAddress: clientIPAddress
    startIpAddress: startIpAddress
    endIpAddress: endIpAddress
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scope-extension-resources
module roleAssignments 'roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    vnetName: vnetName
    subnetName: appSubnetName
    kvName: kvName
    kvRGName: kvRGName
    networkRoleType: 'NetworkContributor'
    kvRoleType: 'KeyVaultReader'
    azureSpringCloudRp: azureSpringCloudRp
  }
  dependsOn: [
    vnet
  ]  
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
    appSubnetId: vnet.outputs.appSubnetSubnetId
    monitoringSettingsName: monitoringSettingsName
    serviceRuntimeNetworkResourceGroup: serviceRuntimeNetworkResourceGroup
    serviceRuntimeSubnetId: vnet.outputs.serviceRuntimeSubnetId
    serviceCidr: serviceCidr
    configServerName: configServerName
    gitConfigURI: gitConfigURI
    serviceRegistryName: serviceRegistryName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
    appInsightsDiagnosticSettingsName: appInsightsDiagnosticSettingsName
    zoneRedundant: zoneRedundant
    mySQLResourceID: mysql.outputs.mySQLResourceID
  }
  dependsOn: [
    roleAssignments
  ]
}


var vNetRules = [
  {
    'id': vnet.outputs.serviceRuntimeSubnetId
    'ignoreMissingVnetServiceEndpoint': false
  }
  {
    'id': vnet.outputs.appSubnetSubnetId
    'ignoreMissingVnetServiceEndpoint': false
  }  
]

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/key-vault-parameter?tabs=azure-cli
/*
The user who deploys the Bicep file must have the Microsoft.KeyVault/vaults/deploy/action permission for the scope 
of the resource group and key vault. 
The Owner and Contributor roles both grant this access.
If you created the key vault, you're the owner and have the permission.
*/


// Specifies all Apps Identities {"appName":"","appIdentity":""} wrapped into an object.')
var appsObject = { 
  apps: [
    {
    appName: 'customers-service'
    appIdentity: azurespringcloud.outputs.customersServiceIdentity
    }
    {
    appName: 'vets-service'
    appIdentity: azurespringcloud.outputs.vetsServiceIdentity
    }
    {
    appName: 'visits-service'
    appIdentity: azurespringcloud.outputs.visitsServiceIdentity
    }
  ]
}

// allow to Azure Spring Cloud subnetID and azureSpringCloudAppIdentity
module KeyVault '../kv/kv.bicep'= {
  name: kvName
  scope: resourceGroup(kvRGName)
  params: {
    location: location
    skuName: kvSkuName
    tenantId: tenantId
    publicNetworkAccess: publicNetworkAccess
    vNetRules: vNetRules
    setKVAccessPolicies: true
    appsObject: appsObject
  } 
}

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-secrets
module KeyVaultsecrets '../kv/kv_sec_key.bicep'= {
  name: 'KeyVaultsecrets'
  scope: resourceGroup(kvRGName)
  params: {
    kvName: kvName
    appName: appName
    secretsObject: secretsObject
  }
}
