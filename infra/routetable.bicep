// Route Table 
resource routeTable 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'rt-vnet2'
  location: resourceGroup().location
  properties: {
    routes: [
      {
        name: 'udr-internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

output routeTableId string = routeTable.id
