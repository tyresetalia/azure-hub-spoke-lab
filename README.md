# Enterprise Hub-and-Spoke Cloud Network — Microsoft Azure

Ontwerp, implementatie en validatie van een gesegmenteerde enterprise netwerkarchitectuur op Microsoft Azure met VNet Peering, Azure Bastion (Zero Public IP beheer), microsegmentatie en niet-transitieve routingvalidatie.

---

## 🎯 Doel

Aantonen dat ik een schaalbaar, enterprise-grade **Hub-and-Spoke** cloudnetwerk kan ontwerpen, via Azure Portal / CLI kan configureren en beveiligen:
- **Zero-Exposure Architecture**: Workload-VM's in afzonderlijke Spokes zonder enig publiek IP-adres.
- **Centrale Management Hub**: Centrale beheerhub met een dedicated `AzureBastionSubnet` en Azure Bastion Host voor browser-gebaseerd beheer (HTTPS/443).
- **VNet Peering & Microsegmentatie**: Bi-directionele peering tussen Hub en Spokes met strikte netwerkinsolatie tussen Productie en Development.
- **Niet-transitieve Routeringsvalidatie**: Aantonen en bewijzen dat verkeer tussen Spokes niet zonder Next Hop (NVA/Firewall) kan communiceren via de Hub.
- **Real-World Incident Response & Troubleshooting**: Oplossen van Azure Availability Zone-restricties op Standard Public IP's in `eastus`.
- **FinOps & Resource Lifecycle**: Kostenbeheersing door geautomatiseerde teardown na afronding van de tests.

---

## 🏗️ Architectuur & Netwerkontwerp

```
                                [ Internet / Beheerder ]
                                           │
                                           │ HTTPS (Port 443 via Portal)
                                           ▼
                              ┌─────────────────────────┐
                              │    pip-bastion-hub      │
                              │ (Zone-Redundant 1,2,3)  │
                              └────────────┬────────────┘
                                           │
                      ┌────────────────────┴────────────────────┐
                      │          vnet-hub (10.0.0.0/16)         │
                      │   • AzureBastionSubnet: 10.0.1.0/26     │
                      │     [Azure Bastion Host: bastion-hub]   │
                      │   • snet-hub-mgmt:      10.0.2.0/24     │
                      └──────────────┬────────────┬─────────────┘
                                     │            │
            VNet Peering (A)         │            │ VNet Peering (B)
    peer-hub-to-spoke-prod           │            │ peer-hub-to-spoke-dev
                                     ▼            ▼
             ┌──────────────────────────────┐   ┌──────────────────────────────┐
             │  vnet-spoke-prod (10.1.0.0/16)│   │  vnet-spoke-dev (10.2.0.0/16) │
             │  • snet-prod: 10.1.1.0/24    │   │  • snet-dev: 10.2.1.0/24     │
             │  • vm-prod-01 (Ubuntu 24.04) │   │  • vm-dev-01 (Ubuntu 24.04)  │
             │    Private IP: 10.1.1.4      │   │    Private IP: 10.2.1.4      │
             │    Public IP: Geen (None)    │   │    Public IP: Geen (None)    │
             └──────────────────────────────┘   └──────────────────────────────┘
                            ▲                                   ▲
                            └─────── ❌ Geen directe peering ────┘
                                 (Strikte Spoke Isolatie)
```

### Componenten & Specificaties

| Component | Resource Naam | Subnet / IP-Bereik | Specificaties | Doel / Functie |
|---|---|---|---|---|
| **Resource Group** | `rg-hub-spoke-lab` | Regio: `East US` | N.v.t. | Centrale container voor alle lab-resources |
| **Hub VNet** | `vnet-hub` | `10.0.0.0/16` | DNS: Default Azure | Centrale gateway en management-hub |
| **Bastion Subnet** | `AzureBastionSubnet` | `10.0.1.0/26` | 64 adressen | Dedicated subnet exclusief voor Azure Bastion |
| **Hub Mgmt Subnet** | `snet-hub-mgmt` | `10.0.2.0/24` | 256 adressen | Management & shared services subnet |
| **Spoke Prod VNet** | `vnet-spoke-prod` | `10.1.0.0/16` | Peered met `vnet-hub` | Productie virtueel netwerk |
| **Spoke Prod Subnet** | `snet-prod` | `10.1.1.0/24` | 256 adressen | Productie workload subnet |
| **Spoke Dev VNet** | `vnet-spoke-dev` | `10.2.0.0/16` | Peered met `vnet-hub` | Development virtueel netwerk |
| **Spoke Dev Subnet** | `snet-dev` | `10.2.1.0/24` | 256 adressen | Development workload subnet |
| **Prod VM** | `vm-prod-01` | `10.1.1.4` (Privé) | Ubuntu 24.04 LTS Gen2, Standard_D2nls_v6 | Productie server (0% publieke exposure) |
| **Dev VM** | `vm-dev-01` | `10.2.1.4` (Privé) | Ubuntu 24.04 LTS Gen2, Standard_D2nls_v6 | Development server (0% publieke exposure) |
| **Bastion Host** | `bastion-hub` | `AzureBastionSubnet` | Basic SKU | Veilige browser-RDP/SSH gateway |
| **Bastion Public IP**| `pip-bastion-hub` | `51.8.228.210` | Standard SKU, Zones: 1, 2, 3 | Zone-redundant openbaar IP voor Bastion |

---

## 🛠️ Wat is gedaan

1. **Resource Group Architectuur** — Centrale container `rg-hub-spoke-lab` ingericht in regio `East US`.
2. **Hub-and-Spoke VNet Ontwerp** — Drie gescheiden virtuele netwerken aangemaakt (`vnet-hub`, `vnet-spoke-prod`, `vnet-spoke-dev`) met niet-overlappende CIDR-blokken (`10.0.0.0/16`, `10.1.0.0/16`, `10.2.0.0/16`).
3. **Dedicated Bastion Subnettering** — Exact volgens Microsoft standaarden het `AzureBastionSubnet` (`10.0.1.0/26`) ingericht binnen de Hub.
4. **Bi-directionele VNet Peering** — Volledig gesynchroniseerde peeringkoppelingen geconfigureerd tussen Hub en Prod (`peer-hub-to-spoke-prod` ↔ `peer-spoke-prod-to-hub`) en tussen Hub en Dev (`peer-hub-to-spoke-dev` ↔ `peer-spoke-dev-to-hub`). Directe peering tussen Prod en Dev is bewust weggelaten.
5. **Zero-Exposure Workload Provisioning** — Twee Linux Ubuntu servers (`vm-prod-01` en `vm-dev-01`) uitgerold zónder openbare IP-adressen (`Public IP = None`) en met gesloten openbare poorten.
6. **Azure Bastion Implementatie** — Uitrol van een centrale Azure Bastion Host in de Hub gekoppeld aan een zone-redundant Standard Public IP (`pip-bastion-hub`), waarmee remote access over TLS/443 mogelijk werd gemaakt.
7. **Zero-Trust Beheersessie & Validatie** — Succesvolle browser-gebaseerde SSH-verbinding opgezet via Azure Bastion naar `vm-prod-01` (10.1.1.4) zonder tussenkomst van openbare beheerpoorten.
8. **Break & Fix Scenario: Spoke-to-Spoke Isolatie & Niet-transitieve Routing** — Vanuit `vm-prod-01` connectiviteitstest uitgevoerd naar `vm-dev-01` (`ping -c 4 10.2.1.4`). 100% packet loss bewees dat VNet peering niet-transitief is en dat omgevingen strikt geïsoleerd blijven.
9. **Network Watcher Topologie Audit** — Volledig netwerkschema visueel geëvalueerd en geverifieerd via Azure Network Watcher.
10. **Geautomatiseerd Opschonen (FinOps)** — Alle resources direct na validatie verwijderd om onnodige doorlopende kosten van Bastion en VM compute te voorkomen.

---

## 🚨 Troubleshooting & Incident Response

Tijdens de uitrol trad een kritiek praktijkprobleem op dat succesvol is gediagnosticeerd en opgelost:

### Incident: Azure Availability Zone Restrictie op Standard Public IP (`BadRequest` in `East US`)

- **Symptoom:** Bij het aanmaken van Azure Bastion faalde de implementatie met de foutmelding:
  ```text
  (BadRequest) De zone(s) None voor de resource Microsoft.Network/publicIPAddresses/pip-bastion-hub worden niet ondersteund. 
  De ondersteunde zones voor de locatie eastus zijn 1,2,3.
  ```
- **Root Cause Analysis (RCA):**
  Microsoft Azure hanteert in volwassen regio's met meerdere Availability Zones (zoals `East US`) een strikt beleid voor nieuwe Standard Public IP-adressen. Niet-zonale IP-adressen (`Zone: None`) worden geweigerd; Standard Public IP's moeten verplicht zone-gebonden of zone-redundant (`Zones: 1, 2, 3`) worden uitgerold.
- **Oplossing & Mitigatie:**
  1. Handmatig een nieuw Standard Public IP `pip-bastion-hub` aangemaakt met **Beschikbaarheidszones: Zone-redundant (1, 2, 3)**.
  2. Azure Bastion opnieuw gekoppeld aan dit zone-redundante IP.
  3. De implementatie slaagde direct (`Status: Succeeded`).
- **Geleerde Les:** In enterprise cloud-architecturen moet zone-redundantie altijd als ontwerpprincipe worden meegenomen voor load balancers, bastions en public IP gateways om hoge beschikbaarheid (High Availability) te waarborgen.

---

## 🧠 Wat is geleerd / Aangetoonde Vaardigheden

- **Enterprise Cloud Netwerkarchitectuur**: Hub-and-Spoke topologieën, CIDR-planning, netwerksegmentatie en isolatie.
- **VNet Peering & Routing**: Transitieve vs. niet-transitieve routering, Network Watcher topologieverificatie.
- **Zero-Trust Beveiliging & Bastion**: Veilige beheerarchitectuur zonder openbare IP-adressen (Zero Public Exposure).
- **High Availability & Resiliency**: Zone-redundante netwerkcomponenten en foutdiagnose bij Azure Availability Zone vereisten.
- **Linux Netwerkdiagnostiek**: Terminal-auditing met `ip -br a`, connectiviteitsanalyse via `ping` en poortaudits.
- **Kostenbewust Cloudbeheer (FinOps)**: Begrip van gateway-uurkosten (Bastion) en levenscyclusbeheer van labomgevingen.

---

## 📸 Bewijsmateriaal & Screenshots

Alle bewijsstukken zijn gedocumenteerd in de map [`Screenshots/`](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/Screenshots/):

| Nr | Bestandsnaam | Omschrijving |
|:---:|---|---|
| **01** | [`01-resource-group-created.png`](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/Screenshots/01-resource-group-created.png) | Aanmaken van de Resource Group `rg-hub-spoke-lab` in `East US`. |
| **02** | [`02-vnets-overview.png`](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/Screenshots/02-vnets-overview.png) | Overzicht van de drie geconfigureerde VNets (`vnet-hub`, `vnet-spoke-prod`, `vnet-spoke-dev`). |
| **03** | [`03-vnet-peerings-connected.png`](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/Screenshots/03-vnet-peerings-connected.png) | Actieve peeringkoppelingen met status *Volledig gesynchroniseerd* en *Connected*. |
| **04** | [`04-vms-created-private-ips.png`](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/Screenshots/04-vms-created-private-ips.png) | Bewijs van running VM's zonder openbaar IP-adres (`Openbaar IP-adres: -`). |
| **05** | [`05-troubleshooting-bastion-zone-error.png`](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/Screenshots/05-troubleshooting-bastion-zone-error.png) | Incident: `BadRequest` door ontbrekende Availability Zone op het Standard Public IP. |
| **06** | [`06-pip-bastion-zone-redundant.png`](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/Screenshots/06-pip-bastion-zone-redundant.png) | Oplossing: Public IP `pip-bastion-hub` succesvol aangemaakt met zone-redundantie. |
| **07** | [`07-bastion-deployed-success.png`](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/Screenshots/07-bastion-deployed-success.png) | Azure Bastion operationeel in `AzureBastionSubnet` met zones `2, 3, 1`. |
| **08** | [`08-bastion-ssh-spoke-isolation-test.png`](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/Screenshots/08-bastion-ssh-spoke-isolation-test.png) | Bastion SSH-sessie naar `10.1.1.4` en bewijs van 100% packet loss naar `10.2.1.4`. |
| **09** | [`09-network-watcher-topology.png`](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/Screenshots/09-network-watcher-topology.png) | Azure Network Watcher topologiediagram van het Hub-and-Spoke netwerk. |

---

## 📚 Documentatie, Rapport & Scripts

- 📄 **[Officieel Labrapport (Word Document)](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/documentatie/Azure_Hub_Spoke_Lab_Rapport.docx)** — Volledig opgemaakt rapport inclusief ingebedde screenshots, metadata, tabellen en analyses.
- 📘 [Uitgebreide Architectuur- & Labhandleiding (Markdown)](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/documentatie/hub-spoke-architectuur-en-handleiding.md)
- 🛠️ [Troubleshooting & RCA Documentatie](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/documentatie/troubleshooting-scenario.md)
- 📸 [Screenshots Overzicht & Gallerij](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/Screenshots/README.md)
- ⚙️ [Automatisering & FinOps Teardown Scripts](file:///c:/Users/talia/Desktop/PersonalGit/azure-hub-spoke-lab/scripts/)

