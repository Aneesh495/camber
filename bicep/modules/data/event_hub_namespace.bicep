metadata description = 'Camber Event Hubs Premium namespace with Kafka protocol and ADLS Gen2 capture'

@description('Name of the Event Hubs namespace')
@minLength(6)
@maxLength(50)
param namespaceName string

@description('Azure region for the Event Hubs namespace')
param location string = resourceGroup().location

@description('Resource tags applied to the namespace')
param tags object = {}

@description('Operational SKU tier')
@allowed([
  'Standard'
  'Premium'
])
param skuTier string = 'Premium'

@description('Capacity processing units')
@minValue(1)
@maxValue(16)
param capacity int = 1

@description('Whether to enable availability zone redundancy')
param zoneRedundant bool = true

@description('Optional Resource ID of the ADLS Gen2 storage account for telemetry capture')
param captureStorageAccountId string = ''

@description('Optional blob container name for event capture archive')
param captureContainerName string = 'telemetry'

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: namespaceName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'StreamingIngest'
  })
  sku: {
    name: skuTier
    tier: skuTier
    capacity: capacity
  }
  properties: {
    zoneRedundant: zoneRedundant
    publicNetworkAccess: publicNetworkAccess
    minimumTlsVersion: '1.2'
    disableLocalAuth: true
  }
}

resource defaultEventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  parent: eventHubNamespace
  name: 'telemetry-stream'
  properties: {
    messageRetentionInDays: 7
    partitionCount: 16
    captureDescription: !empty(captureStorageAccountId) ? {
      enabled: true
      encoding: 'Avro'
      intervalInSeconds: 300
      sizeLimitInBytes: 314572800
      destination: {
        name: 'EventHubArchive.AzureBlockBlob'
        properties: {
          storageAccountResourceId: captureStorageAccountId
          blobContainer: captureContainerName
          archiveNameFormat: '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
        }
      }
    } : null
  }
}

@description('Resource ID of the Event Hubs namespace')
output id string = eventHubNamespace.id

@description('Name of the Event Hubs namespace')
output name string = eventHubNamespace.name

@description('Service Bus endpoint URI for Kafka connection strings')
output serviceBusEndpoint string = eventHubNamespace.properties.serviceBusEndpoint
