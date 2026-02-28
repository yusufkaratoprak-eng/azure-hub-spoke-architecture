param nsgId string
param routeTableId string

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: 'my-vnet2'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: 'my-subnet2'
  parent: vnet
  properties: {
    addressPrefix: '10.1.1.0/24'
    networkSecurityGroup: {
      id: nsgId
    }
    routeTable: {
      id: routeTableId
    }
    
  }
}
