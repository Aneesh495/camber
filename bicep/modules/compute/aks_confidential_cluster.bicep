metadata description = 'Camber Confidential Azure Kubernetes Service (AKS) cluster with Cilium eBPF CNI and Azure Linux enclaves'

@description('Name of the AKS cluster')
param clusterName string

@description('Azure region for the AKS cluster')
param location string = resourceGroup().location

@description('Resource tags applied to the AKS cluster')
param tags object = {}

@description('Kubernetes orchestrator version')
param kubernetesVersion string = '1.30.3'

@description('Resource ID of the dedicated Kubernetes subnet')
param subnetId string

@description('VM SKU size for the system agent pool')
param systemPoolVmSize string = 'Standard_D4ds_v5'

@description('Confidential VM SKU size for AMD SEV-SNP enclave worker pool')
param confidentialWorkerVmSize string = 'Standard_DC4as_v5'

@description('Minimum node count for the confidential worker pool autoscaler')
@minValue(1)
@maxValue(100)
param minWorkerCount int = 3

@description('Maximum node count for the confidential worker pool autoscaler')
@minValue(3)
@maxValue(100)
param maxWorkerCount int = 20

@description('Optional Resource ID of the Disk Encryption Set for host disk encryption')
param diskEncryptionSetId string = ''

@description('Optional Resource ID of the Private DNS Zone for private API server resolution')
param privateDnsZoneId string = ''

@description('Optional Log Analytics Workspace ID for monitoring telemetry')
param logAnalyticsWorkspaceId string = ''

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: clusterName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'ConfidentialKubernetes'
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: '${clusterName}-dns'
    diskEncryptionSetID: !empty(diskEncryptionSetId) ? diskEncryptionSetId : null
    kubernetesVersion: kubernetesVersion
    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: !empty(privateDnsZoneId) ? privateDnsZoneId : 'system'
    }
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      networkPolicy: 'cilium'
      networkDataplane: 'cilium'
      outboundType: 'userDefinedRouting'
      serviceCidr: '10.241.0.0/16'
      dnsServiceIP: '10.241.0.10'
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
      defender: !empty(logAnalyticsWorkspaceId) ? {
        logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceId
        securityMonitoring: {
          enabled: true
        }
      } : null
    }
    oidcIssuerProfile: {
      enabled: true
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
      omsagent: !empty(logAnalyticsWorkspaceId) ? {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      } : {
        enabled: false
      }
    }
    agentPoolProfiles: [
      {
        name: 'systempool'
        mode: 'System'
        count: 3
        minCount: 3
        maxCount: 5
        vmSize: systemPoolVmSize
        osType: 'Linux'
        osSKU: 'AzureLinux'
        vnetSubnetID: subnetId
        enableAutoScaling: true
        enableNodePublicIP: false
        osDiskType: 'Ephemeral'
        osDiskSizeGB: 64
        enableEncryptionAtHost: true
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
      }
      {
        name: 'confidential'
        mode: 'User'
        count: minWorkerCount
        minCount: minWorkerCount
        maxCount: maxWorkerCount
        vmSize: confidentialWorkerVmSize
        osType: 'Linux'
        osSKU: 'AzureLinux'
        vnetSubnetID: subnetId
        enableAutoScaling: true
        enableNodePublicIP: false
        osDiskType: 'Managed'
        osDiskSizeGB: 128
        enableEncryptionAtHost: true
        nodeLabels: {
          'camber.io/enclave': 'amd-sev-snp'
          'camber.io/isolation': 'confidential'
        }
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
      }
    ]
  }
}

@description('Resource ID of the AKS cluster')
output id string = aksCluster.id

@description('Name of the AKS cluster')
output name string = aksCluster.name

@description('OIDC Issuer URL for Kubernetes workload identity federation')
output oidcIssuerUrl string = aksCluster.properties.oidcIssuerProfile.issuerURL

@description('Principal ID of the AKS cluster identity')
output principalId string = aksCluster.identity.principalId

@description('Object ID of the Kubelet managed identity')
output kubeletIdentityObjectId string = aksCluster.properties.identityProfile.kubeletidentity.objectId
