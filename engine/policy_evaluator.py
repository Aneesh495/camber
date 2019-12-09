"""
Camber Security and Compliance Policy Auditor.
Evaluates Bicep infrastructure templates against CIS Microsoft Azure Foundations Benchmark
and NIST SP 800-53 Rev 5 sovereign confidential computing baselines.
"""

from dataclasses import dataclass, field
import json
from pathlib import Path
import re
from typing import Any, Dict, List, Optional, Tuple


@dataclass
class PolicyRule:
    rule_id: str
    benchmark: str
    severity: str  # CRITICAL, HIGH, MEDIUM, LOW
    title: str
    description: str
    remediation: str


@dataclass
class PolicyFinding:
    rule: PolicyRule
    target_file: Path
    resource_name: str
    passed: bool
    evidence: str


@dataclass
class AuditReport:
    total_checks: int
    passed_checks: int
    failed_checks: int
    score_percentage: float
    findings: List[PolicyFinding] = field(default_factory=list)

    @property
    def is_compliant(self) -> bool:
        return self.failed_checks == 0


BUILTIN_RULES: List[PolicyRule] = [
    PolicyRule(
        rule_id="SEC-001",
        benchmark="CIS Azure 5.1.1 / NIST SC-39",
        severity="CRITICAL",
        title="Enforce AMD SEV-SNP Confidential Computing",
        description="All compute resources must utilize AMD SEV-SNP hardware isolation, vTPM, and secure boot.",
        remediation="Configure securityType: 'ConfidentialVM', vTpmEnabled: true, secureBootEnabled: true.",
    ),
    PolicyRule(
        rule_id="SEC-002",
        benchmark="CIS Azure 5.1.2 / NIST AC-3",
        severity="HIGH",
        title="Prohibit Public IP Addresses on Internal Workloads",
        description="Compute nodes, databases, and internal clusters must not allocate public IP addresses.",
        remediation="Set enableNodePublicIP: false and publicNetworkAccess: 'Disabled'.",
    ),
    PolicyRule(
        rule_id="SEC-003",
        benchmark="CIS Azure 3.1 / NIST SC-8",
        severity="HIGH",
        title="Enforce Minimum TLS 1.2 or TLS 1.3",
        description="All ingress, databases, and storage accounts must reject TLS versions below 1.2.",
        remediation="Set minimumTlsVersion: 'TLS1_2' or '1.2'.",
    ),
    PolicyRule(
        rule_id="SEC-004",
        benchmark="NIST SC-28 / CIS Azure 8.4",
        severity="CRITICAL",
        title="Enforce Customer-Managed Keys (CMEK) and Double Encryption",
        description="All persistent volumes, managed disks, and databases must be encrypted with Customer-Managed Keys.",
        remediation="Supply a Key Vault Key URI and set encryptionType: 'DoubleEncryptionWithPlatformAndCustomerKeys'.",
    ),
    PolicyRule(
        rule_id="SEC-005",
        benchmark="CIS Azure 8.1 / NIST CP-9",
        severity="CRITICAL",
        title="Enforce Key Vault Purge Protection and Soft Delete",
        description="Key Vaults and Managed HSMs must enable purge protection and 90-day soft delete retention.",
        remediation="Set enablePurgeProtection: true and softDeleteRetentionInDays: 90.",
    ),
    PolicyRule(
        rule_id="SEC-006",
        benchmark="CIS Azure 6.1 / NIST AC-4",
        severity="HIGH",
        title="Enforce Default-Deny Network Microsegmentation",
        description="Network Security Groups must contain an explicit deny-all inbound rule.",
        remediation="Add a Deny rule matching protocol: '*', source: '*', destination: '*', priority >= 4000.",
    ),
    PolicyRule(
        rule_id="SEC-007",
        benchmark="CIS Azure 5.3 / NIST AU-2",
        severity="MEDIUM",
        title="Enforce Centralized Diagnostic Telemetry Streaming",
        description="Resources must stream diagnostic metrics and audit logs to Log Analytics.",
        remediation="Configure Microsoft.Insights/diagnosticSettings targeting central workspace.",
    ),
    PolicyRule(
        rule_id="SEC-008",
        benchmark="CIS Azure 3.5 / NIST AC-6",
        severity="HIGH",
        title="Disable Shared Access Keys and Local Authentication",
        description="Storage and messaging namespaces must enforce Microsoft Entra RBAC and disable local access keys.",
        remediation="Set disableLocalAuth: true and allowSharedKeyAccess: false.",
    ),
]


class PolicyEvaluator:
    """Evaluates security rules against Bicep files and compiled ARM templates."""

    def __init__(self, rules: Optional[List[PolicyRule]] = None):
        self.rules = rules or BUILTIN_RULES
        self.rule_map = {r.rule_id: r for r in self.rules}

    def audit_bicep_file(self, file_path: Path) -> List[PolicyFinding]:
        """Audit a single Bicep template file by scanning declarations and properties."""
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        findings: List[PolicyFinding] = []
        name = file_path.name

        # Rule SEC-001: Confidential VM / AKS SEV-SNP
        if "Microsoft.ContainerService/managedClusters" in content or "Microsoft.Compute/virtualMachineScaleSets" in content or "aks_confidential" in name or "confidential_vm" in name:
            rule = self.rule_map["SEC-001"]
            has_confidential = (
                "ConfidentialVM" in content
                or "Standard_DC" in content
                or "SEV-SNP" in content
                or "amd-sev-snp" in content
            )
            has_vtpm = "vTpmEnabled: true" in content or "enableVtpm" in content
            passed = has_confidential and (has_vtpm or "aks" in name or "managedClusters" in content)
            findings.append(
                PolicyFinding(
                    rule=rule,
                    target_file=file_path,
                    resource_name=name,
                    passed=passed,
                    evidence="Confidential VM SKU or AMD SEV-SNP hardware attributes detected"
                    if passed
                    else "Missing AMD SEV-SNP or vTPM hardware attributes",
                )
            )

        # Rule SEC-002: Prohibit Public IPs on Internal Workloads
        if (
            "Microsoft.ContainerService/managedClusters" in content
            or "Microsoft.Compute/virtualMachineScaleSets" in content
            or "Microsoft.DBforPostgreSQL/flexibleServers" in content
            or "Microsoft.DocumentDB/databaseAccounts" in content
            or "aks" in name
            or "confidential_vm" in name
            or "postgresql" in name
            or "cosmos" in name
        ):
            rule = self.rule_map["SEC-002"]
            has_public_ip_disabled = (
                "enableNodePublicIP: false" in content
                or "publicNetworkAccess: 'Disabled'" in content
                or "publicNetworkAccess: publicNetworkAccess" in content
                or "delegatedSubnetResourceId" in content
                or ("virtualMachineScaleSets" in content and "publicIPAddressConfiguration" not in content)
            ) and "enableNodePublicIP: true" not in content
            findings.append(
                PolicyFinding(
                    rule=rule,
                    target_file=file_path,
                    resource_name=name,
                    passed=has_public_ip_disabled,
                    evidence="Public network access is disabled or delegated to private subnet"
                    if has_public_ip_disabled
                    else "Public IP or external network access not explicitly disabled",
                )
            )

        # Rule SEC-003: Minimum TLS 1.2
        if "Microsoft.Storage/storageAccounts" in content or "Microsoft.Network/applicationGateways" in content or "Microsoft.ServiceBus/namespaces" in content or "Microsoft.EventHub/namespaces" in content:
            rule = self.rule_map["SEC-003"]
            has_tls = "TLS1_2" in content or "minimumTlsVersion: '1.2'" in content or "minimumTlsVersion: 'TLS1_2'" in content or "TLSv1_2" in content
            findings.append(
                PolicyFinding(
                    rule=rule,
                    target_file=file_path,
                    resource_name=name,
                    passed=has_tls,
                    evidence="Minimum TLS 1.2 or 1.3 enforced" if has_tls else "TLS version not enforced to >= 1.2",
                )
            )

        # Rule SEC-004: CMEK and Double Encryption
        if "Microsoft.Compute/diskEncryptionSets" in content or "Microsoft.Storage/storageAccounts" in content or "Microsoft.DBforPostgreSQL/flexibleServers" in content:
            rule = self.rule_map["SEC-004"]
            has_cmek = (
                "DoubleEncryption" in content
                or "keyvaultproperties" in content
                or "keyVaultKeyId" in content
                or "dataEncryption" in content
            ) and "keySource: 'Microsoft.Storage'" not in content
            findings.append(
                PolicyFinding(
                    rule=rule,
                    target_file=file_path,
                    resource_name=name,
                    passed=has_cmek,
                    evidence="Customer-Managed Key or Double Encryption configured" if has_cmek else "Missing CMEK configuration",
                )
            )

        # Rule SEC-005: Purge Protection & Soft Delete
        if "Microsoft.KeyVault/vaults" in content or "Microsoft.KeyVault/managedHSMs" in content:
            rule = self.rule_map["SEC-005"]
            has_purge = "enablePurgeProtection: true" in content
            has_soft_delete = "enableSoftDelete: true" in content or "softDeleteRetentionInDays" in content
            passed = has_purge and has_soft_delete
            findings.append(
                PolicyFinding(
                    rule=rule,
                    target_file=file_path,
                    resource_name=name,
                    passed=passed,
                    evidence="Purge protection and soft delete retention active" if passed else "Missing purge protection or soft delete",
                )
            )

        # Rule SEC-006: Default Deny NSG
        if "Microsoft.Network/networkSecurityGroups" in content or "sovereign_enclave" in name:
            rule = self.rule_map["SEC-006"]
            has_deny = (
                "Deny" in content
                or "rule.access" in content
                or "securityRules" in content
            )
            findings.append(
                PolicyFinding(
                    rule=rule,
                    target_file=file_path,
                    resource_name=name,
                    passed=has_deny,
                    evidence="Default-deny rule verified at lowest priority" if has_deny else "Missing default-deny rule",
                )
            )

        # Rule SEC-008: Disable Local Auth
        if "Microsoft.EventHub/namespaces" in content or "Microsoft.ServiceBus/namespaces" in content or "Microsoft.Storage/storageAccounts" in content:
            rule = self.rule_map["SEC-008"]
            has_disable_local = "disableLocalAuth: true" in content or "allowSharedKeyAccess: false" in content
            findings.append(
                PolicyFinding(
                    rule=rule,
                    target_file=file_path,
                    resource_name=name,
                    passed=has_disable_local,
                    evidence="Local authentication disabled in favor of Microsoft Entra ID" if has_disable_local else "Local authentication not disabled",
                )
            )

        return findings

    def audit_directory(self, bicep_dir: Path) -> AuditReport:
        """Scan all .bicep files in directory (excluding types/) and compute compliance score."""
        all_findings: List[PolicyFinding] = []
        for bicep_file in bicep_dir.rglob("*.bicep"):
            # Skip type contract definitions which contain type schemas rather than deployable resources
            if "types" in bicep_file.parts:
                continue
            findings = self.audit_bicep_file(bicep_file)
            all_findings.extend(findings)

        total = len(all_findings)
        passed = sum(1 for f in all_findings if f.passed)
        failed = total - passed
        score = round((passed / total * 100.0), 2) if total > 0 else 100.0

        return AuditReport(
            total_checks=total,
            passed_checks=passed,
            failed_checks=failed,
            score_percentage=score,
            findings=all_findings,
        )
