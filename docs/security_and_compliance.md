# Security & Compliance Specification

## 1. Regulatory Framework Alignments

Camber maps every infrastructure module to specific controls within the CIS Microsoft Azure Foundations Benchmark v2.0 and NIST SP 800-53 Rev 5 catalog.

| Control ID | Framework Reference | Severity | Description | Camber Implementation |
|---|---|---|---|---|
| **SEC-001** | CIS 5.1.1 / NIST SC-39 | CRITICAL | AMD SEV-SNP Confidential Computing | `confidential_vm_ss.bicep`, `aks_confidential_cluster.bicep` |
| **SEC-002** | CIS 5.1.2 / NIST AC-3 | HIGH | Prohibit Public IP on Workloads | Enforced across all internal compute and database modules |
| **SEC-003** | CIS 3.1 / NIST SC-8 | HIGH | Enforce TLS 1.2 or TLS 1.3 | Configured on Storage, App Gateway, Service Bus, Event Hubs |
| **SEC-004** | NIST SC-28 / CIS 8.4 | CRITICAL | Customer-Managed Keys (CMEK) | Double encryption with Disk Encryption Sets and Key Vault |
| **SEC-005** | CIS 8.1 / NIST CP-9 | CRITICAL | Key Vault Purge Protection | 90-day soft delete retention and purge protection on Key Vaults |
| **SEC-006** | CIS 6.1 / NIST AC-4 | HIGH | Default-Deny Microsegmentation | Priority 4096 deny-all inbound rules on all NSG perimeters |
| **SEC-007** | CIS 5.3 / NIST AU-2 | MEDIUM | Diagnostic Telemetry Streaming | Automated diagnostic settings to central Log Analytics |
| **SEC-008** | CIS 3.5 / NIST AC-6 | HIGH | Disable Local Shared Keys | Microsoft Entra ID RBAC enforced, local keys disabled |

---

## 2. Automated Static Policy Auditing

The Camber engine includes an automated security auditor (`camber audit`) that inspects template syntax, properties, and declarations directly, certifying that templates satisfy 100% of controls prior to deployment.
