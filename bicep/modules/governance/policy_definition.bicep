targetScope = 'subscription'

metadata description = 'Camber custom Azure Policy definition for confidential computing and zero-trust controls'

@description('Unique technical name for the policy definition')
param policyName string

@description('Human readable display name for the policy')
param displayName string

@description('Detailed description of the policy invariant being enforced')
param policyDescription string

@description('Evaluation mode: Indexed for resources with tags/locations, All for all resource types')
@allowed([
  'Indexed'
  'All'
])
param mode string = 'Indexed'

@description('Policy metadata object containing category, version, and compliance framework references')
param metadata object = {
  category: 'Confidential Computing'
  version: '1.0.0'
  source: 'Camber Sovereign Mesh'
}

@description('Policy rule logic condition block')
param policyRule object

@description('Optional configurable parameters for the policy rule')
param parameters object = {}

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: policyName
  properties: {
    displayName: displayName
    description: policyDescription
    mode: mode
    metadata: metadata
    parameters: parameters
    policyRule: policyRule
  }
}

@description('Resource ID of the policy definition')
output id string = policyDefinition.id

@description('Name of the policy definition')
output name string = policyDefinition.name
