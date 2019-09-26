metadata description = 'Camber universal diagnostic settings module for automated log streaming to central Log Analytics'

@description('Name of the diagnostic setting')
param settingName string = 'camber-diagnostic-setting'

@description('Resource ID of the central Log Analytics Workspace')
param workspaceId string

@description('Optional Storage Account ID for archival cold storage')
param storageAccountId string = ''

@description('Optional Event Hub Authorization Rule ID for real-time SIEM streaming')
param eventHubAuthorizationRuleId string = ''

@description('Whether to capture all metric streams')
param enableAllMetrics bool = true

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: settingName
  properties: {
    workspaceId: !empty(workspaceId) ? workspaceId : null
    storageAccountId: !empty(storageAccountId) ? storageAccountId : null
    eventHubAuthorizationRuleId: !empty(eventHubAuthorizationRuleId) ? eventHubAuthorizationRuleId : null
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: enableAllMetrics ? [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ] : []
  }
}

@description('Resource ID of the diagnostic setting')
output id string = diagnosticSettings.id

@description('Name of the diagnostic setting')
output name string = diagnosticSettings.name
