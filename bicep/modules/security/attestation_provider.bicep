metadata description = 'Camber Microsoft Azure Attestation (MAA) confidential enclave attestation provider'

@description('Name of the Attestation Provider')
@minLength(3)
@maxLength(24)
param providerName string

@description('Azure region for the Attestation Provider')
param location string = resourceGroup().location

@description('Resource tags applied to the provider')
param tags object = {}

@description('Public network access setting for attestation endpoints')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('X.509 certificate public keys for signing attestation policies in isolated mode')
param policySigningCertificates array = []

resource attestationProvider 'Microsoft.Attestation/attestationProviders@2021-06-01' = {
  name: providerName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'HardwareAttestation'
  })
  properties: {
    publicNetworkAccess: publicNetworkAccess
    policySigningCertificates: empty(policySigningCertificates) ? null : {
      keys: policySigningCertificates
    }
  }
}

@description('Resource ID of the Attestation Provider')
output id string = attestationProvider.id

@description('Name of the Attestation Provider')
output name string = attestationProvider.name

@description('Attestation service endpoint URI')
output attestUri string = attestationProvider.properties.attestUri
