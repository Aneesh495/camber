metadata description = 'Camber custom RBAC role definition for sovereign enclave least privilege'

@description('Unique display name for the custom role')
param roleName string

@description('Detailed description of permissions granted by this role')
param roleDescription string

@description('Allowed control plane actions')
param actions array = []

@description('Denied control plane actions')
param notActions array = []

@description('Allowed data plane actions')
param dataActions array = []

@description('Denied data plane actions')
param notDataActions array = []

@description('Scopes where this custom role can be assigned')
param assignableScopes array = [
  resourceGroup().id
]

@description('Deterministic role definition GUID')
param roleDefinitionId string = guid(resourceGroup().id, roleName)

resource customRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleDefinitionId
  properties: {
    roleName: roleName
    description: roleDescription
    type: 'CustomRole'
    permissions: [
      {
        actions: actions
        notActions: notActions
        dataActions: dataActions
        notDataActions: notDataActions
      }
    ]
    assignableScopes: assignableScopes
  }
}

@description('Resource ID of the custom role definition')
output id string = customRole.id

@description('GUID name of the custom role definition')
output name string = customRole.name

@description('Display name of the custom role definition')
output roleName string = customRole.properties.roleName
