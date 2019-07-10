metadata description = 'Camber planetary Azure Virtual WAN with secure multi-region virtual hubs'

@description('Name of the Azure Virtual WAN')
param vwanName string

@description('Azure region for the Virtual WAN resource')
param location string = resourceGroup().location

@description('Resource tags applied to the Virtual WAN and Virtual Hubs')
param tags object = {}

@description('Virtual WAN operational SKU tier')
@allowed([
  'Basic'
  'Standard'
])
param skuType string = 'Standard'

@description('Whether branch to branch traffic is allowed across hubs')
param allowBranchToBranchTraffic bool = true

@description('Configuration array for regional Virtual Hubs')
param virtualHubs array = []

resource vwan 'Microsoft.Network/virtualWans@2023-09-01' = {
  name: vwanName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'PlanetaryTransit'
  })
  properties: {
    type: skuType
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
    disableVpnEncryption: false
  }
}

resource hubs 'Microsoft.Network/virtualHubs@2023-09-01' = [for hub in virtualHubs: {
  name: hub.name
  location: hub.location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'TransitHub'
    Region: hub.location
  })
  properties: {
    virtualWan: {
      id: vwan.id
    }
    addressPrefix: hub.addressPrefix
    sku: hub.?sku ?? 'Standard'
  }
}]

@description('Resource ID of the Virtual WAN')
output id string = vwan.id

@description('Name of the Virtual WAN')
output name string = vwan.name

@description('Array of regional Virtual Hub resource IDs')
output hubIds array = [for i in range(0, length(virtualHubs)): hubs[i].id]
