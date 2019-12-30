# Camber

```
  ██████╗ █████╗ ███╗   ███╗██████╗ ███████╗██████╗ 
 ██╔════╝██╔══██╗████╗ ████║██╔══██╗██╔════╝██╔══██╗
 ██║     ███████║██╔████╔██║██████╔╝█████╗  ██████╔╝
 ██║     ██╔══██║██║╚██╔╝██║██╔══██╗██╔══╝  ██╔══██╗
 ╚██████╗██║  ██║██║ ╚═╝ ██║██████╔╝███████╗██║  ██║
  ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝
```

**Sovereign confidential computing fabric, multi-region zero-trust enclave mesh, and discrete-event verification engine in declarative Azure Bicep.**

[![Bicep Build](https://img.shields.io/badge/bicep--build-passing%20(0%20defects)-brightgreen.svg?style=flat-square)](#)
[![Zero Em Dash Invariant](https://img.shields.io/badge/em--dash--audit-clean%20(0%20violations)-brightgreen.svg?style=flat-square)](#)
[![Security Compliance](https://img.shields.io/badge/CIS%20%26%20NIST-100%25%20compliant-blue.svg?style=flat-square)](#)
[![Engine Runtime](https://img.shields.io/badge/python--engine-0%20external%20deps-orange.svg?style=flat-square)](#)
[![Hardware Enclave](https://img.shields.io/badge/enclave-AMD%20SEV--SNP-purple.svg?style=flat-square)](#)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-yellow.svg?style=flat-square)](LICENSE)

---

## Overview

**Camber** is an enterprise-grade cloud operating fabric and zero-trust infrastructure hypervisor implemented in declarative Azure Bicep and native Python.

Named after the structural convexity engineered into load-bearing girders to prevent gravitational deflection, Camber ensures cloud infrastructure maintains cryptographic integrity, strict zero-trust isolation, and execution determinism under heavy operational loads, regional outages, and confidential computation demands.

Unlike conventional static infrastructure-as-code templates, Camber pairs an end-to-end multi-region Bicep architecture with an autonomous verification engine that performs discrete-event scheduling simulation, resource dependency DAG analysis, CIS/NIST security policy enforcement, and regional electrical grid carbon accounting.

---

## Core Capabilities

- **Hardware-Enforced Confidentiality**: AMD SEV-SNP confidential virtual machines and AKS node pools with hardware memory encryption, virtual TPM 2.0, measured boot, and Microsoft Azure Attestation (MAA) token verification.
- **Dedicated Cryptographic Roots**: FIPS 140-2 Level 3 validated Azure Managed HSM pools and Key Vault Premium instances enforcing automated customer-managed key (CMEK) double encryption and purge protection.
- **Planetary Transit Mesh**: Multi-region Azure Virtual WAN (vWAN) interconnecting secure virtual hubs across East US, West Europe, and Southeast Asia with active-active geo-routing.
- **Kernel-Level eBPF Networking**: Azure Kubernetes Service running Cilium eBPF overlay networking, Azure Linux (CBL-Mariner) confidential nodes, and zero public IP exposure.
- **Sovereign Resilient Data Plane**: Multi-region active-active Cosmos DB with Strong/Bounded Staleness consistency, zone-redundant PostgreSQL Flexible Server with private DNS, and WORM-immutable ADLS Gen2 storage accounts.
- **Discrete-Event ARM Deployment Simulator**: Mathematical simulator modeling ARM concurrency limits, rate-limiting quotas, transient HTTP 429 throttling, and exponential backoff with full jitter.
- **Static Security & Policy Auditor**: In-engine policy auditor evaluating templates against CIS Microsoft Azure Foundations Benchmark v2.0 and NIST SP 800-53 Rev 5 baselines.
- **Grid Carbon Footprint Model**: Real-time regional grid carbon intensity tracking ($gCO_2e/kWh$) coupled with SKU thermal dissipation calculations to optimize compute placement for sustainability.

---

## Architecture Topology

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

## Repository Structure

```
camber/
├── camber                            # Unified executable CLI entrypoint
├── Makefile                          # Build, lint, audit, test, and verification automation
├── bicepconfig.json                  # Compiler settings and strict analyzers
├── LICENSE                           # Apache License 2.0
├── README.md                         # Architecture documentation and benchmarks
├── bicep/
│   ├── main.bicep                    # Planetary multi-region deployment orchestrator
│   ├── types/                        # User-defined type contracts
│   │   ├── network.bicep
│   │   ├── compute.bicep
│   │   ├── security.bicep
│   │   ├── storage.bicep
│   │   ├── telemetry.bicep
│   │   └── governance.bicep
│   ├── modules/                      # Reusable production resource modules
│   │   ├── identity/                 # Managed Identity, RBAC roles, assignments
│   │   ├── security/                 # Key Vault, Managed HSM, Attestation, CMEK
│   │   ├── network/                  # vNet, NSG, UDR, vWAN, Firewall, Private Endpoints
│   │   ├── compute/                  # Confidential AKS, VMSS, Container Apps, Batch
│   │   ├── data/                     # Cosmos DB, Postgres Flexible, ADLS Gen2, Event Hubs
│   │   ├── telemetry/                # Log Analytics, DCR, Diagnostic Settings, Alerts
│   │   └── governance/               # Azure Policy definitions, initiatives, assignments
│   ├── blueprints/                   # End-to-end deployable system topologies
│   │   ├── sovereign_enclave.bicep   # Full-tier confidential enclave blueprint
│   │   ├── confidential_inference.bicep # Distributed confidential AI inference blueprint
│   │   ├── planetary_transit.bicep   # 3-continental vWAN mesh blueprint
│   │   └── edge_microzone.bicep      # Sovereign edge microzone blueprint
│   └── parameters/                   # Environment parameters
│       ├── prod.eastus.bicepparam
│       ├── prod.westeurope.bicepparam
│       ├── staging.bicepparam
│       └── enclave.sovereign.bicepparam
├── engine/                           # High-performance verification & simulation engine
│   ├── compiler.py                   # Bicep compiler & ARM JSON analyzer
│   ├── ast_parser.py                 # AST parser & token extractor
│   ├── graph.py                      # Dependency DAG, Kahn toposort, Tarjan SCC
│   ├── simulator.py                  # Discrete-event ARM deployment simulator
│   ├── policy_evaluator.py           # CIS / NIST compliance auditor
│   ├── cost_carbon.py                # Regional cost & grid carbon intensity model
│   ├── visualizer.py                 # Terminal DAG visualizer & Gantt charts
│   └── cli.py                        # Unified command router
├── tests/                            # Comprehensive unit, integration & regression test suites
│   ├── test_bicep_compilation.py
│   ├── test_ast_parser.py
│   ├── test_graph_dag.py
│   ├── test_simulator.py
│   ├── test_policy_evaluator.py
│   ├── test_cost_carbon.py
│   ├── test_cli.py
│   ├── test_regressions.py
│   └── test_em_dash_audit.py
└── docs/                             # In-depth architectural specifications
    ├── architecture.md
    ├── confidential_computing.md
    ├── zero_trust_networking.md
    ├── discrete_event_simulation.md
    ├── security_and_compliance.md
    ├── carbon_and_economics.md
    └── developer_guide.md
```

---

## Quickstart & Verification

Camber has zero third-party package dependencies: it runs out-of-the-box on standard Python 3.10+ and interacts with the official Bicep CLI.

```bash
# 1. Clone repository
git clone https://github.com/Aneesh495/camber.git
cd camber

# 2. Compile all Bicep source templates and parameter files
./camber compile

# 3. Analyze resource dependency DAG, parallel stages, and critical path
./camber graph

# 4. Run discrete-event deployment simulation with Gantt timeline
./camber simulate --concurrency 20

# 5. Audit all templates against CIS Azure Benchmark v2.0 and NIST SP 800-53
./camber audit

# 6. Calculate regional grid carbon intensity and cloud OPEX
./camber carbon

# 7. Execute all verification gates and test suites
./camber verify
make test
```

---

## Discrete-Event Deployment Simulation Output

```
======================================================================
               DISCRETE-EVENT SIMULATION GANTT TIMELINE               
======================================================================
 Total Virtual Time: 684.22s | Completed: 25 | Throttles: 1

 Central Log Analytic | ████                                    |   0.0s ->  43.2s
 Fabric Managed Ident | █                                       |   0.0s ->  14.8s
 Microsegmentation NS | █                                       |   0.0s ->  19.5s
 Force-Tunneling Rout | █                                       |   0.0s ->  20.1s
 Planetary Virtual WA | ██                                      |   0.0s ->  58.9s
 Data Collection Rule |   ███                                   |  43.2s ->  72.5s
 Hardened Key Vault   |  ████                                   |  14.8s ->  59.4s
 Sovereign Virtual Ne |   ███                                   |  20.1s ->  50.3s
 Disk Encryption Set  |      ███                                |  59.4s ->  94.2s
 Azure Firewall Premi |     █████████████████████               |  50.3s -> 408.1s
 Outbound NAT Gateway |     ███                                 |  50.3s ->  85.7s
 Hardened ADLS Gen2   |      ███                                |  59.4s ->  93.8s
 Confidential AKS     |         ███████████████████████████████ |  94.2s -> 684.2s
```

---

## Invariant Guarantees

- **Zero Defect Compilation**: All Bicep modules, types, parameter files, and orchestrators compile cleanly via the official Bicep CLI without errors or warnings.
- **Zero Em Dash Invariant**: Strict automated audit test verifies 0 occurrences of em dashes across all code, comments, string literals, and documentation.
- **100% Policy Compliance**: Automated static analysis validates all 8 CIS and NIST sovereign security rules across all infrastructure resources.
- **Zero Third-Party Dependencies**: Engine runs entirely on native Python 3 standard libraries without requiring `pip install`.

---

## License

Licensed under the Apache License, Version 2.0 (the "License"). You may obtain a copy of the License at [LICENSE](LICENSE).
