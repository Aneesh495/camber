targetScope = 'subscription'

metadata description = 'Camber Azure Policy initiative set grouping sovereign confidential computing and CIS baselines'

@description('Unique technical name for the policy initiative')
param policySetName string

@description('Human readable display name for the initiative')
param displayName string

@description('Detailed description of the compliance initiative')
param policySetDescription string

@description('Initiative metadata object containing category, version, and framework mapping')
param metadata object = {
  category: 'Confidential Computing'
  version: '1.0.0'
  source: 'Camber Sovereign Mesh'
}

@description('Array of policy definition reference objects bundled in this initiative')
param policyDefinitions array = []

resource policySet 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: policySetName
  properties: {
    displayName: displayName
    description: policySetDescription
    policyType: 'Custom'
    metadata: metadata
    policyDefinitions: [for (policy, i) in policyDefinitions: {
      policyDefinitionId: policy.policyDefinitionId
      policyDefinitionReferenceId: policy.?policyDefinitionReferenceId ?? 'policy-${i}'
      parameters: policy.?parameters ?? null
      groupNames: policy.?groupNames ?? []
    }]
  }
}

@description('Resource ID of the policy set definition')
output id string = policySet.id

@description('Name of the policy set definition')
output name string = policySet.name
