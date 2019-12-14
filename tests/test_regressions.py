"""
Regression test suite documenting and preventing bugs encountered during development.
Each test case reproduces an edge condition that failed previously, verifying that
the fix permanently prevents future regressions.
"""

from pathlib import Path
import tempfile
import unittest

from engine.compiler import BicepCompiler
from engine.policy_evaluator import PolicyEvaluator


class TestRegressions(unittest.TestCase):
    """Regression test cases verifying permanent resolution of discovered edge cases."""

    @classmethod
    def setUpClass(cls):
        cls.compiler = BicepCompiler(root_dir=Path.cwd())
        cls.installed, _ = cls.compiler.check_installed()

    def test_regression_01_bicep_reserved_decorator_param_name(self):
        """
        Regression 1: Naming a parameter 'description' collides with Bicep's @description decorator (BCP079/BCP062).
        Resolution: Use 'roleDescription' or 'assignmentDescription'.
        Verification: Ensure role_assignment.bicep compiles cleanly with roleDescription.
        """
        if not self.installed:
            raise unittest.SkipTest("Bicep CLI unavailable")
        role_mod = Path("bicep/modules/identity/role_assignment.bicep")
        res = self.compiler.compile_file(role_mod, retain_output=False)
        self.assertTrue(res.success, f"role_assignment.bicep should compile without BCP079 error: {res.stderr}")

    def test_regression_02_nested_for_expression_prohibition(self):
        """
        Regression 2: Bicep forbids nested for-expressions in properties (BCP142).
        Resolution: Pass pre-structured arrays directly rather than nesting loops.
        Verification: Ensure azure_firewall.bicep compiles cleanly without BCP142 error.
        """
        if not self.installed:
            raise unittest.SkipTest("Bicep CLI unavailable")
        fw_mod = Path("bicep/modules/network/azure_firewall.bicep")
        res = self.compiler.compile_file(fw_mod, retain_output=False)
        self.assertTrue(res.success, f"azure_firewall.bicep should compile without BCP142 error: {res.stderr}")

    def test_regression_03_service_bus_endpoint_property_drift(self):
        """
        Regression 3: Service Bus namespace properties use 'serviceBusEndpoint' rather than 'endpoint' (BCP053).
        Resolution: Use .serviceBusEndpoint output expression.
        Verification: Ensure service_bus_namespace.bicep compiles cleanly without BCP053 error.
        """
        if not self.installed:
            raise unittest.SkipTest("Bicep CLI unavailable")
        sb_mod = Path("bicep/modules/data/service_bus_namespace.bicep")
        res = self.compiler.compile_file(sb_mod, retain_output=False)
        self.assertTrue(res.success, f"service_bus_namespace.bicep should compile without BCP053 error: {res.stderr}")

    def test_regression_04_policy_evaluator_resource_provider_decoupling(self):
        """
        Regression 4: Policy evaluator previously checked filename heuristics rather than content resource providers.
        Resolution: Decoupled rule matching to inspect AST resource providers.
        Verification: Audit a uniquely named file with no conventional keywords and assert rule evaluation triggers.
        """
        evaluator = PolicyEvaluator()
        with tempfile.NamedTemporaryFile("w", prefix="random_prefix_", suffix=".bicep", delete=False) as f:
            f.write("""
            resource myCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
              name: 'arbitrary-name'
              location: 'eastus'
              properties: {
                agentPoolProfiles: [
                  {
                    name: 'pool'
                    enableNodePublicIP: true
                  }
                ]
              }
            }
            """)
            temp_path = Path(f.name)

        try:
            findings = evaluator.audit_bicep_file(temp_path)
            sec002 = [f for f in findings if f.rule.rule_id == "SEC-002"]
            self.assertEqual(len(sec002), 1, "Evaluator must detect resource provider regardless of filename")
            self.assertFalse(sec002[0].passed, "Public IP violation must be flagged")
        finally:
            temp_path.unlink()

    def test_regression_05_nat_gateway_property_casing(self):
        """
        Regression 5: NAT Gateway properties format requires 'publicIpAddresses' (lowercase 'p'), not 'publicIPAddresses'.
        Resolution: Verified schema casing in nat_gateway.bicep.
        Verification: Ensure nat_gateway.bicep compiles cleanly without BCP089 warning.
        """
        if not self.installed:
            raise unittest.SkipTest("Bicep CLI unavailable")
        nat_mod = Path("bicep/modules/network/nat_gateway.bicep")
        res = self.compiler.compile_file(nat_mod, retain_output=False)
        self.assertTrue(res.success)
        for diag in res.diagnostics:
            self.assertNotIn("BCP089", diag)


if __name__ == "__main__":
    unittest.main()
