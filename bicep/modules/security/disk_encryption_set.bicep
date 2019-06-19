metadata description = 'Camber Disk Encryption Set with Customer-Managed Keys (CMEK) and automated key rotation'

@description('Name of the Disk Encryption Set')
param diskEncryptionSetName string

@description('Azure region for the Disk Encryption Set')
param location string = resourceGroup().location

@description('Resource tags applied to the Disk Encryption Set')
param tags object = {}

@description('Resource ID of the source Key Vault containing the encryption key')
param keyVaultId string

@description('Full versioned or unversioned URL of the Key Vault cryptographic key')
param keyUrl string

@description('Disk encryption strategy')
@allowed([
  'EncryptionAtRestWithCustomerKey'
  'DoubleEncryptionWithPlatformAndCustomerKeys'
])
param encryptionType string = 'DoubleEncryptionWithPlatformAndCustomerKeys'

@description('Whether to automatically track and rotate to the latest version of the customer-managed key')
param rotationToLatestKeyVersionEnabled bool = true

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2023-04-02' = {
  name: diskEncryptionSetName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'HostStorageEncryption'
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    encryptionType: encryptionType
    rotationToLatestKeyVersionEnabled: rotationToLatestKeyVersionEnabled
    activeKey: {
      sourceVault: {
        id: keyVaultId
      }
      keyUrl: keyUrl
    }
  }
}

@description('Resource ID of the Disk Encryption Set')
output id string = diskEncryptionSet.id

@description('Name of the Disk Encryption Set')
output name string = diskEncryptionSet.name

@description('Principal ID of the system-assigned managed identity used to grant Key Vault access')
output principalId string = diskEncryptionSet.identity.principalId
