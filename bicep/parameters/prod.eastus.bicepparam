using '../main.bicep'

param environment = 'prod'
param workloadName = 'camber-prod'
param primaryLocation = 'eastus'
param secondaryLocation = 'westeurope'
param adminUsername = 'camberadmin'
param databasePassword = 'CamberSecurePassword2026!#Enclave'
param sshPublicKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICamberProductionSecuritySovereignKey2026 camberadmin@camber.internal'
param hsmAdminObjectIds = [
  '11111111-2222-3333-4444-555555555555'
]
