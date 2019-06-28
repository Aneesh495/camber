metadata description = 'Camber microsegmentation Network Security Group with default-deny security posture'

@description('Name of the Network Security Group')
param nsgName string

@description('Azure region for the Network Security Group')
param location string = resourceGroup().location

@description('Resource tags applied to the Network Security Group')
param tags object = {}

@description('Custom security rules to inject into the Network Security Group')
param securityRules array = []

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'Microsegmentation'
  })
  properties: {
    securityRules: [for rule in securityRules: {
      name: rule.name
      properties: {
        description: rule.?description ?? 'Camber microsegmentation rule ${rule.name}'
        protocol: rule.protocol
        sourcePortRange: rule.?sourcePortRange ?? '*'
        destinationPortRange: rule.?destinationPortRange ?? '*'
        sourcePortRanges: rule.?sourcePortRanges ?? []
        destinationPortRanges: rule.?destinationPortRanges ?? []
        sourceAddressPrefix: rule.?sourceAddressPrefix ?? '*'
        destinationAddressPrefix: rule.?destinationAddressPrefix ?? '*'
        sourceAddressPrefixes: rule.?sourceAddressPrefixes ?? []
        destinationAddressPrefixes: rule.?destinationAddressPrefixes ?? []
        access: rule.access
        priority: rule.priority
        direction: rule.direction
      }
    }]
  }
}

@description('Resource ID of the Network Security Group')
output id string = nsg.id

@description('Name of the Network Security Group')
output name string = nsg.name
