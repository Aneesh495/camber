metadata description = 'Camber Sovereign Confidential Enclave end-to-end blueprint'

@description('Deployment environment identifier')
@allowed([
  'dev'
  'staging'
  'prod'
  'enclave'
])
param environment string = 'prod'

@description('Base workload name')
param workloadName string = 'camber'

@description('Primary Azure region for the sovereign enclave')
param location string = resourceGroup().location

@description('Administrator username for confidential nodes')
param adminUsername string = 'camberadmin'

@description('Administrator database password')
@secure()
param databasePassword string

@description('Array of Microsoft Entra object IDs designating initial HSM administrators')
param hsmAdminObjectIds array = [
  '00000000-0000-0000-0000-000000000000'
]

var uniqueSuffix = take(uniqueString(resourceGroup().id, workloadName), 6)
var vnetName = '${workloadName}-${environment}-vnet'
var nsgName = '${workloadName}-${environment}-nsg'
var routeTableName = '${workloadName}-${environment}-rt'
var kvName = '${take(workloadName, 12)}${uniqueSuffix}kv'
var hsmName = '${take(workloadName, 12)}${uniqueSuffix}hsm'
var storageName = '${take(workloadName, 12)}${uniqueSuffix}sa'
var logAnalyticsName = '${workloadName}-${environment}-law'
var aksClusterName = '${workloadName}-${environment}-aks'
var postgresName = '${workloadName}-${environment}-pg'

// 1. Centralized Telemetry and Log Analytics
module telemetryWorkspace '../modules/telemetry/log_analytics.bicep' = {
  name: 'deploy-log-analytics'
  params: {
    workspaceName: logAnalyticsName
    location: location
    retentionInDays: 365
    sku: 'PerGB2018'
  }
}

// 2. Data Collection Rule for Host OS Telemetry
module dcrRule '../modules/telemetry/data_collection_rule.bicep' = {
  name: 'deploy-dcr'
  params: {
    ruleName: '${workloadName}-${environment}-dcr'
    location: location
    workspaceResourceId: telemetryWorkspace.outputs.id
  }
}

// 3. User-Assigned Managed Identity for Fabric Orchestration
module fabricIdentity '../modules/identity/managed_identity.bicep' = {
  name: 'deploy-fabric-identity'
  params: {
    identityName: '${workloadName}-${environment}-fabric-id'
    location: location
    federatedCredentials: [
      {
        name: 'k8s-workload-identity'
        issuer: 'https://${location}.oic.prod-aks.azure.com/${uniqueSuffix}'
        subject: 'system:serviceaccount:camber-system:enclave-controller'
      }
    ]
  }
}

// 4. Microsegmentation Network Security Group
module networkSecurity '../modules/network/network_security_group.bicep' = {
  name: 'deploy-nsg'
  params: {
    nsgName: nsgName
    location: location
    securityRules: [
      {
        name: 'AllowVNetInbound'
        protocol: '*'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'VirtualNetwork'
        access: 'Allow'
        priority: 100
        direction: 'Inbound'
      }
      {
        name: 'DenyAllInbound'
        protocol: '*'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Deny'
        priority: 4096
        direction: 'Inbound'
      }
    ]
  }
}

// 5. Force-Tunneling User-Defined Route Table
module routeTable '../modules/network/route_table.bicep' = {
  name: 'deploy-route-table'
  params: {
    routeTableName: routeTableName
    location: location
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'DefaultToVirtualAppliance'
        addressPrefix: '0.0.0.0/0'
        nextHopType: 'VirtualAppliance'
        nextHopIpAddress: '10.240.0.4'
      }
    ]
  }
}

// 6. Zero-Trust Virtual Network with Segmented Subnets
module virtualNetwork '../modules/network/virtual_network.bicep' = {
  name: 'deploy-vnet'
  params: {
    vnetName: vnetName
    location: location
    addressPrefixes: [
      '10.240.0.0/16'
    ]
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.240.0.0/26'
      }
      {
        name: 'AksClusterSubnet'
        addressPrefix: '10.240.1.0/24'
        networkSecurityGroupId: networkSecurity.outputs.id
        routeTableId: routeTable.outputs.id
        privateEndpointNetworkPolicies: 'Disabled'
      }
      {
        name: 'DatabaseSubnet'
        addressPrefix: '10.240.2.0/24'
        networkSecurityGroupId: networkSecurity.outputs.id
        routeTableId: routeTable.outputs.id
        delegationServiceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
      }
      {
        name: 'PrivateEndpointSubnet'
        addressPrefix: '10.240.3.0/24'
        networkSecurityGroupId: networkSecurity.outputs.id
        routeTableId: routeTable.outputs.id
        privateEndpointNetworkPolicies: 'Disabled'
      }
    ]
  }
}

// 7. Cryptographic Key Vault with Purge Protection
module keyVault '../modules/security/key_vault.bicep' = {
  name: 'deploy-key-vault'
  params: {
    keyVaultName: kvName
    location: location
    skuTier: 'premium'
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Disabled'
    initialKeys: [
      {
        name: 'enclave-disk-cmek'
        kty: 'RSA'
        keySize: 4096
      }
    ]
  }
}

// 8. Dedicated FIPS 140-2 Level 3 Managed HSM
module managedHsm '../modules/security/managed_hsm.bicep' = {
  name: 'deploy-managed-hsm'
  params: {
    hsmName: hsmName
    location: location
    skuName: 'Standard_B1'
    initialAdminObjectIds: hsmAdminObjectIds
    publicNetworkAccess: 'Disabled'
  }
}

// 9. Microsoft Azure Attestation Provider for AMD SEV-SNP enclaves
module attestation '../modules/security/attestation_provider.bicep' = {
  name: 'deploy-attestation'
  params: {
    providerName: '${take(workloadName, 12)}${uniqueSuffix}att'
    location: location
    publicNetworkAccess: 'Disabled'
  }
}

// 10. Disk Encryption Set with Customer-Managed Keys
module diskEncryptionSet '../modules/security/disk_encryption_set.bicep' = {
  name: 'deploy-disk-encryption'
  params: {
    diskEncryptionSetName: '${workloadName}-${environment}-des'
    location: location
    keyVaultId: keyVault.outputs.id
    keyUrl: '${keyVault.outputs.vaultUri}keys/enclave-disk-cmek'
    encryptionType: 'DoubleEncryptionWithPlatformAndCustomerKeys'
  }
}

// 11. Confidential AKS Cluster with Cilium eBPF and Azure Linux
module aksCluster '../modules/compute/aks_confidential_cluster.bicep' = {
  name: 'deploy-aks-confidential'
  params: {
    clusterName: aksClusterName
    location: location
    subnetId: virtualNetwork.outputs.subnets.AksClusterSubnet
    kubernetesVersion: '1.30.3'
    systemPoolVmSize: 'Standard_D4ds_v5'
    confidentialWorkerVmSize: 'Standard_DC4as_v5'
    minWorkerCount: 3
    maxWorkerCount: 15
    diskEncryptionSetId: diskEncryptionSet.outputs.id
    logAnalyticsWorkspaceId: telemetryWorkspace.outputs.id
  }
}

// 12. PostgreSQL Flexible Server with Zone Redundancy
module postgresServer '../modules/data/postgresql_flexible.bicep' = {
  name: 'deploy-postgres-flexible'
  params: {
    serverName: postgresName
    location: location
    delegatedSubnetId: virtualNetwork.outputs.subnets.DatabaseSubnet
    privateDnsZoneId: resourceId('Microsoft.Network/privateDnsZones', 'privatelink.postgres.database.azure.com')
    skuName: 'Standard_D4ds_v5'
    tier: 'GeneralPurpose'
    storageSizeGB: 128
    administratorLogin: adminUsername
    administratorLoginPassword: databasePassword
    primaryZone: '1'
    standbyZone: '2'
  }
}

// 13. Hardened ADLS Gen2 Storage Account
module storageAccount '../modules/data/storage_account.bicep' = {
  name: 'deploy-storage-account'
  params: {
    storageAccountName: storageName
    location: location
    skuName: 'Standard_ZRS'
    enableHierarchicalNamespace: true
    allowedSubnetIds: [
      virtualNetwork.outputs.subnets.AksClusterSubnet
    ]
  }
}

@description('Resource ID of the Sovereign Enclave VNet')
output vnetId string = virtualNetwork.outputs.id

@description('Resource ID of the Confidential AKS Cluster')
output aksClusterId string = aksCluster.outputs.id

@description('OIDC Issuer URL of the AKS Cluster')
output oidcIssuerUrl string = aksCluster.outputs.oidcIssuerUrl

@description('Resource ID of the Dedicated Managed HSM')
output managedHsmId string = managedHsm.outputs.id

@description('Resource ID of the Attestation Provider')
output attestationProviderId string = attestation.outputs.id

@description('Resource ID of the PostgreSQL Flexible Server')
output postgresServerId string = postgresServer.outputs.id
