# Zero-Trust Networking & Transit Mesh Specification

## 1. Network Topology & Microsegmentation Architecture

Camber implements a zero-trust network topology designed to eliminate lateral movement, unauthorized data exfiltration, and direct internet exposure.

```
+===================================================================================+
|                              PERIMETER INGRESS & TRANSIT                          |
+===================================================================================+
                                         |
               +-------------------------+-------------------------+
               |                                                   |
               v                                                   v
   +-----------------------+                           +-----------------------+
   | Application Gateway   |                           | Azure Firewall        |
   | v2 WAF (HTTP/2, mTLS) |                           | Premium (IDPS, TLS)   |
   +-----------------------+                           +-----------------------+
               |                                                   |
               +-------------------------+-------------------------+
                                         | (Inspected Egress / Ingress)
                                         v
+===================================================================================+
|                                CORE VIRTUAL NETWORK                               |
+===================================================================================+
  Subnets (Isolated via NSGs and UDRs):
   ├── AzureFirewallSubnet (10.240.0.0/26)
   ├── AksClusterSubnet (10.240.1.0/24) [Cilium eBPF Overlay 10.241.0.0/16]
   ├── DatabaseSubnet (10.240.2.0/24) [PostgreSQL Flexible Delegation]
   └── PrivateEndpointSubnet (10.240.3.0/24) [Private Link NICs]
```

---

## 2. Force-Tunneling & Traffic Steering

All subnets are bound to User-Defined Route (UDR) tables that disable BGP route propagation and direct `0.0.0.0/0` outbound traffic to the private IP of Azure Firewall Premium (`10.240.0.4`). 

Direct outbound internet egress from compute instances is strictly impossible. Outbound traffic to allowed external APIs must match explicit FQDN application rules evaluated by Azure Firewall.

---

## 3. Private DNS Zone Resolution

All Azure PaaS dependencies communicate over Private Endpoints with automated Private DNS Zone linking:
- `privatelink.vaultcore.azure.net` (Key Vault & Managed HSM)
- `privatelink.blob.core.windows.net` (ADLS Gen2 Storage)
- `privatelink.postgres.database.azure.com` (PostgreSQL Flexible Server)
- `privatelink.documents.azure.com` (Cosmos DB)
- `privatelink.servicebus.windows.net` (Service Bus & Event Hubs)

DNS lookups return RFC 1918 private IP addresses exclusively within `10.240.3.0/24`.
