metadata description = 'Camber Azure Container Apps Managed Environment with internal VNet integration and Dapr sidecars'

@description('Name of the Container Apps Managed Environment')
param environmentName string

@description('Azure region for the environment')
param location string = resourceGroup().location

@description('Resource tags applied to the environment')
param tags object = {}

@description('Resource ID of the dedicated subnet delegated to Microsoft.App/environments')
param infrastructureSubnetId string

@description('Resource ID of the central Log Analytics Workspace')
param logAnalyticsWorkspaceId string

@description('Whether the ingress endpoint is strictly internal within the VNet')
param internalOnly bool = true

@description('Optional Dapr state store component definitions')
param daprStateComponents array = []

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'MicroserviceRuntime'
  })
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2023-09-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspaceId, '2023-09-01').primarySharedKey
      }
    }
    vnetConfiguration: {
      internal: internalOnly
      infrastructureSubnetId: infrastructureSubnetId
    }
    zoneRedundant: true
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
      {
        name: 'Dedicated-D4'
        workloadProfileType: 'D4'
        minimumCount: 1
        maximumCount: 5
      }
    ]
  }
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2024-03-01' = [for comp in daprStateComponents: {
  parent: containerAppsEnvironment
  name: comp.name
  properties: {
    componentType: comp.componentType
    version: comp.?version ?? 'v1'
    ignoreErrors: false
    initTimeout: '5s'
    metadata: comp.metadata
    scopes: comp.?scopes ?? []
  }
}]

@description('Resource ID of the Container Apps Environment')
output id string = containerAppsEnvironment.id

@description('Name of the Container Apps Environment')
output name string = containerAppsEnvironment.name

@description('Default fully qualified domain name of the environment')
output defaultDomain string = containerAppsEnvironment.properties.defaultDomain

@description('Static IP address of the ingress endpoint')
output staticIp string = containerAppsEnvironment.properties.staticIp
