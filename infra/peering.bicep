// VNet1 
resource vnet1 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: 'my-vnet'
}

// VNet2 
resource vnet2 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: 'my-vnet2'
}

// VNet1 → VNet2
resource peering1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: 'vnet1-to-vnet2'
  parent: vnet1
  properties: {
    remoteVirtualNetwork: {
      id: vnet2.id
    }
    allowVirtualNetworkAccess: true
  }
}

// VNet2 → VNet1
resource peering2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: 'vnet2-to-vnet1'
  parent: vnet2
  properties: {
    remoteVirtualNetwork: {
      id: vnet1.id
    }
    allowVirtualNetworkAccess: true
  }
}
