param AZ_VM_Name string
param AZ_VM_OS_Name string
param AZ_Resource_Location string
param AZ_Admin_Usr string
@secure()
param AZ_Admin_Pwd string

param nicId string

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: AZ_VM_Name
  location: AZ_Resource_Location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    osProfile: {
      computerName: AZ_VM_OS_Name
      adminUsername: AZ_Admin_Usr
      adminPassword: AZ_Admin_Pwd

    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2025-datacenter-azure-edition-smalldisk'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
        }
      ]
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    licenseType: 'Windows_Server'
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

