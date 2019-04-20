metadata description = 'Camber zero-trust network infrastructure and security contracts'

@description('Direction of network security rule')
@export()
type ruleDirection = 'Inbound' | 'Outbound'

@description('Access evaluation for network security rule')
@export()
type ruleAccess = 'Allow' | 'Deny'

@description('Transport protocol for network security rule')
@export()
type transportProtocol = 'Tcp' | 'Udp' | 'Icmp' | 'Ah' | 'Esp' | '*'

@description('Next hop routing appliance type')
@export()
type nextHopApplianceType = 'VirtualAppliance' | 'VnetLocal' | 'Internet' | 'VirtualNetworkGateway' | 'None'

@description('Detailed network security rule configuration contract')
@export()
type securityRuleConfig = {
  name: string
  description: string
  protocol: transportProtocol
  sourcePortRange: string
  destinationPortRange: string
  sourceAddressPrefix: string
  destinationAddressPrefix: string
  access: ruleAccess
  priority: int
  direction: ruleDirection
}

@description('Subnet route table association contract')
@export()
type routeConfig = {
  name: string
  addressPrefix: string
  nextHopType: nextHopApplianceType
  nextHopIpAddress: string?
}

@description('Subnet delegation configuration contract')
@export()
type subnetDelegation = {
  name: string
  serviceName: string
}

@description('Subnet definition with security and route associations')
@export()
type subnetConfig = {
  name: string
  addressPrefix: string
  networkSecurityGroupId: string?
  routeTableId: string?
  natGatewayId: string?
  delegations: subnetDelegation[]?
  privateEndpointNetworkPolicies: 'Enabled' | 'Disabled'?
  privateLinkServiceNetworkPolicies: 'Enabled' | 'Disabled'?
}

@description('Virtual network topology configuration')
@export()
type virtualNetworkConfig = {
  name: string
  addressPrefixes: string[]
  dnsServers: string[]?
  enableDdosProtection: bool
  ddosProtectionPlanId: string?
  subnets: subnetConfig[]
}

@description('Azure Firewall application rule protocol definition')
@export()
type firewallAppProtocol = {
  protocolType: 'Http' | 'Https' | 'Mssql'
  port: int
}

@description('Azure Firewall application rule specification')
@export()
type firewallApplicationRule = {
  name: string
  description: string?
  sourceAddresses: string[]
  protocols: firewallAppProtocol[]
  targetFqdns: string[]
}

@description('Azure Firewall network rule specification')
@export()
type firewallNetworkRule = {
  name: string
  description: string?
  protocols: transportProtocol[]
  sourceAddresses: string[]
  destinationAddresses: string[]
  destinationPorts: string[]
}

@description('Private endpoint connection configuration')
@export()
type privateEndpointConfig = {
  name: string
  subnetId: string
  privateLinkServiceId: string
  groupIds: string[]
  privateDnsZoneId: string?
}

@description('Application Gateway backend pool member')
@export()
type backendPoolMember = {
  ipAddress: string?
  fqdn: string?
}

@description('Application Gateway probe definition')
@export()
type healthProbeConfig = {
  name: string
  protocol: 'Http' | 'Https'
  path: string
  host: string?
  intervalSeconds: int
  timeoutSeconds: int
  unhealthyThreshold: int
  pickHostNameFromBackendHttpSettings: bool
}
