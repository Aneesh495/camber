metadata description = 'Camber centralized Log Analytics Workspace with 730-day retention and automated data export'

@description('Name of the Log Analytics Workspace')
param workspaceName string

@description('Azure region for the workspace')
param location string = resourceGroup().location

@description('Resource tags applied to the workspace')
param tags object = {}

@description('Operational retention period in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 730

@description('Pricing tier SKU for the workspace')
@allowed([
  'PerGB2018'
  'CapacityReservation'
])
param sku string = 'PerGB2018'

@description('Optional daily ingestion volume cap in gigabytes')
param dailyQuotaGb int = -1

@description('Optional Storage Account ID destination for continuous data export')
param storageAccountIdForExport string = ''

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'TelemetryDataLake'
  })
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    workspaceCapping: dailyQuotaGb > 0 ? {
      dailyQuotaGb: dailyQuotaGb
    } : null
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      immediatePurgeDataOn30Days: false
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource dataExport 'Microsoft.OperationalInsights/workspaces/dataExports@2020-08-01' = if (!empty(storageAccountIdForExport)) {
  parent: logAnalyticsWorkspace
  name: 'ExportToColdStorage'
  properties: {
    tableNames: [
      'Heartbeat'
      'Syslog'
      'AzureDiagnostics'
    ]
    destination: {
      resourceId: storageAccountIdForExport
    }
    enable: true
  }
}

@description('Resource ID of the Log Analytics Workspace')
output id string = logAnalyticsWorkspace.id

@description('Name of the Log Analytics Workspace')
output name string = logAnalyticsWorkspace.name

@description('Workspace customer workspace ID GUID')
output customerId string = logAnalyticsWorkspace.properties.customerId

@description('Primary shared authentication key for agent telemetry submission')
#disable-next-line outputs-should-not-contain-secrets
output primarySharedKey string = logAnalyticsWorkspace.listKeys().primarySharedKey
