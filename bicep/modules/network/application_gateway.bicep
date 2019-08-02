metadata description = 'Camber Application Gateway v2 with OWASP CRS v3 WAF policy and mutual TLS'

@description('Name of the Application Gateway')
param appGatewayName string

@description('Azure region for the Application Gateway')
param location string = resourceGroup().location

@description('Resource tags applied to the Application Gateway')
param tags object = {}

@description('Resource ID of the dedicated ApplicationGatewaySubnet')
param subnetId string

@description('Autoscale minimum capacity instances')
@minValue(2)
@maxValue(125)
param minCapacity int = 2

@description('Autoscale maximum capacity instances')
@minValue(3)
@maxValue(125)
param maxCapacity int = 10

@description('Backend server pool IP addresses or FQDNs')
param backendAddressPools array = [
  {
    name: 'default-backend-pool'
    backendAddresses: []
  }
]

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${appGatewayName}-pip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'IngressPublicIP'
  })
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource wafPolicy 'Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies@2023-09-01' = {
  name: '${appGatewayName}-waf'
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'IngressWafPolicy'
  })
  properties: {
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: appGatewayName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'IngressProxy'
  })
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    autoscaleConfiguration: {
      minCapacity: minCapacity
      maxCapacity: maxCapacity
    }
    firewallPolicy: {
      id: wafPolicy.id
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [for pool in backendAddressPools: {
      name: pool.name
      properties: {
        backendAddresses: pool.backendAddresses
      }
    }]
    backendHttpSettingsCollection: [
      {
        name: 'defaultBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpsListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'defaultRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'httpsListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, backendAddressPools[0].name)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'defaultBackendHttpSettings')
          }
        }
      }
    ]
  }
}

@description('Resource ID of the Application Gateway')
output id string = appGateway.id

@description('Name of the Application Gateway')
output name string = appGateway.name

@description('Public IP address assigned to the Application Gateway frontend')
output publicIpAddress string = publicIp.properties.ipAddress
