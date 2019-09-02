metadata description = 'Camber PostgreSQL Flexible Server with zone-redundant high availability, private DNS, and CMEK'

@description('Name of the PostgreSQL Flexible Server')
param serverName string

@description('Azure region for the server')
param location string = resourceGroup().location

@description('Resource tags applied to the server')
param tags object = {}

@description('Resource ID of the subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers')
param delegatedSubnetId string

@description('Resource ID of the Private DNS Zone (privatelink.postgres.database.azure.com)')
param privateDnsZoneId string

@description('PostgreSQL compute SKU name')
param skuName string = 'Standard_D4ds_v5'

@description('PostgreSQL compute tier')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param tier string = 'GeneralPurpose'

@description('Storage size in gigabytes')
@minValue(32)
@maxValue(16384)
param storageSizeGB int = 128

@description('Master database administrator login username')
param administratorLogin string = 'camberadmin'

@description('Master database administrator login password')
@secure()
param administratorLoginPassword string

@description('PostgreSQL engine major version')
@allowed([
  '15'
  '16'
])
param version string = '16'

@description('Availability zone for primary server')
param primaryZone string = '1'

@description('Standby availability zone for zone-redundant HA')
param standbyZone string = '2'

@description('Optional Key Vault Key URI for customer-managed encryption')
param keyVaultKeyId string = ''

@description('Optional User-Assigned Identity Resource ID for Key Vault access')
param userAssignedIdentityId string = ''

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: serverName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'RelationalDatabase'
  })
  sku: {
    name: skuName
    tier: tier
  }
  identity: !empty(userAssignedIdentityId) ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  } : null
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    availabilityZone: primaryZone
    highAvailability: {
      mode: 'ZoneRedundant'
      standbyAvailabilityZone: standbyZone
    }
    storage: {
      storageSizeGB: storageSizeGB
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 35
      geoRedundantBackup: 'Enabled'
    }
    network: {
      delegatedSubnetResourceId: delegatedSubnetId
      privateDnsZoneArmResourceId: privateDnsZoneId
    }
    dataEncryption: !empty(keyVaultKeyId) ? {
      type: 'AzureKeyVault'
      primaryKeyURI: keyVaultKeyId
      primaryUserAssignedIdentityId: userAssignedIdentityId
    } : null
  }
}

resource pgauditConfig 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2023-03-01-preview' = {
  parent: postgresServer
  name: 'shared_preload_libraries'
  properties: {
    value: 'pgaudit'
    source: 'user-override'
  }
}

@description('Resource ID of the PostgreSQL server')
output id string = postgresServer.id

@description('Name of the PostgreSQL server')
output name string = postgresServer.name

@description('Fully qualified domain name of the PostgreSQL server')
output fqdn string = postgresServer.properties.fullyQualifiedDomainName
