using '../main.bicep'

param environment = 'prod'
param workloadName = 'camber-eu'
param primaryLocation = 'westeurope'
param secondaryLocation = 'northeurope'
param adminUsername = 'camberadmin'
param databasePassword = 'CamberEUSecurePassword2026!#Enclave'
param sshPublicKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICamberEuropeProductionSecurityKey2026 camberadmin@camber.internal'
param hsmAdminObjectIds = [
  '22222222-3333-4444-5555-666666666666'
]
