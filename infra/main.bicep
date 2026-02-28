module nsgModule 'nsg.bicep' = {
  name: 'nsgDeploy'
}
module routeTableModule 'routetable.bicep' = {
  name: 'routeTableDeploy'
}

module vnetModule 'vnet.bicep' = {
  name: 'vnetDeploy'
}

module subnetModule 'subnet.bicep' = {
  name: 'subnetDeploy'
  params: {
    nsgId: nsgModule.outputs.nsgId
    routeTableId: routeTableModule.outputs.routeTableId
  }
}


module peeringModule 'peering.bicep' = {
  name: 'peeringDeploy'
}


