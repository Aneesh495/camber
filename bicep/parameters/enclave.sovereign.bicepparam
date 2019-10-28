using '../main.bicep'

param environment = 'enclave'
param workloadName = 'camber-sov'
param primaryLocation = 'switzerlandnorth'
param secondaryLocation = 'germanywestcentral'
param adminUsername = 'camberadmin'
param databasePassword = 'CamberSovereignEnclavePassword2026!#UltraSecure'
param sshPublicKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICamberAirgapSovereignSecurityKey2026 camberadmin@camber.internal'
param hsmAdminObjectIds = [
  '44444444-5555-6666-7777-888888888888'
]
