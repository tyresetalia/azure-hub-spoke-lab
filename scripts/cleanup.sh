#!/bin/bash
# ==============================================================================
# Azure Enterprise Hub-and-Spoke Teardown Script (Bash / Azure CLI)
# ==============================================================================

RG_NAME="rg-hub-spoke-lab"

echo "=============================================================="
echo "  Azure Hub-and-Spoke Lab — FinOps Cleanup & Teardown         "
echo "=============================================================="

read -p "Weet je zeker dat je alle resources in '$RG_NAME' wilt verwijderen? (j/n): " confirm
if [[ "$confirm" != "j" && "$confirm" != "y" ]]; then
    echo "Opschonen geannuleerd."
    exit 0
fi

echo -e "\nBezig met verwijderen van Resource Group: $RG_NAME..."
az group delete --name "$RG_NAME" --yes --no-wait

echo -e "\n=============================================================="
echo "  Verwijderopdracht verzonden naar Azure Resource Manager!"
echo "  Er worden geen verdere kosten meer gemaakt voor dit lab."
echo "=============================================================="
