metadata description = 'Camber Azure Batch account for high-throughput confidential compute clusters'

@description('Name of the Batch account')
@minLength(3)
@maxLength(24)
param batchAccountName string

@description('Azure region for the Batch account')
param location string = resourceGroup().location

@description('Resource tags applied to the Batch account')
param tags object = {}

@description('Resource ID of the diagnostic and auto-storage storage account')
param storageAccountId string

@description('Resource ID of the user-assigned identity managing Batch encryption')
param userAssignedIdentityId string = ''

@description('Full URI of the Key Vault key for customer-managed encryption')
param keyVaultKeyId string = ''

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Batch compute pool configurations')
param batchPools array = []

resource batchAccount 'Microsoft.Batch/batchAccounts@2024-02-01' = {
  name: batchAccountName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'HighPerformanceBatch'
  })
  identity: !empty(userAssignedIdentityId) ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  } : {
    type: 'SystemAssigned'
  }
  properties: {
    autoStorage: {
      storageAccountId: storageAccountId
    }
    publicNetworkAccess: publicNetworkAccess
    encryption: !empty(keyVaultKeyId) ? {
      keySource: 'Microsoft.KeyVault'
      keyVaultProperties: {
        keyIdentifier: keyVaultKeyId
      }
    } : {
      keySource: 'Microsoft.Batch'
    }
  }
}

resource pools 'Microsoft.Batch/batchAccounts/pools@2024-02-01' = [for pool in batchPools: {
  parent: batchAccount
  name: pool.name
  properties: {
    vmSize: pool.vmSize
    scaleSettings: {
      fixedScale: {
        targetDedicatedNodes: pool.?targetDedicatedNodes ?? 2
        targetLowPriorityNodes: pool.?targetLowPriorityNodes ?? 0
      }
    }
    interNodeCommunication: pool.?enableInterNodeCommunication ?? true
    networkConfiguration: {
      subnetId: pool.subnetId
    }
    deploymentConfiguration: {
      virtualMachineConfiguration: {
        imageReference: {
          publisher: 'canonical'
          offer: '0001-com-ubuntu-server-jammy'
          sku: '22_04-lts'
          version: 'latest'
        }
        nodeAgentSkuId: 'batch.node.ubuntu 22.04'
      }
    }
  }
}]

@description('Resource ID of the Batch account')
output id string = batchAccount.id

@description('Name of the Batch account')
output name string = batchAccount.name

@description('Dedicated account endpoint URI')
output accountEndpoint string = batchAccount.properties.accountEndpoint
