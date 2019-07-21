metadata description = 'Camber Private Endpoint module with automated Private DNS Zone Group registration'

@description('Name of the Private Endpoint')
param endpointName string

@description('Azure region for the Private Endpoint')
param location string = resourceGroup().location

@description('Resource tags applied to the Private Endpoint')
param tags object = {}

@description('Subnet resource ID where the Private Endpoint NIC will be attached')
param subnetId string

@description('Resource ID of the target Azure PaaS service')
param privateLinkServiceId string

@description('Target subresource group ID (e.g., vault, blob, postgresqlServer, coordinator)')
param groupIds array

@description('Optional Resource ID of the Private DNS Zone for automated record registration')
param privateDnsZoneId string = ''

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: endpointName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'PrivateLink'
  })
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${endpointName}-connection'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (!empty(privateDnsZoneId)) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatednsconfig'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

@description('Resource ID of the Private Endpoint')
output id string = privateEndpoint.id

@description('Name of the Private Endpoint')
output name string = privateEndpoint.name

@description('Resource ID of the allocated network interface')
output networkInterfaceId string = privateEndpoint.properties.networkInterfaces[0].id
