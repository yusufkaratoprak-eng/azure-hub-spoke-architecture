# Azure VNet Infrastructure — Bicep & AZ CLI

This project demonstrates how to build a secure network infrastructure between two VNets on Azure using Bicep and AZ CLI.

---

## 📁 Project Structure

```
infra/
├── main.bicep          # Main deployment file (orchestrates all modules)
├── nsg.bicep           # Network Security Group for my-vnet2
├── subnet.bicep        # Subnet definition for my-vnet2
├── routetable.bicep    # Route Table + UDR for my-vnet2
├── peering.bicep       # VNet Peering (vnet1 ↔ vnet2)
├── vnet.bicep          # VNet definition
├── deploy.ps1          # PowerShell deploy script
├── deploy.sh           # Bash deploy script
└── playbook.yml        # Ansible playbook
```

---

## 🏗️ Architecture

```
my-rg (Resource Group)
│
├── my-vnet  (10.0.0.0/16)
│   ├── my-subnet       (10.0.1.0/24)
│   ├── my-nsg          (Only allows inbound traffic from my-vnet2)
│   └── Peering → my-vnet2
│
└── my-vnet2 (10.1.0.0/16)
    ├── my-subnet2  (10.1.1.0/24)
    ├── my-nsg2     (Only allows inbound traffic from my-vnet)
    ├── rt-vnet2    (Route Table — next hop: Internet)
    └── Peering → my-vnet
```

---

## 🚀 Getting Started

### Prerequisites

- [Azure CLI](https://aka.ms/installazurecliwindows) installed
- Login to your Azure account:

```powershell
az login
```

---

## 📋 Step-by-Step with AZ CLI

### 1. Create Resource Group

```powershell
az group create --name my-rg --location westeurope
```

### 2. Create VNets

```powershell
# VNet1
az network vnet create --name my-vnet --resource-group my-rg --address-prefix 10.0.0.0/16

# VNet2
az network vnet create --name my-vnet2 --resource-group my-rg --address-prefix 10.1.0.0/16
```

### 3. Create Subnet

```powershell
az network vnet subnet create --name my-subnet --vnet-name my-vnet --resource-group my-rg --address-prefix 10.0.1.0/24
```

### 4. Create NSG and Attach to Subnet

```powershell
az network nsg create --name my-nsg --resource-group my-rg --location westeurope
az network vnet subnet update --name my-subnet --vnet-name my-vnet --resource-group my-rg --network-security-group my-nsg
```

### 5. NSG Rules — Allow Only Traffic from VNet2

```powershell
# Allow inbound from VNet2
az network nsg rule create --name Allow-VNet2 --nsg-name my-nsg --resource-group my-rg \
  --priority 100 --direction Inbound --access Allow --protocol * \
  --source-address-prefix 10.1.0.0/16 --destination-address-prefix *

# Deny all other inbound traffic
az network nsg rule create --name Deny-All-Inbound --nsg-name my-nsg --resource-group my-rg \
  --priority 4096 --direction Inbound --access Deny --protocol * \
  --source-address-prefix * --destination-address-prefix *
```

### 6. VNet Peering (AZ CLI — one direction)

```powershell
# VNet2 → VNet1
az network vnet peering create --name vnet2-to-vnet1 --resource-group my-rg \
  --vnet-name my-vnet2 --remote-vnet my-vnet --allow-vnet-access
```

> The other direction (VNet1 → VNet2) is handled by `peering.bicep`.

---

## 🔧 Deployment with Bicep

`main.bicep` orchestrates all modules with proper dependency ordering. Deploy with a single command:

```powershell
az deployment group create --resource-group my-rg --template-file main.bicep
```

### main.bicep

```bicep
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
  dependsOn: [
    nsgModule
    routeTableModule
    vnetModule
  ]
  params: {
    nsgId: nsgModule.outputs.nsgId
    routeTableId: routeTableModule.outputs.routeTableId
  }
}

module peeringModule 'peering.bicep' = {
  name: 'peeringDeploy'
  dependsOn: [
    subnetModule
  ]
}
```

### nsg.bicep

```bicep
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'my-nsg2'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'Allow-VNet1'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '10.0.0.0/16'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

output nsgId string = nsg.id
```

### routetable.bicep

```bicep
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
```

### subnet.bicep

```bicep
param nsgId string
param routeTableId string

resource vnet2 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: 'my-vnet2'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: 'my-subnet2'
  parent: vnet2
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
```

### peering.bicep

```bicep
resource vnet1 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: 'my-vnet'
}

resource vnet2 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: 'my-vnet2'
}

// VNet1 → VNet2 (VNet2 → VNet1 was created via AZ CLI)
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
```

---

## ✅ Verify Deployment

```powershell
# Check peering status
az network vnet peering show --name vnet1-to-vnet2 --resource-group my-rg \
  --vnet-name my-vnet --query peeringState

az network vnet peering show --name vnet2-to-vnet1 --resource-group my-rg \
  --vnet-name my-vnet2 --query peeringState

# Check subnet has NSG and Route Table attached
az network vnet subnet show --name my-subnet2 --vnet-name my-vnet2 \
  --resource-group my-rg --query "{NSG:networkSecurityGroup.id, RouteTable:routeTable.id}"
```

Both peerings should return `"Connected"` ✅

---

## 💰 Cost Overview

| Resource | Cost |
|----------|------|
| VNet | Free ✅ |
| Subnet | Free ✅ |
| NSG | Free ✅ |
| Route Table / UDR | Free ✅ |
| VNet Peering | ~$0.01 per GB |
| Azure Firewall | ~$1.25 per hour |

---

## 📌 Important Notes

- Both VNets must use non-overlapping IP ranges (required for peering)
- `my-vnet`: `10.0.0.0/16`, `my-vnet2`: `10.1.0.0/16`
- VNet Peering must be configured **in both directions**
- The `Deny-All` NSG rule must always have the highest priority number (4096)
- UDR alone cannot route traffic between two isolated VNets — peering is required first
- When multiple Bicep modules update the same subnet, use `dependsOn` to avoid deployment conflicts
