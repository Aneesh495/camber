"""
Unit tests for multi-region grid carbon intensity and cloud economics calculations.
"""

import unittest

from engine.cost_carbon import CloudEconomicsEngine, REGIONAL_GRID_CARBON_INTENSITY


class TestCostCarbon(unittest.TestCase):
    """Test suite verifying cloud economics and carbon intensity calculations."""

    def setUp(self):
        self.engine = CloudEconomicsEngine(pue=1.18)

    def test_regional_grid_intensity_values(self):
        """Verify known grid intensity baselines."""
        self.assertEqual(REGIONAL_GRID_CARBON_INTENSITY["switzerlandnorth"], 28.0)
        self.assertEqual(REGIONAL_GRID_CARBON_INTENSITY["eastus"], 410.0)
        self.assertLess(
            REGIONAL_GRID_CARBON_INTENSITY["switzerlandnorth"],
            REGIONAL_GRID_CARBON_INTENSITY["eastus"],
        )

    def test_evaluate_resource_calculation(self):
        """Verify energy and carbon calculations for a standard confidential compute SKU."""
        profile = self.engine.evaluate_resource(
            resource_id="test-aks",
            name="Test AKS Node",
            resource_type="Microsoft.ContainerService/managedClusters",
            location="switzerlandnorth",
            sku_or_tier="Standard_DC4as_v5",
            quantity=2,
        )

        # 2 nodes * 160W = 320W
        self.assertEqual(profile.power_watts, 320.0)
        # Energy = (320W * 1.18 PUE * 730h) / 1000 = 275.65 kWh
        self.assertAlmostEqual(profile.monthly_energy_kwh, 275.65, delta=0.5)
        # Carbon = (275.65 kWh * 28 gCO2/kWh) / 1000 = 7.72 kg CO2e
        self.assertAlmostEqual(profile.monthly_carbon_kg_co2e, 7.72, delta=0.5)
        # Monthly cost = 2 * 0.348 * 730 = $508.08
        self.assertAlmostEqual(profile.monthly_cost_usd, 508.08, delta=1.0)

    def test_generate_report_recommendations(self):
        """Verify sustainability report generates recommendations when high carbon regions are present."""
        p_east = self.engine.evaluate_resource(
            resource_id="east-vm",
            name="East VM",
            resource_type="Compute",
            location="eastus",
            sku_or_tier="Standard_DC4as_v5",
        )
        report = self.engine.generate_report([p_east])
        self.assertGreater(len(report.green_recommendations), 0)
        self.assertIn("switzerlandnorth", report.green_recommendations[0])


if __name__ == "__main__":
    unittest.main()
