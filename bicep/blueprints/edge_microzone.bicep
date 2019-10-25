metadata description = 'Camber Sovereign Edge Microzone blueprint for disconnected or autonomous edge environments'

@description('Deployment environment identifier')
param environment string = 'edge'

@description('Base workload name')
param workloadName string = 'camber-edge'

@description('Azure region for the edge microzone')
param location string = resourceGroup().location

var uniqueSuffix = take(uniqueString(resourceGroup().id, workloadName), 6)
var vnetName = '${workloadName}-${environment}-vnet'
var nsgName = '${workloadName}-${environment}-nsg'
var batchName = '${take(replace(workloadName, '-', ''), 14)}${uniqueSuffix}ba'
var storageName = '${take(replace(workloadName, '-', ''), 14)}${uniqueSuffix}sa'
var sbName = '${workloadName}-${environment}-servicebus'
var kvName = '${take(replace(workloadName, '-', ''), 12)}${uniqueSuffix}kv'

// 1. Network Security Group
module networkSecurity '../modules/network/network_security_group.bicep' = {
  name: 'deploy-edge-nsg'
  params: {
    nsgName: nsgName
    location: location
    securityRules: [
      {
        name: 'AllowEdgeInternal'
        protocol: '*'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'VirtualNetwork'
        access: 'Allow'
        priority: 100
        direction: 'Inbound'
      }
      {
        name: 'DenyDirectInternetInbound'
        protocol: '*'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: 'Internet'
        destinationAddressPrefix: '*'
        access: 'Deny'
        priority: 4096
        direction: 'Inbound'
      }
    ]
  }
}

// 2. Edge Virtual Network
module virtualNetwork '../modules/network/virtual_network.bicep' = {
  name: 'deploy-edge-vnet'
  params: {
    vnetName: vnetName
    location: location
    addressPrefixes: [
      '10.250.0.0/16'
    ]
    subnets: [
      {
        name: 'BatchPoolSubnet'
        addressPrefix: '10.250.1.0/24'
        networkSecurityGroupId: networkSecurity.outputs.id
      }
      {
        name: 'PrivateLinkSubnet'
        addressPrefix: '10.250.2.0/24'
        networkSecurityGroupId: networkSecurity.outputs.id
        privateEndpointNetworkPolicies: 'Disabled'
      }
    ]
  }
}

// 3. Local Key Vault
module keyVault '../modules/security/key_vault.bicep' = {
  name: 'deploy-edge-kv'
  params: {
    keyVaultName: kvName
    location: location
    skuTier: 'premium'
    publicNetworkAccess: 'Disabled'
  }
}

// 4. Edge Local Storage Account
module storageAccount '../modules/data/storage_account.bicep' = {
  name: 'deploy-edge-storage'
  params: {
    storageAccountName: storageName
    location: location
    skuName: 'Standard_LRS'
    enableHierarchicalNamespace: true
    containers: [
      {
        name: 'edge-spool'
        publicAccess: 'None'
      }
    ]
  }
}

// 5. Asynchronous Store-and-Forward Edge Messaging
module serviceBus '../modules/data/service_bus_namespace.bicep' = {
  name: 'deploy-edge-servicebus'
  params: {
    namespaceName: sbName
    location: location
    messagingUnits: 1
    zoneRedundant: false
    queueNames: [
      'edge-outbox'
      'edge-inbox'
      'edge-deadletter'
    ]
  }
}

// 6. Azure Batch Account for Edge Compute
module batchAccount '../modules/compute/batch_account.bicep' = {
  name: 'deploy-edge-batch'
  params: {
    batchAccountName: batchName
    location: location
    storageAccountId: storageAccount.outputs.id
    publicNetworkAccess: 'Disabled'
    batchPools: [
      {
        name: 'edge-worker-pool'
        vmSize: 'Standard_D4ds_v5'
        targetDedicatedNodes: 2
        enableInterNodeCommunication: true
        subnetId: virtualNetwork.outputs.subnets.BatchPoolSubnet
      }
    ]
  }
}

@description('Resource ID of the Edge VNet')
output vnetId string = virtualNetwork.outputs.id

@description('Resource ID of the Edge Batch Account')
output batchAccountId string = batchAccount.outputs.id

@description('Resource ID of the Edge Service Bus')
output serviceBusId string = serviceBus.outputs.id

@description('Resource ID of the Edge Storage Account')
output storageAccountId string = storageAccount.outputs.id
