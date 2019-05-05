metadata description = 'Camber sovereign data plane, storage immutability, and database contracts'

@description('Storage account replication tier')
@export()
type storageRedundancyType = 'Standard_LRS' | 'Standard_GRS' | 'Standard_ZRS' | 'Standard_GZRS' | 'Premium_LRS' | 'Premium_ZRS'

@description('WORM immutability policy configuration for compliance storage')
@export()
type blobImmutabilityPolicy = {
  immutabilityPeriodSinceCreationInDays: int
  allowProtectedAppendWrites: bool
  state: 'Unlocked' | 'Locked'
}

@description('Storage lifecycle management rule specification')
@export()
type storageLifecycleRule = {
  name: string
  enabled: bool
  tierToCoolDays: int?
  tierToArchiveDays: int?
  deleteBlobDays: int?
  prefixMatch: string[]?
}

@description('Hierarchical namespace storage account specification')
@export()
type storageAccountSpecification = {
  name: string
  sku: storageRedundancyType
  enableHierarchicalNamespace: bool
  enableNfsV3: bool
  enableSftp: bool
  minimumTlsVersion: 'TLS1_2' | 'TLS1_3'
  allowBlobPublicAccess: bool
  networkAclsDefaultAction: 'Allow' | 'Deny'
  keyVaultKeyId: string?
  userAssignedIdentityId: string?
}

@description('Cosmos DB default consistency level')
@export()
type cosmosConsistencyLevel = 'Eventual' | 'Session' | 'BoundedStaleness' | 'Strong' | 'ConsistentPrefix'

@description('Cosmos DB multi-region failover and geo-replication specification')
@export()
type cosmosLocationConfig = {
  locationName: string
  failoverPriority: int
  isZoneRedundant: bool
}

@description('Cosmos DB multi-region account contract')
@export()
type cosmosDbSpecification = {
  accountName: string
  defaultConsistencyLevel: cosmosConsistencyLevel
  maxStalenessPrefix: int?
  maxIntervalInSeconds: int?
  enableMultipleWriteLocations: bool
  enableAutomaticFailover: bool
  locations: cosmosLocationConfig[]
  enableAnalyticalStore: bool
  keyVaultKeyUri: string?
  networkAclBypass: 'AzureServices' | 'None'
}

@description('PostgreSQL Flexible Server compute tier')
@export()
type postgresComputeTier = 'Burstable' | 'GeneralPurpose' | 'MemoryOptimized'

@description('PostgreSQL Flexible Server high availability mode')
@export()
type postgresHighAvailabilityMode = 'ZoneRedundant' | 'SameZone' | 'Disabled'

@description('PostgreSQL Flexible Server specification')
@export()
type postgresqlSpecification = {
  serverName: string
  version: '15' | '16'
  skuName: string
  tier: postgresComputeTier
  storageSizeGB: int
  highAvailabilityMode: postgresHighAvailabilityMode
  standbyAvailabilityZone: string?
  delegatedSubnetId: string
  privateDnsZoneId: string
  keyVaultKeyId: string?
  userAssignedIdentityId: string?
  backupRetentionDays: int
  geoRedundantBackup: 'Enabled' | 'Disabled'
}

@description('Event Hubs namespace tier')
@export()
type eventHubsSkuTier = 'Standard' | 'Premium'

@description('Event Hubs namespace specification')
@export()
type eventHubSpecification = {
  name: string
  skuTier: eventHubsSkuTier
  capacity: int
  zoneRedundant: bool
  maximumThroughputUnits: int?
  isAutoInflateEnabled: bool?
  keyVaultKeyId: string?
}

@description('Service Bus premium namespace specification')
@export()
type serviceBusSpecification = {
  name: string
  messagingUnits: int
  zoneRedundant: bool
  keyVaultKeyId: string?
}
