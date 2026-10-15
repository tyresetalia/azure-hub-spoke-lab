# ==============================================================================
# Azure Enterprise Hub-and-Spoke Teardown Script (PowerShell / Azure CLI)
# ==============================================================================

$rgName = "rg-hub-spoke-lab"

Write-Host "==============================================================" -ForegroundColor Red
Write-Host "  Azure Hub-and-Spoke Lab — FinOps Cleanup & Teardown         " -ForegroundColor Red
Write-Host "==============================================================" -ForegroundColor Red

$confirmation = Read-Host "Weet je zeker dat je alle resources in '$rgName' wilt verwijderen? (j/n)"
if ($confirmation -ne 'j' -and $confirmation -ne 'y') {
    Write-Host "Opschonen geannuleerd." -ForegroundColor Yellow
    exit
}

Write-Host "`nBezig met verwijderen van Resource Group: $rgName..." -ForegroundColor Yellow
Write-Host "Dit verwijdert alle VNets, Bastion, VM's en schijven op de achtergrond..." -ForegroundColor DarkGray

az group delete --name $rgName --yes --no-wait

Write-Host "`n==============================================================" -ForegroundColor Green
Write-Host "  Verwijderopdracht verzonden naar Azure Resource Manager!    " -ForegroundColor Green
Write-Host "  Er worden geen verdere kosten meer gemaakt voor dit lab.    " -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Green
