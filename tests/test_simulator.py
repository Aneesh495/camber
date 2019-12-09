"""
Unit and edge-case tests for the discrete-event ARM deployment simulator.
"""

import unittest

from engine.graph import DependencyDAG
from engine.simulator import ARMDeploymentSimulator, SimulationConfig


class TestSimulator(unittest.TestCase):
    """Test suite verifying discrete event simulation behavior and edge conditions."""

    def setUp(self):
        self.dag = DependencyDAG()
        self.dag.add_node("r1", "Resource 1", "Microsoft.Network/virtualNetworks", 10.0)
        self.dag.add_node("r2", "Resource 2", "Microsoft.Network/networkSecurityGroups", 10.0)
        self.dag.add_node("r3", "Resource 3", "Microsoft.Compute/virtualMachineScaleSets", 20.0)
        self.dag.add_dependency("r2", "r1")
        self.dag.add_dependency("r3", "r2")

    def test_deterministic_ideal_simulation(self):
        """Verify simulator produces monotonic timestamps and 100% completion with zero faults."""
        config = SimulationConfig(
            throttle_probability=0.0,
            failure_probability=0.0,
            max_concurrency=10,
            random_seed=42,
        )
        sim = ARMDeploymentSimulator(self.dag, config)
        result = sim.run()

        self.assertTrue(result.is_successful)
        self.assertEqual(result.completed_resources, 3)
        self.assertEqual(result.failed_resources, 0)
        self.assertEqual(result.total_throttles, 0)
        self.assertEqual(result.total_retries, 0)

        # Monotonic time check in event log
        prev_time = 0.0
        for t, event_type, r_id in result.event_log:
            self.assertGreaterEqual(t, prev_time)
            prev_time = t

    def test_transient_throttling_recovery(self):
        """Verify simulator recovers gracefully from simulated HTTP 429 throttling."""
        config = SimulationConfig(
            throttle_probability=0.6,
            failure_probability=0.0,
            max_concurrency=5,
            max_retry_attempts=5,
            random_seed=123,
        )
        sim = ARMDeploymentSimulator(self.dag, config)
        result = sim.run()

        self.assertTrue(result.is_successful)
        self.assertEqual(result.completed_resources, 3)
        self.assertGreater(result.total_throttles, 0)

    def test_terminal_failure_when_retries_exhausted(self):
        """Verify simulator halts and marks resource failed when max retries exceeded."""
        config = SimulationConfig(
            throttle_probability=0.0,
            failure_probability=1.0,  # Always fails
            max_retry_attempts=2,
            random_seed=999,
        )
        sim = ARMDeploymentSimulator(self.dag, config)
        result = sim.run()

        self.assertFalse(result.is_successful)
        self.assertGreater(result.failed_resources, 0)


if __name__ == "__main__":
    unittest.main()
