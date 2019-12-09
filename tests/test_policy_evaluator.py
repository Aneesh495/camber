"""
Unit and compliance tests for the CIS and NIST security policy auditor.
"""

from pathlib import Path
import tempfile
import unittest

from engine.policy_evaluator import PolicyEvaluator, BUILTIN_RULES


class TestPolicyEvaluator(unittest.TestCase):
    """Test suite verifying policy audit rules and violation detection."""

    def setUp(self):
        self.evaluator = PolicyEvaluator()

    def test_repository_modules_are_compliant(self):
        """Verify the production Bicep modules achieve 100% compliance across CIS/NIST rules."""
        report = self.evaluator.audit_directory(Path("bicep"))
        self.assertEqual(report.failed_checks, 0, f"Expected 0 failures, got: {[f.rule.rule_id for f in report.findings if not f.passed]}")
        self.assertEqual(report.score_percentage, 100.0)

    def test_detect_insecure_public_ip_violation(self):
        """Verify evaluator catches non-compliant AKS cluster with public node IPs."""
        with tempfile.NamedTemporaryFile("w", suffix=".bicep", delete=False) as f:
            f.write("""
            resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
              name: 'insecure-aks'
              location: 'eastus'
              properties: {
                agentPoolProfiles: [
                  {
                    name: 'nodepool'
                    enableNodePublicIP: true
                  }
                ]
              }
            }
            """)
            temp_path = Path(f.name)

        try:
            findings = self.evaluator.audit_bicep_file(temp_path)
            # Should have an SEC-002 finding that failed
            sec002_findings = [f for f in findings if f.rule.rule_id == "SEC-002"]
            self.assertEqual(len(sec002_findings), 1)
            self.assertFalse(sec002_findings[0].passed)
        finally:
            temp_path.unlink()

    def test_detect_insecure_missing_cmek_violation(self):
        """Verify evaluator catches storage account without CMEK."""
        with tempfile.NamedTemporaryFile("w", suffix=".bicep", delete=False) as f:
            f.write("""
            resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
              name: 'insecurestorage'
              location: 'eastus'
              sku: { name: 'Standard_LRS' }
              properties: {
                encryption: {
                  keySource: 'Microsoft.Storage'
                }
              }
            }
            """)
            temp_path = Path(f.name)

        try:
            findings = self.evaluator.audit_bicep_file(temp_path)
            sec004_findings = [f for f in findings if f.rule.rule_id == "SEC-004"]
            self.assertEqual(len(sec004_findings), 1)
            self.assertFalse(sec004_findings[0].passed)
        finally:
            temp_path.unlink()


if __name__ == "__main__":
    unittest.main()
