metadata description = 'Camber Confidential AI Inference Topology blueprint for AMD SEV-SNP enclaves'

@description('Deployment environment identifier')
param environment string = 'prod'

@description('Base workload name')
param workloadName string = 'camber-ai'

@description('Primary Azure region for inference cluster')
param location string = resourceGroup().location

@description('Administrator username for Linux instances')
param adminUsername string = 'camberadmin'

@description('Administrator SSH public key')
@secure()
param sshPublicKey string

@description('Inference VMSS worker node capacity')
@minValue(2)
@maxValue(50)
param inferenceNodeCount int = 4

var uniqueSuffix = take(uniqueString(resourceGroup().id, workloadName), 6)
var vnetName = '${workloadName}-${environment}-vnet'
var nsgName = '${workloadName}-${environment}-nsg'
var vmssName = '${workloadName}-cvm'
var storageName = '${take(replace(workloadName, '-', ''), 12)}${uniqueSuffix}mdl'
var eventHubName = '${workloadName}-${environment}-eventhub'
var envName = '${workloadName}-${environment}-cae'
var logAnalyticsName = '${workloadName}-${environment}-law'

// 1. Centralized Telemetry
module telemetryWorkspace '../modules/telemetry/log_analytics.bicep' = {
  name: 'deploy-inference-telemetry'
  params: {
    workspaceName: logAnalyticsName
    location: location
    retentionInDays: 180
  }
}

// 2. Microsegmentation NSG
module networkSecurity '../modules/network/network_security_group.bicep' = {
  name: 'deploy-inference-nsg'
  params: {
    nsgName: nsgName
    location: location
    securityRules: [
      {
        name: 'AllowInferenceMesh'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '8000-8080'
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'VirtualNetwork'
        access: 'Allow'
        priority: 200
        direction: 'Inbound'
      }
      {
        name: 'DenyExternal'
        protocol: '*'
        sourcePortRange: '*'
        destinationPortRange: '*'
        sourceAddressPrefix: 'Internet'
        destinationAddressPrefix: '*'
        access: 'Deny'
        priority: 4096
        direction: 'Inbound'
      }
    ]
  }
}

// 3. Virtual Network
module virtualNetwork '../modules/network/virtual_network.bicep' = {
  name: 'deploy-inference-vnet'
  params: {
    vnetName: vnetName
    location: location
    addressPrefixes: [
      '10.244.0.0/16'
    ]
    subnets: [
      {
        name: 'InferenceNodeSubnet'
        addressPrefix: '10.244.1.0/24'
        networkSecurityGroupId: networkSecurity.outputs.id
      }
      {
        name: 'ContainerAppSubnet'
        addressPrefix: '10.244.2.0/23'
        networkSecurityGroupId: networkSecurity.outputs.id
        delegationServiceName: 'Microsoft.App/environments'
      }
    ]
  }
}

// 4. Confidential VMSS with AMD SEV-SNP
module confidentialVmss '../modules/compute/confidential_vm_ss.bicep' = {
  name: 'deploy-confidential-vmss'
  params: {
    vmssName: vmssName
    location: location
    subnetId: virtualNetwork.outputs.subnets.InferenceNodeSubnet
    vmSku: 'Standard_DC4as_v5'
    instanceCount: inferenceNodeCount
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
  }
}

// 5. Container Apps Environment with Dapr Sidecars
module containerAppsEnvironment '../modules/compute/container_apps_env.bicep' = {
  name: 'deploy-inference-cae'
  params: {
    environmentName: envName
    location: location
    infrastructureSubnetId: virtualNetwork.outputs.subnets.ContainerAppSubnet
    logAnalyticsWorkspaceId: telemetryWorkspace.outputs.id
    internalOnly: true
  }
}

// 6. High-Throughput Event Hubs for Streaming Inference Logs
module eventHubs '../modules/data/event_hub_namespace.bicep' = {
  name: 'deploy-inference-eventhub'
  params: {
    namespaceName: eventHubName
    location: location
    skuTier: 'Premium'
    capacity: 2
    zoneRedundant: true
  }
}

// 7. Model Storage Account
module modelStorage '../modules/data/storage_account.bicep' = {
  name: 'deploy-model-storage'
  params: {
    storageAccountName: storageName
    location: location
    skuName: 'Standard_ZRS'
    enableHierarchicalNamespace: true
    containers: [
      {
        name: 'weights'
        publicAccess: 'None'
      }
      {
        name: 'embeddings'
        publicAccess: 'None'
      }
    ]
  }
}

@description('Resource ID of the inference VNet')
output vnetId string = virtualNetwork.outputs.id

@description('Resource ID of the confidential VMSS')
output vmssId string = confidentialVmss.outputs.id

@description('Resource ID of the Container Apps Environment')
output containerAppsEnvId string = containerAppsEnvironment.outputs.id

@description('Resource ID of the Event Hubs namespace')
output eventHubsId string = eventHubs.outputs.id
