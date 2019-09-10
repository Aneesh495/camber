metadata description = 'Camber hardened ADLS Gen2 Storage Account with WORM immutability and CMEK'

@description('Name of the storage account')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region for the storage account')
param location string = resourceGroup().location

@description('Resource tags applied to the storage account')
param tags object = {}

@description('Storage replication SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Standard_GZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param skuName string = 'Standard_ZRS'

@description('Whether to enable Hierarchical Namespace for ADLS Gen2')
param enableHierarchicalNamespace bool = true

@description('Optional Key Vault Key URI for customer-managed encryption')
param keyVaultKeyId string = ''

@description('Optional User-Assigned Identity Resource ID for Key Vault access')
param userAssignedIdentityId string = ''

@description('Subnet resource IDs permitted by network ACLs')
param allowedSubnetIds array = []

@description('Array of blob container configurations to provision')
param containers array = [
  {
    name: 'telemetry'
    publicAccess: 'None'
  }
  {
    name: 'artifacts'
    publicAccess: 'None'
  }
]

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'HierarchicalStorage'
  })
  identity: !empty(userAssignedIdentityId) ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  } : null
  properties: {
    isHnsEnabled: enableHierarchicalNamespace
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [for subnet in allowedSubnetIds: {
        id: subnet
        action: 'Allow'
      }]
    }
    encryption: {
      services: {
        blob: {
          enabled: true
          keyType: !empty(keyVaultKeyId) ? 'Account' : 'Service'
        }
        file: {
          enabled: true
          keyType: !empty(keyVaultKeyId) ? 'Account' : 'Service'
        }
      }
      keySource: !empty(keyVaultKeyId) ? 'Microsoft.Keyvault' : 'Microsoft.Storage'
      keyvaultproperties: !empty(keyVaultKeyId) ? {
        keyname: last(split(keyVaultKeyId, '/'))
        keyvaulturi: take(keyVaultKeyId, indexOf(keyVaultKeyId, '/keys/'))
      } : null
      requireInfrastructureEncryption: true
    }
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 30
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 30
    }
  }
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [for c in containers: {
  parent: blobServices
  name: c.name
  properties: {
    publicAccess: 'None'
  }
}]

@description('Resource ID of the Storage Account')
output id string = storageAccount.id

@description('Name of the Storage Account')
output name string = storageAccount.name

@description('Primary endpoints dictionary of the storage account')
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
