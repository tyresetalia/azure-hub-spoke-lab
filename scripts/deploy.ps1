# ==============================================================================
# Azure Enterprise Hub-and-Spoke Deployment Script (PowerShell / Azure CLI)
# ==============================================================================

$ErrorActionPreference = "Stop"

$location = "eastus"
$rgName = "rg-hub-spoke-lab"

# Netwerkvariabelen
$vnetHubName = "vnet-hub"
$vnetProdName = "vnet-spoke-prod"
$vnetDevName = "vnet-spoke-dev"

$bastionSubnetName = "AzureBastionSubnet"
$mgmtSubnetName = "snet-hub-mgmt"
$prodSubnetName = "snet-prod"
$devSubnetName = "snet-dev"

# Compute variabelen
$vmAdminUser = "azureuser"
$vmSize = "Standard_B1s"
$image = "Ubuntu2204"

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  Starting Azure Enterprise Hub-and-Spoke Lab Deployment      " -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan

# 1. Resource Group
Write-Host "`n[1/8] Aanmaken Resource Group: $rgName ($location)..." -ForegroundColor Yellow
az group create --name $rgName --location $location --output none

# 2. Virtual Networks
Write-Host "`n[2/8] Aanmaken Virtuele Netwerken (VNets)..." -ForegroundColor Yellow
# Hub VNet
az network vnet create `
  --resource-group $rgName `
  --name $vnetHubName `
  --address-prefixes 10.0.0.0/16 `
  --subnet-name $bastionSubnetName `
  --subnet-prefixes 10.0.1.0/26 `
  --output none

az network vnet subnet create `
  --resource-group $rgName `
  --vnet-name $vnetHubName `
  --name $mgmtSubnetName `
  --address-prefixes 10.0.2.0/24 `
  --output none

# Spoke Prod VNet
az network vnet create `
  --resource-group $rgName `
  --name $vnetProdName `
  --address-prefixes 10.1.0.0/16 `
  --subnet-name $prodSubnetName `
  --subnet-prefixes 10.1.1.0/24 `
  --output none

# Spoke Dev VNet
az network vnet create `
  --resource-group $rgName `
  --name $vnetDevName `
  --address-prefixes 10.2.0.0/16 `
  --subnet-name $devSubnetName `
  --subnet-prefixes 10.2.1.0/24 `
  --output none

# 3. VNet Peerings (Hub <-> Spokes)
Write-Host "`n[3/8] Configureren Bi-directionele VNet Peerings..." -ForegroundColor Yellow
$hubId = az network vnet show --resource-group $rgName --name $vnetHubName --query id -o tsv
$prodId = az network vnet show --resource-group $rgName --name $vnetProdName --query id -o tsv
$devId = az network vnet show --resource-group $rgName --name $vnetDevName --query id -o tsv

# Hub <-> Prod
az network vnet peering create --resource-group $rgName --name peer-hub-to-spoke-prod --vnet-name $vnetHubName --remote-vnet $prodId --allow-vnet-access --allow-forwarded-traffic --output none
az network vnet peering create --resource-group $rgName --name peer-spoke-prod-to-hub --vnet-name $vnetProdName --remote-vnet $hubId --allow-vnet-access --allow-forwarded-traffic --output none

# Hub <-> Dev
az network vnet peering create --resource-group $rgName --name peer-hub-to-spoke-dev --vnet-name $vnetHubName --remote-vnet $devId --allow-vnet-access --allow-forwarded-traffic --output none
az network vnet peering create --resource-group $rgName --name peer-spoke-dev-to-hub --vnet-name $vnetDevName --remote-vnet $hubId --allow-vnet-access --allow-forwarded-traffic --output none

# 4. Standard Public IP voor Bastion (Zone-Redundant)
Write-Host "`n[4/8] Resilient Zone-Redundant Public IP aanmaken voor Bastion..." -ForegroundColor Yellow
az network public-ip create `
  --resource-group $rgName `
  --name pip-bastion-hub `
  --sku Standard `
  --zone 1 2 3 `
  --location $location `
  --output none

# 5. Azure Bastion Host
Write-Host "`n[5/8] Implementeren Azure Bastion Host (duurt 5-7 minuten)..." -ForegroundColor Yellow
az network bastion create `
  --resource-group $rgName `
  --name bastion-hub `
  --public-ip-address pip-bastion-hub `
  --vnet-name $vnetHubName `
  --location $location `
  --sku Basic `
  --output none

# 6. Virtuele Machine vm-prod-01 (Geen openbaar IP)
Write-Host "`n[6/8] Uitrollen vm-prod-01 in Spoke Prod (Zero Public IP)..." -ForegroundColor Yellow
az vm create `
  --resource-group $rgName `
  --name vm-prod-01 `
  --image $image `
  --size $vmSize `
  --vnet-name $vnetProdName `
  --subnet $prodSubnetName `
  --public-ip-address '""' `
  --admin-username $vmAdminUser `
  --generate-ssh-keys `
  --output none

# 7. Virtuele Machine vm-dev-01 (Geen openbaar IP)
Write-Host "`n[7/8] Uitrollen vm-dev-01 in Spoke Dev (Zero Public IP)..." -ForegroundColor Yellow
az vm create `
  --resource-group $rgName `
  --name vm-dev-01 `
  --image $image `
  --size $vmSize `
  --vnet-name $vnetDevName `
  --subnet $devSubnetName `
  --public-ip-address '""' `
  --admin-username $vmAdminUser `
  --generate-ssh-keys `
  --output none

Write-Host "`n==============================================================" -ForegroundColor Green
Write-Host "  Hub-and-Spoke Lab Deployment Succesvol Afgerond!             " -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Green
