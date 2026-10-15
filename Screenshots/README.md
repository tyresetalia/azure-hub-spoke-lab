# 📸 Bewijsmateriaal & Screenshot Gallerij — Azure Hub-and-Spoke Lab

Dit overzicht bevat alle officiële bewijsscreenshots die zijn vastgelegd tijdens het uitvoeren en valideren van het Azure Hub-and-Spoke netwerklab.

---

### 1. Resource Group Aangemaakt
- **Bestand**: `01-resource-group-created.png`
- **Omschrijving**: Bevestiging van het aanmaken van `rg-hub-spoke-lab` in regio `East US`.
![01-resource-group-created](01-resource-group-created.png)

---

### 2. Overzicht van de Drie Virtual Networks
- **Bestand**: `02-vnets-overview.png`
- **Omschrijving**: De 3 virtuele netwerken (`vnet-hub`, `vnet-spoke-dev`, `vnet-spoke-prod`) actief in `rg-hub-spoke-lab`.
![02-vnets-overview](02-vnets-overview.png)

---

### 3. Bi-directionele VNet Peerings Verbonden
- **Bestand**: `03-vnet-peerings-connected.png`
- **Omschrijving**: De twee peeringkoppelingen op `vnet-hub` in de status *Volledig gesynchroniseerd* en *Connected*.
![03-vnet-peerings-connected](03-vnet-peerings-connected.png)

---

### 4. Virtuele Machines met Uitsluitend Private IP's
- **Bestand**: `04-vms-created-private-ips.png`
- **Omschrijving**: `vm-dev-01` en `vm-prod-01` actief met uitsluitend interne IP's (`Openbaar IP-adres: -`).
![04-vms-created-private-ips](04-vms-created-private-ips.png)

---

### 5. Troubleshooting: Zone Error op Standard Public IP
- **Bestand**: `05-troubleshooting-bastion-zone-error.png`
- **Omschrijving**: Foutmelding `BadRequest` door het ontbreken van een verplichte Availability Zone op het Standard Public IP in `East US`.
![05-troubleshooting-bastion-zone-error](05-troubleshooting-bastion-zone-error.png)

---

### 6. Oplossing: Public IP met Zone-Redundantie Aangemaakt
- **Bestand**: `06-pip-bastion-zone-redundant.png`
- **Omschrijving**: Handmatig en resilient aangemaakt Standard Public IP `pip-bastion-hub` met zones 1, 2 en 3.
![06-pip-bastion-zone-redundant](06-pip-bastion-zone-redundant.png)

---

### 7. Azure Bastion Succesvol Uitgerold
- **Bestand**: `07-bastion-deployed-success.png`
- **Omschrijving**: Azure Bastion operationeel in `AzureBastionSubnet` met zones `2, 3, 1` en status `Succeeded`.
![07-bastion-deployed-success](07-bastion-deployed-success.png)

---

### 8. Zero-Exposure Bastion SSH & Spoke Isolatietest
- **Bestand**: `08-bastion-ssh-spoke-isolation-test.png`
- **Omschrijving**: Browser-gebaseerde Bastion SSH-sessie op `vm-prod-01` (10.1.1.4) met 100% packet loss naar `vm-dev-01` (10.2.1.4) als bewijs van niet-transitieve routering.
![08-bastion-ssh-spoke-isolation-test](08-bastion-ssh-spoke-isolation-test.png)

---

### 9. Network Watcher Hub-and-Spoke Topologie
- **Bestand**: `09-network-watcher-topology.png`
- **Omschrijving**: Azure Network Watcher topologiediagram dat de stervormige architectuur visueel aantoont.
![09-network-watcher-topology](09-network-watcher-topology.png)
