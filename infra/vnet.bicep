resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'my-vnet2'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.1.0.0/16']
    }
  }
}
