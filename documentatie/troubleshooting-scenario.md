# 🛠️ Troubleshooting Scenario's — Azure Hub-and-Spoke Lab

Dit document beschrijft de technische incidenten, diagnoses, root cause analyses (RCA) en beveiligingsvalidaties die zijn uitgevoerd tijdens het Hub-and-Spoke lab.

---

## 📌 Scenario 1: Azure Standard Public IP Availability Zone Beperking (`BadRequest`)

### 1. Incidentbeschrijving & Foutmelding
Tijdens de uitrol van de Azure Bastion Host in de regio `East US` trad bij het automatisch aanmaken van het openbare IP-adres (`pip-bastion-hub`) de volgende foutmelding op:

```text
(BadRequest) De zone(s) None voor de resource Microsoft.Network/publicIPAddresses/pip-bastion-hub worden niet ondersteund. 
De ondersteunde zones voor de locatie eastus zijn 1,2,3.
Code: BadRequest
```

![05-troubleshooting-bastion-zone-error](../Screenshots/05-troubleshooting-bastion-zone-error.png)

---

### 2. Root Cause Analysis (RCA) & Diagnose
1. **Regionaal Beleid in East US**: De regio `East US` is een van de grootste en meest volwassen Azure-datacenters met drie fysiek gescheiden Availability Zones (Zones 1, 2 en 3).
2. **Mandatory Zonal Redundancy**: Om netwerkweerbaarheid en hoge beschikbaarheid te garanderen, ondersteunt Microsoft in `East US` geen niet-zonale Standard Public IP-adressen meer (`Zone: None` of *No Zone*).
3. **PaaS Wizard Default**: De wizard van Azure Bastion probeerde standaard een Public IP aan te maken zonder expliciete zone-toewijzing, wat direct werd geweigerd door de Azure Resource Manager (ARM) engine.

---

### 3. Oplossing & Mitigatie
In plaats van te vertrouwen op de default-instellingen van de Bastion-wizard, is het Public IP vooraf handmatig en resilient geconfigureerd:

1. **Aanmaken Standalone Public IP**:
   - **Naam**: `pip-bastion-hub`
   - **Resourcegroep**: `rg-hub-spoke-lab`
   - **Regio**: `East US`
   - **SKU**: `Standard`
   - **Beschikbaarheidszones**: Geconfigureerd als **Zone-redundant** (`Zones: 1, 2, 3`).

![06-pip-bastion-zone-redundant](../Screenshots/06-pip-bastion-zone-redundant.png)

2. **Koppeling aan Azure Bastion**:
   - Bij het opnieuw starten van de Bastion-implementatie is gekozen voor *Bestaande gebruiken* en werd `pip-bastion-hub` geselecteerd.
   - De deployment slaagde direct met de status `Succeeded` en de zone-toewijzing `2, 3, 1`:

![07-bastion-deployed-success](../Screenshots/07-bastion-deployed-success.png)

---

### 4. Operational Best Practice & Lessons Learned
- **High Availability by Default**: Publieke gateways en ingress-punten moeten in enterprise omgevingen altijd zone-redundant worden uitgerold. Als een heel datacenter (zone) uitvalt, blijft Bastion bereikbaar via de overige zones.
- **Infrastructure as Code (IaC) Tip**: Bij het definiëren van Public IP's in Bicep of Terraform moet altijd de eigenschap `zones: ['1', '2', '3']` worden meegegeven in regio's die zones ondersteunen.

---

## 📌 Scenario 2: Niet-transitieve Routering & Spoke-to-Spoke Isolatie

### 1. Incidentbeschrijving & Testscenario
In een Hub-and-Spoke architectuur is het een vereiste dat ontwikkelomgevingen (Dev) nooit direct kunnen communiceren met productieomgevingen (Prod), om te voorkomen dat foutieve code of kwetsbaarheden overspringen.

Vanuit `vm-prod-01` (`10.1.1.4`) is een connectiviteitstest uitgevoerd naar `vm-dev-01` (`10.2.1.4`):

```bash
azureuser@vm-prod-01:~$ ping -c 4 10.2.1.4
PING 10.2.1.4 (10.2.1.4) 56(84) bytes of data.

--- 10.2.1.4 ping statistics ---
4 packets transmitted, 0 received, 100% packet loss, time 3078ms
```

![08-bastion-ssh-spoke-isolation-test](../Screenshots/08-bastion-ssh-spoke-isolation-test.png)

---

### 2. Technische Verklaring (Waarom faalt de ping?)
Veel engineers verwachten ten onrechte dat verkeer van `vnet-spoke-prod` via `vnet-hub` automatisch doorstroomt naar `vnet-spoke-dev`. Dit gebeurt echter **niet**:
1. **Non-Transitive Peering**: VNet Peering koppelt alleen de twee specifieke VNets aan elkaar (`vnet-hub` ↔ `vnet-spoke-prod` en `vnet-hub` ↔ `vnet-spoke-dev`).
2. **Ontbrekende Routing Tabel**: `vnet-spoke-prod` heeft geen routeringsregel voor het subnet `10.2.0.0/16`. De netwerkinterface dropt het verkeer omdat er geen geldige next-hop bekend is.
3. **Beveiligingswinst**: Deze standaardgedrag van Azure fungeert als een natuurlijke netwerkisolatie (Air Gapping op SDN-niveau).

---

### 3. Hoe zou communicatie WEL mogelijk gemaakt worden?
Mocht er in de toekomst wél gecontroleerde communicatie nodig zijn tussen spokes, dan vereist dit de volgende stappen:
- Plaatsen van een **Network Virtual Appliance (NVA)** of **Azure Firewall** in het `vnet-hub`.
- Aanmaken van een **User Defined Route (UDR)** / Route Table op `snet-prod` en `snet-dev` met een regel:
  - Adresvoorvoegsel: `10.2.0.0/16`
  - Volgende hop: Virtueel apparaat (IP van de Azure Firewall in de Hub).
- Inschakelen van **Gateway Transit / Allow Forwarded Traffic** op de VNet Peerings.
- Firewallregels configureren die alleen specifiek verkeer (bijv. poort 443 of een database-poort) inspecteren en doorlaten.
