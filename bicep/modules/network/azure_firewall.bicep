metadata description = 'Camber Azure Firewall Premium with TLS inspection, IDPS, and structured rule collection groups'

@description('Name of the Azure Firewall')
param firewallName string

@description('Azure region for the Firewall')
param location string = resourceGroup().location

@description('Resource tags applied to the Firewall')
param tags object = {}

@description('Firewall operational tier')
@allowed([
  'Standard'
  'Premium'
])
param skuTier string = 'Premium'

@description('Resource ID of the dedicated AzureFirewallSubnet')
param subnetId string

@description('Application rule definitions for FQDN filtering')
param applicationRules array = []

@description('Network rule definitions for L4 packet filtering')
param networkRules array = []

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${firewallName}-pip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'PerimeterEgress'
  })
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: '${firewallName}-policy'
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'PerimeterSecurityPolicy'
  })
  properties: {
    sku: {
      tier: skuTier
    }
    threatIntelMode: 'Deny'
    intrusionDetection: skuTier == 'Premium' ? {
      mode: 'Deny'
    } : null
    dnsSettings: {
      enableProxy: true
    }
  }
}

resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  parent: firewallPolicy
  name: 'DefaultRuleCollectionGroup'
  properties: {
    priority: 1000
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'ApplicationRules'
        priority: 1100
        action: {
          type: 'Allow'
        }
        rules: [for (appRule, i) in applicationRules: {
          ruleType: 'ApplicationRule'
          name: appRule.name
          description: appRule.?description ?? 'Allow FQDN egress'
          sourceAddresses: appRule.sourceAddresses
          protocols: appRule.protocols
          targetFqdns: appRule.targetFqdns
        }]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'NetworkRules'
        priority: 1200
        action: {
          type: 'Allow'
        }
        rules: [for (netRule, j) in networkRules: {
          ruleType: 'NetworkRule'
          name: netRule.name
          description: netRule.?description ?? 'Allow network traffic'
          ipProtocols: netRule.protocols
          sourceAddresses: netRule.sourceAddresses
          destinationAddresses: netRule.destinationAddresses
          destinationPorts: netRule.destinationPorts
        }]
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: firewallName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'PerimeterInspection'
  })
  dependsOn: [
    ruleCollectionGroup
  ]
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: skuTier
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'AzureFirewallIpConfiguration'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

@description('Resource ID of the Azure Firewall')
output id string = firewall.id

@description('Name of the Azure Firewall')
output name string = firewall.name

@description('Private IP address of the Azure Firewall for routing')
output privateIpAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress

@description('Public IP address of the Azure Firewall')
output publicIpAddress string = publicIp.properties.ipAddress
