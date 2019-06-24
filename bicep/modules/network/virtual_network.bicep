metadata description = 'Camber zero-trust Virtual Network with dynamic subnet topology, delegations, and DDoS protection'

@description('Name of the Virtual Network')
param vnetName string

@description('Azure region for the Virtual Network')
param location string = resourceGroup().location

@description('Resource tags applied to the Virtual Network')
param tags object = {}

@description('CIDR address spaces for the virtual network')
param addressPrefixes array = [
  '10.240.0.0/16'
]

@description('DNS server IP addresses')
param dnsServers array = []

@description('Whether to associate an Azure DDoS Protection Plan')
param enableDdosProtection bool = false

@description('Resource ID of the DDoS protection plan if enabled')
param ddosProtectionPlanId string = ''

@description('Array of subnet configurations')
param subnets array = []

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'VirtualNetwork'
  })
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    dhcpOptions: empty(dnsServers) ? null : {
      dnsServers: dnsServers
    }
    enableDdosProtection: enableDdosProtection
    ddosProtectionPlan: enableDdosProtection && !empty(ddosProtectionPlanId) ? {
      id: ddosProtectionPlanId
    } : null
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: contains(subnet, 'networkSecurityGroupId') && !empty(subnet.networkSecurityGroupId) ? {
          id: subnet.networkSecurityGroupId
        } : null
        routeTable: contains(subnet, 'routeTableId') && !empty(subnet.routeTableId) ? {
          id: subnet.routeTableId
        } : null
        natGateway: contains(subnet, 'natGatewayId') && !empty(subnet.natGatewayId) ? {
          id: subnet.natGatewayId
        } : null
        privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Disabled'
        privateLinkServiceNetworkPolicies: subnet.?privateLinkServiceNetworkPolicies ?? 'Enabled'
        serviceEndpoints: subnet.?serviceEndpoints ?? []
        delegations: contains(subnet, 'delegationServiceName') && !empty(subnet.delegationServiceName) ? [
          {
            name: 'delegation-${subnet.name}'
            properties: {
              serviceName: subnet.delegationServiceName
            }
          }
        ] : []
      }
    }]
  }
}

@description('Resource ID of the Virtual Network')
output id string = vnet.id

@description('Name of the Virtual Network')
output name string = vnet.name

@description('Address prefixes allocated to the Virtual Network')
output addressPrefixes array = vnet.properties.addressSpace.addressPrefixes

@description('Dictionary mapping subnet names to their allocated subnet resource IDs')
output subnets object = toObject(vnet.properties.subnets, s => s.name, s => s.id)
