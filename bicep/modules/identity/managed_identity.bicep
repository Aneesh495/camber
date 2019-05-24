metadata description = 'Camber User-Assigned Managed Identity with federated identity credentials'

@description('Name of the user-assigned managed identity')
@minLength(3)
@maxLength(128)
param identityName string

@description('Azure region for the identity resource')
param location string = resourceGroup().location

@description('Resource tags applied to the identity')
param tags object = {}

@description('Federated identity credential specifications for workload identity')
param federatedCredentials array = []

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'Identity'
  })
}

resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = [for cred in federatedCredentials: {
  parent: managedIdentity
  name: cred.name
  properties: {
    issuer: cred.issuer
    subject: cred.subject
    audiences: cred.?audiences ?? [
      'api://AzureADTokenExchange'
    ]
  }
}]

@description('Resource ID of the created user-assigned managed identity')
output id string = managedIdentity.id

@description('Name of the created user-assigned managed identity')
output name string = managedIdentity.name

@description('Principal ID of the created user-assigned managed identity')
output principalId string = managedIdentity.properties.principalId

@description('Client ID of the created user-assigned managed identity')
output clientId string = managedIdentity.properties.clientId

@description('Tenant ID of the created user-assigned managed identity')
output tenantId string = managedIdentity.properties.tenantId
