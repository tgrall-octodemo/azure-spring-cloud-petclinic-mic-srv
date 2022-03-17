param appName string = '101-${uniqueString(deployment().name)}'

param appInsightsName string = 'appi-${appName}'
param appInsightsDiagnosticSettingsName string = 'dgs-${appName}-send-logs-and-metrics-to-log-analytics'

param logAnalyticsWorkspaceResourceId string = 'log-${appName}'
param location string = 'northeurope'

// https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/components?tabs=bicep
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    ImmediatePurgeDataOn30Days: true
    IngestionMode: 'ApplicationInsightsWithDiagnosticSettings'
    Request_Source: 'rest'
    RetentionInDays: 30
    SamplingPercentage: 20
    WorkspaceResourceId: logAnalyticsWorkspaceResourceId
  }
}

output appInsightsResourceId string = appInsights.id
output appInsightsAppId string = appInsights.properties.AppId
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString

// https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings?tabs=bicep
resource appInsightsDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: appInsightsDiagnosticSettingsName
  scope: SPRING_CLOUD_RESOURCE_ID
  workspaceId: logAnalyticsWorkspaceResourceId
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
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
