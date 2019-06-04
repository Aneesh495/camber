metadata description = 'Camber granular RBAC role assignment with ABAC condition support'

@description('Principal ID of the service principal, user, or group')
param principalId string

@description('Fully qualified or GUID role definition ID')
param roleDefinitionId string

@description('Principal type assigned to the role')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
  'Device'
  'ForeignGroup'
])
param principalType string = 'ServicePrincipal'

@description('Optional human readable description of the assignment rationale')
param roleDescription string = 'Camber autonomous sovereign RBAC role assignment'

@description('Optional ABAC attribute-based access control condition expression')
param condition string = ''

@description('ABAC condition syntax version')
@allowed([
  '2.0'
  ''
])
param conditionVersion string = ''

@description('Deterministic role assignment name GUID')
param roleAssignmentName string = guid(resourceGroup().id, principalId, roleDefinitionId)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    principalType: principalType
    description: roleDescription
    condition: empty(condition) ? null : condition
    conditionVersion: empty(conditionVersion) ? null : conditionVersion
  }
}

@description('Resource ID of the role assignment')
output id string = roleAssignment.id

@description('Name of the role assignment')
output name string = roleAssignment.name

@description('Assigned principal ID')
output principalId string = roleAssignment.properties.principalId

@description('Assigned role definition ID')
output roleDefinitionId string = roleAssignment.properties.roleDefinitionId
