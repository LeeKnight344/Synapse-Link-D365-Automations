param AZ_Resource_Location string
param AZ_VM_Name string


resource AZ_VM_Name_Resource 'Microsoft.Compute/virtualMachines@2021-03-01' existing = {
  name: AZ_VM_Name
}


resource DownloadAndBuild 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  name: 'DownloadAndBuild'
  parent: AZ_VM_Name_Resource
  location: AZ_Resource_Location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/LeeKnight344/Synapse-Link-D365-Automations/refs/heads/main/SynapseLinkAutomations.Host/modules/downloadandbuild.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File downloadandbuild.ps1'
    }
  }
}
