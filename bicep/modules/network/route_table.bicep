metadata description = 'Camber force-tunneling User-Defined Route (UDR) table with BGP propagation controls'

@description('Name of the Route Table')
param routeTableName string

@description('Azure region for the Route Table')
param location string = resourceGroup().location

@description('Resource tags applied to the Route Table')
param tags object = {}

@description('Whether to disable BGP route propagation from gateways')
param disableBgpRoutePropagation bool = false

@description('User-defined routes for traffic steering and firewall inspection')
param routes array = []

resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: routeTableName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'TrafficSteering'
  })
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: [for route in routes: {
      name: route.name
      properties: {
        addressPrefix: route.addressPrefix
        nextHopType: route.nextHopType
        nextHopIpAddress: contains(route, 'nextHopIpAddress') && !empty(route.nextHopIpAddress) ? route.nextHopIpAddress : null
      }
    }]
  }
}

@description('Resource ID of the Route Table')
output id string = routeTable.id

@description('Name of the Route Table')
output name string = routeTable.name
