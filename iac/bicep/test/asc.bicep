// https://docs.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring?tabs=bicep
@description('A UNIQUE name')
@maxLength(20)
param appName string = '101-${uniqueString(deployment().name)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

@description('The Azure Active Directory tenant ID that should be used to manage Azure Spring Cloud Apps Identity.')
param tenantId string = subscription().tenantId

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

@description('The Azure Spring Cloud SKU name. Check it out at https://docs.microsoft.com/en-us/rest/api/azurespringcloud/skus/list#code-try-0')
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
@description('The Azure Spring Cloud SKU Tier. Check it out at https://docs.microsoft.com/en-us/rest/api/azurespringcloud/skus/list#code-try-0')
param azureSpringCloudTier string = 'Standard'

param appNetworkResourceGroup string 
param serviceRuntimeNetworkResourceGroup string 

param zoneRedundant bool = false

@description('The Azure Spring Cloud Git Config Server name. Only "default" is supported')
@allowed([
  'default'
])
param configServerName string = 'default'

@description('The Azure Spring Cloud monitoring Settings name. Only "default" is supported')
@allowed([
  'default'
])
param monitoringSettingsName string = 'default'


// https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?tabs=bicep
resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
}
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.id

// pre-req: https://docs.microsoft.com/en-us/azure/spring-cloud/quickstart-deploy-infrastructure-vnet-bicep
// https://docs.microsoft.com/en-us/azure/spring-cloud/quickstart-deploy-infrastructure-vnet-azure-cli#prerequisites
resource azurespringcloud 'Microsoft.AppPlatform/Spring@2022-01-01-preview' = {
  name: azureSpringCloudInstanceName
  location: location
  sku: {
    capacity: azureSpringCloudSkuCapacity
    name: azureSpringCloudSkuName
    tier: azureSpringCloudTier
  }
  properties: {}
  // zoneRedundant: zoneRedundant
}

output azureSpringCloudResourceId string = azurespringcloud.id
output azureSpringCloudFQDN string = azurespringcloud.properties.fqdn

// https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/components?tabs=bicep
// https://docs.microsoft.com/en-us/rest/api/application-insights/components/get#applicationinsightscomponent
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    // ImmediatePurgeDataOn30Days: true // "ImmediatePurgeDataOn30Days cannot be set on current api-version"
    IngestionMode: 'LogAnalytics' // Cannot set ApplicationInsightsWithDiagnosticSettings as IngestionMode on consolidated application 
    Request_Source: 'rest'
    RetentionInDays: 30
    SamplingPercentage: 20
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}
output appInsightsResourceId string = appInsights.id
output appInsightsAppId string = appInsights.properties.AppId
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString

// https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings?tabs=bicep
resource appInsightsDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: appInsightsDiagnosticSettingsName
  scope: azurespringcloud
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'ApplicationConsole'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'SystemLogs'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'IngressLogs'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }    
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
  }
}

resource azurespringcloudmonitoringSettings 'Microsoft.AppPlatform/Spring/monitoringSettings@2022-03-01-preview' = {
  name: monitoringSettingsName
  parent: azurespringcloud
  properties: {
    appInsightsInstrumentationKey: 'InstrumentationKey=b87334be-2d70-446b-a193-f32918ca4314;IngestionEndpoint=https://northeurope-2.in.applicationinsights.azure.com/' // DO NOT USE the InstrumentationKey appInsights.properties.InstrumentationKey
    appInsightsSamplingRate: 10
    // traceEnabled: true Indicates whether enable the trace functionality, which will be deprecated since api version 2020-11-01-preview. Please leverage appInsightsInstrumentationKey to indicate if monitoringSettings enabled or not
  }
}
