metadata description = 'Camber dedicated FIPS 140-2 Level 3 Managed HSM cryptographic module'

@description('Name of the Managed HSM pool')
@minLength(3)
@maxLength(24)
param hsmName string

@description('Azure region for the Managed HSM')
param location string = resourceGroup().location

@description('Resource tags applied to the Managed HSM')
param tags object = {}

@description('Managed HSM SKU tier name')
@allowed([
  'Standard_B1'
  'Custom_B32'
])
param skuName string = 'Standard_B1'

@description('Retention period in days for soft deleted Managed HSM pool')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Array of Microsoft Entra object IDs designating initial HSM security domain administrators')
param initialAdminObjectIds array

@description('Public network access setting for Managed HSM')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

resource managedHsm 'Microsoft.KeyVault/managedHSMs@2023-07-01' = {
  name: hsmName
  location: location
  sku: {
    family: 'B'
    name: skuName
  }
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'HardwareSecurityModule'
  })
  properties: {
    tenantId: subscription().tenantId
    initialAdminObjectIds: initialAdminObjectIds
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

@description('Resource ID of the Managed HSM instance')
output id string = managedHsm.id

@description('Name of the Managed HSM instance')
output name string = managedHsm.name

@description('Data plane URI endpoint of the Managed HSM')
output hsmUri string = managedHsm.properties.hsmUri
