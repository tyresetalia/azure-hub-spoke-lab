#!/bin/bash
# ==============================================================================
# Azure Enterprise Hub-and-Spoke Deployment Script (Bash / Azure CLI)
# ==============================================================================

set -e

LOCATION="eastus"
RG_NAME="rg-hub-spoke-lab"

VNET_HUB="vnet-hub"
VNET_PROD="vnet-spoke-prod"
VNET_DEV="vnet-spoke-dev"

SUBNET_BASTION="AzureBastionSubnet"
SUBNET_MGMT="snet-hub-mgmt"
SUBNET_PROD="snet-prod"
SUBNET_DEV="snet-dev"

VM_ADMIN="azureuser"
VM_SIZE="Standard_B1s"
IMAGE="Ubuntu2204"

echo "=============================================================="
echo "  Starting Azure Enterprise Hub-and-Spoke Lab Deployment      "
echo "=============================================================="

# 1. Resource Group
echo -e "\n[1/8] Aanmaken Resource Group: $RG_NAME ($LOCATION)..."
az group create --name "$RG_NAME" --location "$LOCATION" --output none

# 2. Virtual Networks & Subnets
echo -e "\n[2/8] Aanmaken Virtuele Netwerken..."
az network vnet create --resource-group "$RG_NAME" --name "$VNET_HUB" --address-prefixes 10.0.0.0/16 --subnet-name "$SUBNET_BASTION" --subnet-prefixes 10.0.1.0/26 --output none
az network vnet subnet create --resource-group "$RG_NAME" --vnet-name "$VNET_HUB" --name "$SUBNET_MGMT" --address-prefixes 10.0.2.0/24 --output none

az network vnet create --resource-group "$RG_NAME" --name "$VNET_PROD" --address-prefixes 10.1.0.0/16 --subnet-name "$SUBNET_PROD" --subnet-prefixes 10.1.1.0/24 --output none
az network vnet create --resource-group "$RG_NAME" --name "$VNET_DEV" --address-prefixes 10.2.0.0/16 --subnet-name "$SUBNET_DEV" --subnet-prefixes 10.2.1.0/24 --output none

# 3. Peerings
echo -e "\n[3/8] Configureren VNet Peerings (Hub <-> Spokes)..."
HUB_ID=$(az network vnet show --resource-group "$RG_NAME" --name "$VNET_HUB" --query id -o tsv)
PROD_ID=$(az network vnet show --resource-group "$RG_NAME" --name "$VNET_PROD" --query id -o tsv)
DEV_ID=$(az network vnet show --resource-group "$RG_NAME" --name "$VNET_DEV" --query id -o tsv)

az network vnet peering create --resource-group "$RG_NAME" --name peer-hub-to-spoke-prod --vnet-name "$VNET_HUB" --remote-vnet "$PROD_ID" --allow-vnet-access --allow-forwarded-traffic --output none
az network vnet peering create --resource-group "$RG_NAME" --name peer-spoke-prod-to-hub --vnet-name "$VNET_PROD" --remote-vnet "$HUB_ID" --allow-vnet-access --allow-forwarded-traffic --output none

az network vnet peering create --resource-group "$RG_NAME" --name peer-hub-to-spoke-dev --vnet-name "$VNET_HUB" --remote-vnet "$DEV_ID" --allow-vnet-access --allow-forwarded-traffic --output none
az network vnet peering create --resource-group "$RG_NAME" --name peer-spoke-dev-to-hub --vnet-name "$VNET_DEV" --remote-vnet "$HUB_ID" --allow-vnet-access --allow-forwarded-traffic --output none

# 4. Standard Public IP met Zone Redundantie
echo -e "\n[4/8] Public IP aanmaken voor Bastion (Zone-Redundant)..."
az network public-ip create --resource-group "$RG_NAME" --name pip-bastion-hub --sku Standard --zone 1 2 3 --location "$LOCATION" --output none

# 5. Bastion Host
echo -e "\n[5/8] Implementeren Azure Bastion Host (5-7 minuten)..."
az network bastion create --resource-group "$RG_NAME" --name bastion-hub --public-ip-address pip-bastion-hub --vnet-name "$VNET_HUB" --location "$LOCATION" --sku Basic --output none

# 6. VM Prod (Geen Public IP)
echo -e "\n[6/8] Uitrollen vm-prod-01 (Zero Public IP)..."
az vm create --resource-group "$RG_NAME" --name vm-prod-01 --image "$IMAGE" --size "$VM_SIZE" --vnet-name "$VNET_PROD" --subnet "$SUBNET_PROD" --public-ip-address '""' --admin-username "$VM_ADMIN" --generate-ssh-keys --output none

# 7. VM Dev (Geen Public IP)
echo -e "\n[7/8] Uitrollen vm-dev-01 (Zero Public IP)..."
az vm create --resource-group "$RG_NAME" --name vm-dev-01 --image "$IMAGE" --size "$VM_SIZE" --vnet-name "$VNET_DEV" --subnet "$SUBNET_DEV" --public-ip-address '""' --admin-username "$VM_ADMIN" --generate-ssh-keys --output none

echo -e "\n=============================================================="
echo "  Hub-and-Spoke Lab Deployment Succesvol Afgerond!"
echo "=============================================================="
