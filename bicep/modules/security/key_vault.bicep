metadata description = 'Camber zero-trust Key Vault with purge protection, RBAC authorization, and private network isolation'

@description('Name of the Key Vault instance')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Azure region for the Key Vault')
param location string = resourceGroup().location

@description('Resource tags applied to the Key Vault')
param tags object = {}

@description('Key Vault SKU pricing and capability tier')
@allowed([
  'standard'
  'premium'
])
param skuTier string = 'premium'

@description('Retention period in days for soft deleted vaults and vault objects')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Subnet resource IDs permitted by network ACLs')
param allowedSubnetIds array = []

@description('IPv4 CIDR blocks permitted by network ACLs')
param allowedIpRules array = []

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Initial cryptographic keys to provision with automated rotation policies')
param initialKeys array = []

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'CryptographicSecurity'
  })
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: skuTier
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: true
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [for ip in allowedIpRules: {
        value: ip
      }]
      virtualNetworkRules: [for subnet in allowedSubnetIds: {
        id: subnet
        ignoreMissingVnetServiceEndpoint: false
      }]
    }
  }
}

resource cryptographicKeys 'Microsoft.KeyVault/vaults/keys@2023-07-01' = [for key in initialKeys: {
  parent: keyVault
  name: key.name
  properties: {
    kty: key.?kty ?? 'RSA'
    keySize: key.?keySize ?? 4096
    curveName: key.?curveName ?? null
    keyOps: key.?keyOps ?? [
      'encrypt'
      'decrypt'
      'wrapKey'
      'unwrapKey'
    ]
    rotationPolicy: {
      lifetimeActions: [
        {
          trigger: {
            timeBeforeExpiry: 'P30D'
          }
          action: {
            type: 'rotate'
          }
        }
      ]
      attributes: {
        expiryTime: 'P1Y'
      }
    }
  }
}]

@description('Resource ID of the Key Vault')
output id string = keyVault.id

@description('Name of the Key Vault')
output name string = keyVault.name

@description('Data plane URI of the Key Vault')
output vaultUri string = keyVault.properties.vaultUri
