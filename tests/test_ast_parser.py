"""
Unit tests for Bicep AST Parser and declaration extractor.
"""

from pathlib import Path
import unittest

from engine.ast_parser import BicepASTParser


class TestBicepASTParser(unittest.TestCase):
    """Test suite verifying AST extraction from Bicep source files."""

    def setUp(self):
        self.parser = BicepASTParser()

    def test_parse_network_types(self):
        """Verify type declarations extracted from bicep/types/network.bicep."""
        net_types_file = Path("bicep/types/network.bicep")
        ast = self.parser.parse_file(net_types_file)
        self.assertGreater(ast.total_lines, 50)
        self.assertGreater(ast.code_lines, 30)
        self.assertGreater(len(ast.types), 5)
        type_names = [t.name for t in ast.types]
        self.assertIn("securityRuleConfig", type_names)
        self.assertIn("virtualNetworkConfig", type_names)

    def test_parse_aks_confidential_cluster(self):
        """Verify parameter, resource, and output extraction from aks_confidential_cluster.bicep."""
        aks_file = Path("bicep/modules/compute/aks_confidential_cluster.bicep")
        ast = self.parser.parse_file(aks_file)
        self.assertGreater(len(ast.parameters), 5)
        self.assertGreater(len(ast.outputs), 2)
        param_names = [p.name for p in ast.parameters]
        self.assertIn("clusterName", param_names)
        self.assertIn("kubernetesVersion", param_names)
        self.assertIn("confidentialWorkerVmSize", param_names)

        # Check resource provider extraction
        resource_providers = [r.provider_type for r in ast.resources]
        self.assertIn("Microsoft.ContainerService/managedClusters", resource_providers)

    def test_parse_main_modules(self):
        """Verify nested module calls in main.bicep."""
        main_file = Path("bicep/main.bicep")
        ast = self.parser.parse_file(main_file)
        self.assertEqual(len(ast.modules), 4)
        module_names = [m.symbolic_name for m in ast.modules]
        self.assertIn("planetaryTransit", module_names)
        self.assertIn("primarySovereignEnclave", module_names)
        self.assertIn("secondaryInferenceStack", module_names)
        self.assertIn("edgeMicrozone", module_names)

    def test_comment_ratio_positive(self):
        """Verify comment to code ratio is strictly positive across modules."""
        main_file = Path("bicep/main.bicep")
        ast = self.parser.parse_file(main_file)
        self.assertGreater(ast.comment_to_code_ratio, 0.0)


if __name__ == "__main__":
    unittest.main()
