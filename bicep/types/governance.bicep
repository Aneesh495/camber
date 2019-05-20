metadata description = 'Camber governance, Azure Policy initiatives, and compliance baseline contracts'

@description('Policy effect mode')
@export()
type policyEffectMode = 'Audit' | 'Deny' | 'Disabled' | 'Modify' | 'AuditIfNotExists' | 'DeployIfNotExists'

@description('Policy rule condition expression contract')
@export()
type policyRuleCondition = {
  field: string
  operator: 'equals' | 'notEquals' | 'in' | 'notIn' | 'match' | 'exists'
  #disable-next-line no-explicit-any
  value: any
}

@description('Custom Azure Policy definition contract')
@export()
type customPolicyDefinition = {
  name: string
  displayName: string
  description: string
  mode: 'Indexed' | 'All'
  metadata: object
  parameters: object
  policyRule: object
}

@description('Policy reference member inside an initiative set')
@export()
type policySetDefinitionReference = {
  policyDefinitionId: string
  policyDefinitionReferenceId: string
  parameters: object?
  groupNames: string[]?
}

@description('Azure Policy initiative set specification')
@export()
type policySetSpecification = {
  name: string
  displayName: string
  description: string
  metadata: object
  parameters: object?
  policyDefinitions: policySetDefinitionReference[]
}

@description('Non compliance explanation message contract')
@export()
type nonComplianceMessage = {
  message: string
  policyDefinitionReferenceId: string?
}

@description('Policy assignment contract with managed identity remediation')
@export()
type policyAssignmentSpecification = {
  assignmentName: string
  displayName: string
  description: string
  policyDefinitionId: string
  enforcementMode: 'Default' | 'DoNotEnforce'
  parameters: object?
  nonComplianceMessages: nonComplianceMessage[]
  assignIdentity: bool
}
