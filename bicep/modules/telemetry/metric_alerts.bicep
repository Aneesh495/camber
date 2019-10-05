metadata description = 'Camber Azure Monitor metric alert rules for latency, saturation, and error budgets'

@description('Name of the metric alert rule')
param alertName string

@description('Azure region for the alert rule')
param location string = 'global'

@description('Resource tags applied to the alert rule')
param tags object = {}

@description('Resource IDs evaluated by this alert rule')
param scopes array

@description('Alert severity: 0 (Critical), 1 (Error), 2 (Warning), 3 (Informational), 4 (Verbose)')
@minValue(0)
@maxValue(4)
param severity int = 1

@description('Evaluation frequency duration format (e.g. PT1M, PT5M)')
param evaluationFrequency string = 'PT1M'

@description('Aggregation lookback window size format (e.g. PT5M, PT15M)')
param windowSize string = 'PT5M'

@description('Metric namespace string')
param metricNamespace string

@description('Metric name string to evaluate')
param metricName string

@description('Comparison operator')
@allowed([
  'GreaterThan'
  'GreaterThanOrEqual'
  'LessThan'
  'LessThanOrEqual'
])
param operator string = 'GreaterThan'

@description('Numeric threshold for triggering alert condition')
param threshold int

@description('Time aggregation type')
@allowed([
  'Average'
  'Minimum'
  'Maximum'
  'Total'
  'Count'
])
param timeAggregation string = 'Average'

@description('Optional Action Group resource IDs notified on breach')
param actionGroupIds array = []

resource metricAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'SloAlerting'
  })
  properties: {
    description: 'Camber automated SLO metric alert for ${metricName}'
    severity: severity
    enabled: true
    scopes: scopes
    evaluationFrequency: evaluationFrequency
    windowSize: windowSize
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: '${alertName}-criterion'
          metricNamespace: metricNamespace
          metricName: metricName
          operator: operator
          threshold: threshold
          timeAggregation: timeAggregation
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [for agId in actionGroupIds: {
      actionGroupId: agId
    }]
  }
}

@description('Resource ID of the metric alert rule')
output id string = metricAlert.id

@description('Name of the metric alert rule')
output name string = metricAlert.name
