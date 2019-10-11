metadata description = 'Camber scoped Azure Policy assignment with managed identity remediation'

@description('Unique technical name for the policy assignment')
param assignmentName string

@description('Human readable display name for the assignment')
param displayName string

@description('Detailed description of the assignment rationale')
param assignmentDescription string

@description('Resource ID of the policy definition or policy set definition')
param policyDefinitionId string

@description('Optional parameters object passed to the policy assignment')
param parameters object = {}

@description('Array of non compliance explanation messages displayed in audit logs')
param nonComplianceMessages array = []

@description('Enforcement mode for the policy assignment')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

@description('Azure region for the assignment managed identity')
param location string = resourceGroup().location

@description('Whether to provision a system-assigned managed identity for automated remediation')
param assignIdentity bool = true

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: assignmentName
  location: location
  identity: assignIdentity ? {
    type: 'SystemAssigned'
  } : {
    type: 'None'
  }
  properties: {
    displayName: displayName
    description: assignmentDescription
    policyDefinitionId: policyDefinitionId
    enforcementMode: enforcementMode
    parameters: parameters
    nonComplianceMessages: [for msg in nonComplianceMessages: {
      message: msg.message
      policyDefinitionReferenceId: msg.?policyDefinitionReferenceId ?? null
    }]
  }
}

@description('Resource ID of the policy assignment')
output id string = policyAssignment.id

@description('Name of the policy assignment')
output name string = policyAssignment.name

@description('Principal ID of the system-assigned remediation identity')
output principalId string = assignIdentity ? policyAssignment.identity.principalId : ''
