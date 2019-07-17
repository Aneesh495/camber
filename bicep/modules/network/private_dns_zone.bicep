metadata description = 'Camber Private DNS Zone module with automated multi-VNet resolution links'

@description('FQDN of the Private DNS Zone, such as privatelink.vaultcore.azure.net')
param zoneName string

@description('Resource tags applied to the Private DNS Zone')
param tags object = {}

@description('Virtual Network links to associate with this Private DNS Zone')
param virtualNetworkLinks array = []

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'PrivateNameResolution'
  })
}

resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (link, i) in virtualNetworkLinks: {
  parent: privateDnsZone
  name: link.?name ?? 'link-${i}'
  location: 'global'
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'DnsVnetLink'
  })
  properties: {
    virtualNetwork: {
      id: link.virtualNetworkId
    }
    registrationEnabled: link.?registrationEnabled ?? false
  }
}]

@description('Resource ID of the Private DNS Zone')
output id string = privateDnsZone.id

@description('Name of the Private DNS Zone')
output name string = privateDnsZone.name
