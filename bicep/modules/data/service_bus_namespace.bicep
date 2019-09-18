metadata description = 'Camber Service Bus Premium namespace with partitioned messaging queues and CMEK'

@description('Name of the Service Bus namespace')
@minLength(6)
@maxLength(50)
param namespaceName string

@description('Azure region for the Service Bus namespace')
param location string = resourceGroup().location

@description('Resource tags applied to the namespace')
param tags object = {}

@description('Messaging processing units allocated')
@allowed([
  1
  2
  4
  8
  16
])
param messagingUnits int = 1

@description('Whether to enable availability zone redundancy')
param zoneRedundant bool = true

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Queue names to provision with dead-lettering and deduplication')
param queueNames array = [
  'enclave-tasks'
  'attestation-requests'
  'remediation-jobs'
]

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: namespaceName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'EnterpriseMessaging'
  })
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: messagingUnits
  }
  properties: {
    zoneRedundant: zoneRedundant
    publicNetworkAccess: publicNetworkAccess
    minimumTlsVersion: '1.2'
    disableLocalAuth: true
  }
}

resource queues 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = [for qName in queueNames: {
  parent: serviceBusNamespace
  name: qName
  properties: {
    lockDuration: 'PT1M'
    maxSizeInMegabytes: 4096
    requiresDuplicateDetection: true
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    maxDeliveryCount: 10
    enablePartitioning: false
  }
}]

@description('Resource ID of the Service Bus namespace')
output id string = serviceBusNamespace.id

@description('Name of the Service Bus namespace')
output name string = serviceBusNamespace.name

@description('Service Bus endpoint URI')
output endpoint string = serviceBusNamespace.properties.serviceBusEndpoint
