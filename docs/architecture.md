# Camber Architectural Specification

## 1. System Philosophy and Design Invariants

Camber is an autonomous, planetary-scale cloud infrastructure operating fabric and zero-trust confidential enclave hypervisor implemented in declarative Azure Bicep and native Python. 

The project name originates from civil and aeronautical engineering: camber represents the intentional upward curvature built into structural girders to counteract gravitational deflection under severe loading. In distributed infrastructure engineering, Camber ensures that multi-region cloud topologies maintain strict security invariants, cryptographic isolation, and execution determinism under heavy operational stress, regional outages, and confidential computation demands.

Camber enforces six non-negotiable architectural invariants:

1. **Hardware-Enforced Cryptographic Isolation**: Zero unencrypted bytes in flight, in memory, or at rest. All computational workloads run within AMD SEV-SNP (Secure Encrypted Virtualization with Secure Nested Paging) confidential execution enclaves backed by virtual Trusted Platform Modules (vTPM) and remote hardware attestation.
2. **Deterministic Zero-Trust Perimeter**: Complete absence of public IP allocations on internal compute nodes, databases, and messaging fabrics. All inter-service and data plane communication routes exclusively through Private Endpoints and force-tunneled User-Defined Routes (UDRs).
3. **Planetary Multi-Region Resilience**: Continental active-active data replication with Bounded Staleness and Strong consistency models across East US, West Europe, and Southeast Asia hubs via Azure Virtual WAN.
4. **Autonomous Policy Enforcement**: Declarative Azure Policy initiatives and custom definitions that evaluate compliance at compile time and deploy time, preventing non-compliant resource provisioning before execution.
5. **Discrete-Event Scheduling Verification**: Mathematical discrete-event simulation of Azure Resource Manager (ARM) engine deployment queues, modeling rate-limiting quotas, transient HTTP 429 throttling, and exponential backoff dynamics.
6. **Carbon-Aware Cloud Economics**: Regional grid carbon intensity tracking ($gCO_2e/kWh$) coupled with SKU power dissipation modeling to optimize geographical workload placement for minimum carbon emissions and cost.

---

## 2. Multi-Tier System Topology

```
+====================================================================================================+
|                                    CAMBER SOVEREIGN SYSTEM MESH                                    |
+====================================================================================================+

 [ Tier 1: Ingress & Planetary Transit Mesh ]
 +--------------------------------------------------------------------------------------------------+
 | Azure Virtual WAN (vWAN Standard)                                                                |
 |   ├── Hub East US (10.100.0.0/24)                                                                |
 |   ├── Hub West Europe (10.101.0.0/24)                                                            |
 |   └── Hub Southeast Asia (10.102.0.0/24)                                                         |
 |                                                                                                  |
 | Perimeter Inspection & Reverse Proxy:                                                            |
 |   ├── Application Gateway v2 (WAF v3 OWASP CRS 3.2, Bot Manager, TLS 1.3, mTLS)                  |
 |   ├── Azure Firewall Premium (TLS Inspection, IDPS Deep Packet Filtering, FQDN Rules)            |
 |   └── Outbound NAT Gateway (Static Public IP Prefix Egress, Zero Inbound Exposure)               |
 +--------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
 [ Tier 2: Cryptographic Security & Hardware Attestation ]
 +--------------------------------------------------------------------------------------------------+
 | Azure Managed HSM (Dedicated FIPS 140-2 Level 3 Hardware Security Module, Standard_B1)           |
 | Key Vault Premium (Purge Protection, 90-Day Soft Delete, RBAC Data Plane Authorization)          |
 | Microsoft Azure Attestation (MAA Isolated Attestation Policy Provider for AMD SEV-SNP)           |
 | Disk Encryption Sets (Double Encryption with Platform and Customer-Managed Keys CMEK)            |
 +--------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
 [ Tier 3: Heterogeneous Confidential Compute ]
 +--------------------------------------------------------------------------------------------------+
 | Confidential AKS Cluster:                                                                        |
 |   ├── CNI: Native Cilium eBPF Overlay with Kernel Microsegmentation Network Policy               |
 |   ├── System Pool: 3x Standard_D4ds_v5 (Azure Linux CBL-Mariner, Ephemeral OS Disks)             |
 |   ├── Enclave Worker Pool: 3-20x Standard_DC4as_v5 (AMD SEV-SNP, vTPM, Secure Boot)             |
 |   ├── Security: Microsoft Entra Workload Identity (OIDC Federation), Key Vault CSI Provider      |
 |                                                                                                  |
 | Confidential VM Scale Sets: Standard_DC4as_v5 / Standard_DC8as_v5 (Rolling Upgrades, Zero PIP)   |
 | Azure Container Apps: Managed Environment, Internal VNet, Dapr State/PubSub, KEDA Autoscaling   |
 | Azure Batch Account: High-Performance Confidential Computing Pool with Inter-Node Fabric         |
 +--------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
 [ Tier 4: Sovereign Resilient Data Plane ]
 +--------------------------------------------------------------------------------------------------+
 | Active-Active Cosmos DB: Multi-Region Write, Bounded Staleness / Strong Consistency, CMEK        |
 | PostgreSQL Flexible Server: Zone-Redundant High Availability, Delegated Subnet, Private DNS      |
 | ADLS Gen2 Storage: Hierarchical Namespace, WORM Immutability Policies, TLS 1.3 Minimum          |
 | Event Hubs Premium: Kafka Protocol, Dedicated Cluster Capture to ADLS Gen2 Avro Archive          |
 | Service Bus Premium: Partitioned Message Queues, Dead-Letter Forwarding, Entra RBAC Only        |
 +--------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
 [ Tier 5: Telemetry, Observability & Continuous Governance ]
 +--------------------------------------------------------------------------------------------------+
 | Centralized Log Analytics: 730-Day Retention, Dedicated Table Data Export to Cold Storage        |
 | Azure Monitor Data Collection Rules (DCR): Linux Syslog, Security Events, Kernel Perf Counters   |
 | Azure Policy Initiatives: CIS Azure Benchmark v2.0, NIST SP 800-53 Rev 5, AMD SEV-SNP Guardrails|
 | Metric Alerts: Dynamic P99 Latency, HTTP 429 Throttling, CPU Saturation, Error Budget Exhaustion |
 +--------------------------------------------------------------------------------------------------+
```

---

## 3. Dependency Graph and Topological Execution Stages

The infrastructure dependency Directed Acyclic Graph (DAG) partitions into four deterministic parallel deployment stages computed via Kahn's algorithm:

```
Stage 1 (Independent Roots, 7 Concurrent Deployments):
  ├── Central Log Analytics Workspace
  ├── Fabric User-Assigned Managed Identity
  ├── Dedicated FIPS 140-2 Level 3 Managed HSM Pool
  ├── Microsoft Azure Attestation Provider
  ├── Microsegmentation Network Security Group
  ├── Force-Tunneling User-Defined Route Table
  └── Planetary Azure Virtual WAN

Stage 2 (Identity & Network Bound, 5 Concurrent Deployments):
  ├── Azure Monitor Data Collection Rule (depends on Log Analytics)
  ├── Hardened Key Vault (depends on Managed Identity)
  ├── Planetary Virtual Hubs (depends on Virtual WAN)
  ├── Sovereign Virtual Network (depends on NSG, Route Table)
  └── Active-Active Cosmos DB (depends on Log Analytics)

Stage 3 (Core Gateways & Data Services, 9 Concurrent Deployments):
  ├── Disk Encryption Set (depends on Key Vault)
  ├── Private DNS Zones (depends on Virtual Network)
  ├── Hardened ADLS Gen2 Storage (depends on Virtual Network, Key Vault)
  ├── Azure Firewall Premium (depends on Virtual Network)
  ├── Application Gateway v2 WAF (depends on Virtual Network)
  ├── Outbound NAT Gateway (depends on Virtual Network)
  ├── Container Apps Environment (depends on Virtual Network, Log Analytics)
  ├── Event Hubs Kafka Namespace (depends on Virtual Network)
  └── Service Bus Premium Namespace (depends on Virtual Network)

Stage 4 (Workload Enclaves & Relational Databases, 4 Concurrent Deployments):
  ├── Confidential AKS Cluster (depends on Virtual Network, Disk Encryption Set, Log Analytics)
  ├── Confidential VM Scale Set (depends on Virtual Network, Disk Encryption Set)
  ├── PostgreSQL Flexible Server (depends on Virtual Network, Private DNS)
  └── Azure Batch HPC Account (depends on Virtual Network, Storage Account)
```

The Critical Path Method (CPM) identifies `Fabric Managed Identity -> Hardened Key Vault -> Disk Encryption Set -> Confidential AKS Cluster` as the pacing critical sequence, dictating an estimated deployment latency of 695 seconds under nominal cloud scheduling conditions.
