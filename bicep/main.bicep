metadata description = 'Camber Planetary Multi-Region Sovereign Confidential Infrastructure Orchestrator'

@description('Deployment environment tier')
@allowed([
  'dev'
  'staging'
  'prod'
  'enclave'
])
param environment string = 'prod'

@description('Base organization or workload identifier')
param workloadName string = 'camber'

@description('Primary continental region (Americas)')
param primaryLocation string = 'eastus'

@description('Secondary continental region (Europe)')
param secondaryLocation string = 'westeurope'

@description('Confidential node Linux administrator username')
param adminUsername string = 'camberadmin'

@description('Administrator database password')
@secure()
param databasePassword string

@description('Administrator SSH public key')
@secure()
param sshPublicKey string

@description('Entra security domain administrator object IDs for HSM')
param hsmAdminObjectIds array = [
  '00000000-0000-0000-0000-000000000000'
]

// 1. Planetary Multi-Region Transit Mesh
module planetaryTransit 'blueprints/planetary_transit.bicep' = {
  name: 'deploy-transit-mesh'
  params: {
    environment: environment
    workloadName: '${workloadName}-net'
    primaryLocation: primaryLocation
    secondaryLocation: secondaryLocation
    tertiaryLocation: 'southeastasia'
  }
}

// 2. Primary Sovereign Enclave Stack
module primarySovereignEnclave 'blueprints/sovereign_enclave.bicep' = {
  name: 'deploy-primary-enclave'
  params: {
    environment: environment
    workloadName: '${workloadName}-east'
    location: primaryLocation
    adminUsername: adminUsername
    databasePassword: databasePassword
    hsmAdminObjectIds: hsmAdminObjectIds
  }
}

// 3. Secondary Confidential AI Inference Stack
module secondaryInferenceStack 'blueprints/confidential_inference.bicep' = {
  name: 'deploy-secondary-inference'
  params: {
    environment: environment
    workloadName: '${workloadName}-west'
    location: secondaryLocation
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    inferenceNodeCount: 4
  }
}

// 4. Edge Sovereign Microzone Stack
module edgeMicrozone 'blueprints/edge_microzone.bicep' = {
  name: 'deploy-edge-microzone'
  params: {
    environment: 'edge'
    workloadName: '${workloadName}-edge'
    location: primaryLocation
  }
}

@description('Planetary Virtual WAN Resource ID')
output planetaryVirtualWanId string = planetaryTransit.outputs.vwanId

@description('Global Multi-Region Cosmos DB Document Endpoint')
output globalCosmosEndpoint string = planetaryTransit.outputs.cosmosEndpoint

@description('Primary Sovereign Enclave VNet ID')
output primaryVnetId string = primarySovereignEnclave.outputs.vnetId

@description('Primary Confidential AKS Cluster ID')
output primaryAksClusterId string = primarySovereignEnclave.outputs.aksClusterId

@description('Primary Dedicated Managed HSM ID')
output primaryManagedHsmId string = primarySovereignEnclave.outputs.managedHsmId

@description('Secondary Inference VNet ID')
output secondaryVnetId string = secondaryInferenceStack.outputs.vnetId

@description('Secondary Confidential VMSS ID')
output secondaryVmssId string = secondaryInferenceStack.outputs.vmssId

@description('Edge Microzone VNet ID')
output edgeVnetId string = edgeMicrozone.outputs.vnetId
