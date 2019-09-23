metadata description = 'Camber Azure Monitor Data Collection Rule (DCR) for OS telemetry and security audit streaming'

@description('Name of the Data Collection Rule')
param ruleName string

@description('Azure region for the Data Collection Rule')
param location string = resourceGroup().location

@description('Resource tags applied to the Data Collection Rule')
param tags object = {}

@description('Resource ID of the target Log Analytics Workspace')
param workspaceResourceId string

resource dcr 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: ruleName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'TelemetryPipeline'
  })
  properties: {
    description: 'Camber unified OS performance and security audit telemetry collection pipeline'
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspaceResourceId
          name: 'CentralLogAnalyticsDestination'
        }
      ]
    }
    dataSources: {
      syslog: [
        {
          name: 'SyslogDataSource'
          streams: [
            'Microsoft-Syslog'
          ]
          facilityNames: [
            'auth'
            'authpriv'
            'daemon'
            'kern'
            'syslog'
          ]
          logLevels: [
            'Warning'
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
        }
      ]
      performanceCounters: [
        {
          name: 'LinuxPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            'Processor(*)\\% Processor Time'
            'Memory(*)\\% Available Memory'
            'Logical Disk(*)\\% Free Space'
            'Network Adapter(*)\\Total Bytes Transmitted'
          ]
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Syslog'
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'CentralLogAnalyticsDestination'
        ]
      }
    ]
  }
}

@description('Resource ID of the Data Collection Rule')
output id string = dcr.id

@description('Name of the Data Collection Rule')
output name string = dcr.name

@description('Immutable ID of the Data Collection Rule used in agent association')
output immutableId string = dcr.properties.immutableId
