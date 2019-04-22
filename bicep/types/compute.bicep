metadata description = 'Camber confidential compute, AKS enclave, and container contracts'

@description('Hardware confidential computing isolation architecture')
@export()
type confidentialSecurityType = 'ConfidentialVM' | 'TrustedLaunch'

@description('Confidential virtual machine isolation configuration')
@export()
type confidentialVmConfig = {
  securityType: confidentialSecurityType
  enableSecureBoot: bool
  enableVtpm: bool
  enableEncryptionAtHost: bool
  confidentialVmType: 'SEV_SNP' | 'TDX'?
}

@description('AKS node pool operating mode')
@export()
type agentPoolMode = 'System' | 'User'

@description('Operating system disk type for cluster nodes')
@export()
type osDiskStorageType = 'Managed' | 'Ephemeral'

@description('Confidential AKS agent pool configuration')
@export()
type aksAgentPoolConfig = {
  name: string
  count: int
  minCount: int
  maxCount: int
  vmSize: string
  osDiskSizeGB: int
  osDiskType: osDiskStorageType
  osType: 'Linux'
  osSKU: 'AzureLinux' | 'Ubuntu'
  vnetSubnetID: string
  enableAutoScaling: bool
  mode: agentPoolMode
  nodeTaints: string[]?
  nodeLabels: object?
  enableNodePublicIP: bool
  enableUltraSSD: bool
}

@description('Network plugin selection for cluster data plane')
@export()
type networkPluginType = 'azure' | 'none'

@description('Network policy engine enforcing microsegmentation')
@export()
type networkPolicyType = 'cilium' | 'calico' | 'azure'

@description('AKS confidential cluster orchestration specification')
@export()
type aksClusterConfig = {
  clusterName: string
  dnsPrefix: string
  kubernetesVersion: string
  networkPlugin: networkPluginType
  networkPolicy: networkPolicyType
  outboundType: 'userDefinedRouting' | 'loadBalancer'
  enablePrivateCluster: bool
  privateDnsZoneId: string?
  authorizedIpRanges: string[]?
  enableWorkloadIdentity: bool
  enableKeyVaultSecretsProvider: bool
  enableDefender: bool
}

@description('Container App Dapr sidecar configuration contract')
@export()
type daprConfiguration = {
  enabled: bool
  appId: string
  appPort: int
  appProtocol: 'http' | 'grpc'
  enableApiLogging: bool
}

@description('Container App microservice container specification')
@export()
type containerSpec = {
  name: string
  image: string
  cpu: string
  memory: string
  env: object[]?
}

@description('High performance batch pool allocation configuration')
@export()
type batchPoolConfig = {
  poolId: string
  vmSize: string
  targetDedicatedNodes: int
  targetLowPriorityNodes: int
  enableInterNodeCommunication: bool
  subnetId: string
}
