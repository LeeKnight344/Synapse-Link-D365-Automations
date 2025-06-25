param AZ_Resource_Location string 
param AZ_VM_Name string 
param AZ_Admin_Usr string 
@secure()
param AZ_Admin_Pwd string
param AZ_NSG_Name string 
param AZ_Nic_Name string 
param AZ_Subnet_Name string 
param AZ_Vnet_Name string 
param AZ_VM_OS_Name string 

module networkModule 'modules/networking.bicep' = {
  name: 'networkDeploy'
  params: {
    AZ_Resource_Location: AZ_Resource_Location
    AZ_Vnet_Name: AZ_Vnet_Name
    AZ_Subnet_Name: AZ_Subnet_Name
    AZ_Nic_Name: AZ_Nic_Name
    AZ_NSG_Name: AZ_NSG_Name
  }
}

module vmModule 'modules/vm.bicep' = {
  name: 'vmDeploy'
  params: {
    AZ_VM_Name: AZ_VM_Name
    AZ_Resource_Location: AZ_Resource_Location
    AZ_Admin_Usr: AZ_Admin_Usr
    AZ_Admin_Pwd: AZ_Admin_Pwd
    AZ_VM_OS_Name: AZ_VM_OS_Name
    nicId: networkModule.outputs.nicId
  }
}




module SynapseAutomationAPI 'modules/SynapseAutomationAPI.bicep' = {
  name: 'SynapseAutomationAPI'
  params: {
    AZ_VM_Name: AZ_VM_Name
    AZ_Resource_Location: AZ_Resource_Location
  }
  dependsOn: [
    vmModule
  ]
}


