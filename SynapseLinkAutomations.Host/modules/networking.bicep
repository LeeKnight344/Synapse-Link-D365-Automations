param AZ_Resource_Location string
param AZ_Vnet_Name string
param AZ_Subnet_Name string
param AZ_Nic_Name string
param AZ_NSG_Name string


resource AZ_Vnet_Name_Resource 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: AZ_Vnet_Name
  location: AZ_Resource_Location
  properties: {
    addressSpace: {
      addressPrefixes: ['100.64.0.0/22']
    }
    subnets: [
      {
        name: AZ_Subnet_Name
        properties: {
          addressPrefix: '100.64.1.0/28'
        }
      }
    ]
  }
}




resource publicIP 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: '${AZ_Nic_Name}-pip'
  location: AZ_Resource_Location
  properties: {
    publicIPAllocationMethod: 'Dynamic' 
  }
}


resource nic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: AZ_Nic_Name
  location: AZ_Resource_Location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: {
            id: AZ_Vnet_Name_Resource.properties.subnets[0].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: AZ_NSG_Name_Resource.id
    }
  }
}



resource AZ_NSG_Name_Resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: AZ_NSG_Name
  location: AZ_Resource_Location
  properties: {
    securityRules: []
  }
}

output nicId string = nic.id
output nsgId string = AZ_NSG_Name_Resource.id
output subnetId string = AZ_Vnet_Name_Resource.properties.subnets[0].id

