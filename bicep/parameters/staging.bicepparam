using '../main.bicep'

param environment = 'staging'
param workloadName = 'camber-stg'
param primaryLocation = 'eastus2'
param secondaryLocation = 'centralus'
param adminUsername = 'camberadmin'
param databasePassword = 'CamberStagingPassword2026!#Enclave'
param sshPublicKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICamberStagingSecurityKey2026 camberadmin@camber.internal'
param hsmAdminObjectIds = [
  '33333333-4444-5555-6666-777777777777'
]
