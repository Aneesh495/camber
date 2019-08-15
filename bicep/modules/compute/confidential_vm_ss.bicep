metadata description = 'Camber Confidential VM Scale Set running on AMD SEV-SNP hardware with vTPM and secure boot'

@description('Name of the Virtual Machine Scale Set')
param vmssName string

@description('Azure region for the VM Scale Set')
param location string = resourceGroup().location

@description('Resource tags applied to the VM Scale Set')
param tags object = {}

@description('Resource ID of the subnet where instances attach')
param subnetId string

@description('Confidential VM SKU family with AMD SEV-SNP hardware isolation')
param vmSku string = 'Standard_DC4as_v5'

@description('Initial instance capacity')
@minValue(2)
@maxValue(100)
param instanceCount int = 2

@description('Administrator username for Linux instances')
param adminUsername string = 'camberadmin'

@description('SSH RSA/Ed25519 public key data for administrative authentication')
@secure()
param sshPublicKey string

@description('Optional Resource ID of the Disk Encryption Set')
param diskEncryptionSetId string = ''

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
  name: vmssName
  location: location
  tags: union(tags, {
    Fabric: 'Camber'
    Tier: 'ConfidentialCompute'
  })
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    upgradePolicy: {
      mode: 'Rolling'
      rollingUpgradePolicy: {
        maxBatchInstancePercent: 20
        maxUnhealthyInstancePercent: 10
        maxUnhealthyUpgradedInstancePercent: 10
        pauseTimeBetweenBatches: 'PT2M'
      }
    }
    overprovision: false
    doNotRunExtensionsOnOverprovisionedVMs: true
    virtualMachineProfile: {
      securityProfile: {
        securityType: 'ConfidentialVM'
        uefiSettings: {
          secureBootEnabled: true
          vTpmEnabled: true
        }
        encryptionAtHost: true
      }
      osProfile: {
        computerNamePrefix: take(vmssName, 9)
        adminUsername: adminUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUsername}/.ssh/authorized_keys'
                keyData: sshPublicKey
              }
            ]
          }
        }
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadOnly'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
            diskEncryptionSet: !empty(diskEncryptionSetId) ? {
              id: diskEncryptionSetId
            } : null
          }
        }
        imageReference: {
          publisher: 'canonical'
          offer: '0001-com-ubuntu-confidential-vm-jammy'
          sku: '22_04-lts-cvm'
          version: 'latest'
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmssName}-nic'
            properties: {
              primary: true
              enableAcceleratedNetworking: true
              ipConfigurations: [
                {
                  name: 'ipconfig-internal'
                  properties: {
                    subnet: {
                      id: subnetId
                    }
                    primary: true
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}

@description('Resource ID of the Confidential VM Scale Set')
output id string = vmss.id

@description('Name of the Confidential VM Scale Set')
output name string = vmss.name

@description('Principal ID of the VMSS system-assigned managed identity')
output principalId string = vmss.identity.principalId
