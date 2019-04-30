metadata description = 'Camber cryptographic key hierarchy, Managed HSM, and attestation contracts'

@description('Key Vault operational tier')
@export()
type keyVaultSkuTier = 'standard' | 'premium'

@description('Managed HSM SKU tier family')
@export()
type managedHsmSkuTier = 'Standard_B1' | 'Custom_B32'

@description('Cryptographic key algorithm specification')
@export()
type cryptographicKeyType = 'RSA' | 'RSA-HSM' | 'EC' | 'EC-HSM'

@description('Elliptic curve specification for EC keys')
@export()
type ellipticCurveName = 'P-256' | 'P-384' | 'P-521' | 'SECP256K1'

@description('Key rotation policy configuration contract')
@export()
type keyRotationPolicy = {
  lifetimeActions: {
    trigger: {
      timeAfterCreate: string?
      timeBeforeExpiry: string?
    }
    action: {
      type: 'Rotate' | 'Notify'
    }
  }[]
  expiryTime: string?
}

@description('Cryptographic key creation specification')
@export()
type keySpecification = {
  keyName: string
  kty: cryptographicKeyType
  keySize: int?
  curveName: ellipticCurveName?
  keyOps: string[]
  rotationPolicy: keyRotationPolicy?
}

@description('Microsoft Azure Attestation provider policy format')
@export()
type attestationPolicyFormat = 'JWT' | 'Text'

@description('Attestation policy configuration for enclaves')
@export()
type attestationPolicyConfig = {
  policyName: string
  format: attestationPolicyFormat
  policyContent: string
  enclaveType: 'SevSnpVm' | 'Sgx' | 'OpenEnclave'
}

@description('Disk encryption set configuration contract')
@export()
type diskEncryptionSetConfig = {
  name: string
  keyVaultKeyUrl: string
  encryptionType: 'EncryptionAtRestWithCustomerKey' | 'DoubleEncryptionWithPlatformAndCustomerKeys'
  rotationToLatestKeyVersionEnabled: bool
  keyVaultResourceId: string
}

@description('Granular RBAC role assignment contract')
@export()
type roleAssignmentConfig = {
  principalId: string
  roleDefinitionId: string
  principalType: 'ServicePrincipal' | 'User' | 'Group' | 'Device'
  condition: string?
  conditionVersion: '2.0'?
  description: string?
}

@description('Custom RBAC sovereign security role definition')
@export()
type customRoleDefinitionConfig = {
  roleName: string
  description: string
  actions: string[]
  notActions: string[]
  dataActions: string[]
  notDataActions: string[]
  assignableScopes: string[]
}
