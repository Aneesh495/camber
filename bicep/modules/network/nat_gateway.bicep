metadata description = 'Camber outbound NAT Gateway with static public IP prefix allocation'

@description('Name of the NAT Gateway')
param natGatewayName string

@description('Azure region for the NAT Gateway')
param location string = resourceGroup().location

@description('Resource tags applied to the NAT Gateway')
param tags object = {}

@description('TCP idle timeout in minutes')
@minValue(4)
@maxValue(120)
param idleTimeoutInMinutes int = 15

@description('Zones for high availability')
param zones array = [
  '1'
  '2'
  '3'
]

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${natGatewayName}-pip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: zones
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'EgressSNAT'
  })
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource natGateway 'Microsoft.Network/natGateways@2023-09-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: zones
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'EgressGateway'
  })
  properties: {
    idleTimeoutInMinutes: idleTimeoutInMinutes
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
  }
}

@description('Resource ID of the NAT Gateway')
output id string = natGateway.id

@description('Name of the NAT Gateway')
output name string = natGateway.name

@description('Resource ID of the allocated public IP')
output publicIpId string = publicIp.id

@description('Allocated outbound static public IP address')
output publicIpAddress string = publicIp.properties.ipAddress
