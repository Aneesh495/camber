metadata description = 'Camber multi-region active-active Cosmos DB account with analytical store and CMEK'

@description('Name of the Cosmos DB account')
param accountName string

@description('Primary Azure region for the Cosmos DB account')
param location string = resourceGroup().location

@description('Resource tags applied to the Cosmos DB account')
param tags object = {}

@description('Default consistency policy')
@allowed([
  'Eventual'
  'Session'
  'BoundedStaleness'
  'Strong'
  'ConsistentPrefix'
])
param defaultConsistencyLevel string = 'BoundedStaleness'

@description('Maximum staleness prefix for BoundedStaleness')
param maxStalenessPrefix int = 100000

@description('Maximum interval in seconds for BoundedStaleness')
param maxIntervalInSeconds int = 300

@description('Array of multi-region replication and failover locations')
param locations array = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: true
  }
]

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Optional Key Vault Key URI for customer-managed encryption')
param keyVaultKeyUri string = ''

@description('Default SQL Database name to provision')
param databaseName string = 'camber-state'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: accountName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'DistributedNoSQL'
  })
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: true
    enableMultipleWriteLocations: true
    publicNetworkAccess: publicNetworkAccess
    keyVaultKeyUri: !empty(keyVaultKeyUri) ? keyVaultKeyUri : null
    enableAnalyticalStorage: true
    consistencyPolicy: {
      defaultConsistencyLevel: defaultConsistencyLevel
      maxStalenessPrefix: defaultConsistencyLevel == 'BoundedStaleness' ? maxStalenessPrefix : null
      maxIntervalInSeconds: defaultConsistencyLevel == 'BoundedStaleness' ? maxIntervalInSeconds : null
    }
    locations: [for loc in locations: {
      locationName: loc.locationName
      failoverPriority: loc.failoverPriority
      isZoneRedundant: loc.isZoneRedundant
    }]
  }
}

resource sqlDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      autoscaleSettings: {
        maxThroughput: 4000
      }
    }
  }
}

@description('Resource ID of the Cosmos DB account')
output id string = cosmosAccount.id

@description('Name of the Cosmos DB account')
output name string = cosmosAccount.name

@description('Data plane document endpoint URI')
output documentEndpoint string = cosmosAccount.properties.documentEndpoint
