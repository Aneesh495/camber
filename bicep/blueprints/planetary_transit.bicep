metadata description = 'Camber Planetary Transit Mesh blueprint spanning East US, West Europe, and Southeast Asia'

@description('Deployment environment identifier')
param environment string = 'prod'

@description('Base workload name')
param workloadName string = 'camber-transit'

@description('Primary region for global resource orchestration')
param primaryLocation string = 'eastus'

@description('Secondary European region')
param secondaryLocation string = 'westeurope'

@description('Tertiary Asia-Pacific region')
param tertiaryLocation string = 'southeastasia'

var uniqueSuffix = take(uniqueString(resourceGroup().id, workloadName), 6)
var vwanName = '${workloadName}-${environment}-vwan'
var cosmosName = '${take(replace(workloadName, '-', ''), 14)}${uniqueSuffix}db'
var logAnalyticsName = '${workloadName}-${environment}-law'

// 1. Planetary Azure Virtual WAN with 3 Continental Hubs
module virtualWan '../modules/network/virtual_wan.bicep' = {
  name: 'deploy-planetary-vwan'
  params: {
    vwanName: vwanName
    location: primaryLocation
    skuType: 'Standard'
    allowBranchToBranchTraffic: true
    virtualHubs: [
      {
        name: '${workloadName}-hub-eastus'
        location: primaryLocation
        addressPrefix: '10.100.0.0/24'
      }
      {
        name: '${workloadName}-hub-westeurope'
        location: secondaryLocation
        addressPrefix: '10.101.0.0/24'
      }
      {
        name: '${workloadName}-hub-southeastasia'
        location: tertiaryLocation
        addressPrefix: '10.102.0.0/24'
      }
    ]
  }
}

// 2. Multi-Region Active-Active Cosmos DB Distributed Data Plane
module globalCosmos '../modules/data/cosmos_db.bicep' = {
  name: 'deploy-global-cosmos'
  params: {
    accountName: cosmosName
    location: primaryLocation
    defaultConsistencyLevel: 'Strong'
    publicNetworkAccess: 'Disabled'
    locations: [
      {
        locationName: primaryLocation
        failoverPriority: 0
        isZoneRedundant: true
      }
      {
        locationName: secondaryLocation
        failoverPriority: 1
        isZoneRedundant: true
      }
      {
        locationName: tertiaryLocation
        failoverPriority: 2
        isZoneRedundant: true
      }
    ]
  }
}

// 3. Centralized Planetary Telemetry Workspace
module telemetry '../modules/telemetry/log_analytics.bicep' = {
  name: 'deploy-planetary-telemetry'
  params: {
    workspaceName: logAnalyticsName
    location: primaryLocation
    retentionInDays: 730
    sku: 'CapacityReservation'
    dailyQuotaGb: 500
  }
}

// 4. Global Private DNS Zone for Key Vault Private Links
module privateDnsVault '../modules/network/private_dns_zone.bicep' = {
  name: 'deploy-dns-vault'
  params: {
    zoneName: 'privatelink.vaultcore.azure.net'
  }
}

// 5. Global Private DNS Zone for DocumentDB Private Links
module privateDnsCosmos '../modules/network/private_dns_zone.bicep' = {
  name: 'deploy-dns-cosmos'
  params: {
    zoneName: 'privatelink.documents.azure.com'
  }
}

@description('Resource ID of the Planetary Virtual WAN')
output vwanId string = virtualWan.outputs.id

@description('Resource IDs of the regional Virtual Hubs')
output hubIds array = virtualWan.outputs.hubIds

@description('Resource ID of the Multi-Region Cosmos DB Account')
output cosmosId string = globalCosmos.outputs.id

@description('Document endpoint of the Multi-Region Cosmos DB Account')
output cosmosEndpoint string = globalCosmos.outputs.documentEndpoint

@description('Resource ID of the Planetary Telemetry Workspace')
output logAnalyticsId string = telemetry.outputs.id
