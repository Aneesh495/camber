metadata description = 'Camber telemetry, observability, and diagnostic contracts'

@description('Log Analytics pricing tier')
@export()
type logAnalyticsPricingTier = 'PerGB2018' | 'CapacityReservation'

@description('Centralized Log Analytics workspace specification')
@export()
type logAnalyticsSpecification = {
  workspaceName: string
  sku: logAnalyticsPricingTier
  retentionInDays: int
  dailyQuotaGb: int?
  capacityReservationLevel: int?
  enableDataExport: bool
  storageAccountIdForExport: string?
}

@description('Diagnostic metric logging setting')
@export()
type diagnosticMetricSetting = {
  category: string
  enabled: bool
  retentionPolicyDays: int?
}

@description('Diagnostic log stream setting')
@export()
type diagnosticLogSetting = {
  category: string?
  categoryGroup: string?
  enabled: bool
  retentionPolicyDays: int?
}

@description('Universal diagnostic settings specification')
@export()
type diagnosticSettingsSpecification = {
  settingName: string
  workspaceId: string
  storageAccountId: string?
  eventHubAuthorizationRuleId: string?
  metrics: diagnosticMetricSetting[]
  logs: diagnosticLogSetting[]
}

@description('Azure Monitor Data Collection Rule destination')
@export()
type dcrDestination = {
  logAnalyticsWorkspaceResourceId: string
  name: string
}

@description('Data Collection Rule data flow stream specification')
@export()
type dcrDataFlow = {
  streams: string[]
  destinations: string[]
  transformKql: string?
  outputStream: string?
}

@description('Metric alert aggregation operator')
@export()
type metricAlertOperator = 'GreaterThan' | 'GreaterThanOrEqual' | 'LessThan' | 'LessThanOrEqual'

@description('Metric alert time aggregation type')
@export()
type timeAggregationType = 'Average' | 'Minimum' | 'Maximum' | 'Total' | 'Count'

@description('Metric alert criterion definition')
@export()
type metricAlertCriterion = {
  name: string
  metricName: string
  metricNamespace: string
  operator: metricAlertOperator
  timeAggregation: timeAggregationType
  threshold: int
}

@description('Metric alert rule specification')
@export()
type metricAlertRuleSpecification = {
  alertName: string
  description: string
  severity: int
  enabled: bool
  scopes: string[]
  evaluationFrequency: string
  windowSize: string
  criteria: metricAlertCriterion[]
  actionGroupIds: string[]
}
