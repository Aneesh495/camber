"""
Unit tests for Dependency DAG, topological sort, cycle detection, and Critical Path Method.
"""

import unittest

from engine.graph import DependencyDAG


class TestDependencyDAG(unittest.TestCase):
    """Test suite verifying graph theoretical algorithms on cloud deployment DAGs."""

    def test_simple_dag_topological_sort(self):
        """Verify Kahn algorithm orders a linear dependency chain correctly."""
        dag = DependencyDAG()
        dag.add_node("A", "Resource A", "TypeA", 10.0)
        dag.add_node("B", "Resource B", "TypeB", 20.0)
        dag.add_node("C", "Resource C", "TypeC", 30.0)
        dag.add_dependency("B", "A")  # B depends on A
        dag.add_dependency("C", "B")  # C depends on B

        order = dag.topological_sort()
        self.assertEqual(order, ["A", "B", "C"])

    def test_cycle_detection_tarjan(self):
        """Verify Tarjan SCC detects direct and indirect circular dependencies."""
        dag = DependencyDAG()
        dag.add_node("X", "Resource X", "TypeX", 10.0)
        dag.add_node("Y", "Resource Y", "TypeY", 10.0)
        dag.add_node("Z", "Resource Z", "TypeZ", 10.0)
        dag.add_dependency("Y", "X")
        dag.add_dependency("Z", "Y")
        dag.add_dependency("X", "Z")  # Creates cycle: X -> Y -> Z -> X

        cycles = dag.find_cycles()
        self.assertEqual(len(cycles), 1)
        self.assertCountEqual(cycles[0], ["X", "Y", "Z"])

        with self.assertRaises(ValueError):
            dag.topological_sort()

    def test_critical_path_method(self):
        """Verify CPM forward and backward passes compute correct duration and critical path."""
        dag = DependencyDAG()
        # Diamond topology:
        #      A (10s)
        #     /      \
        #  B (50s)    C (20s)
        #     \      /
        #      D (10s)
        dag.add_node("A", "Node A", "TypeA", 10.0)
        dag.add_node("B", "Node B", "TypeB", 50.0)
        dag.add_node("C", "Node C", "TypeC", 20.0)
        dag.add_node("D", "Node D", "TypeD", 10.0)

        dag.add_dependency("B", "A")
        dag.add_dependency("C", "A")
        dag.add_dependency("D", "B")
        dag.add_dependency("D", "C")

        crit_path, duration = dag.compute_critical_path()
        # Path A -> B -> D duration is 10 + 50 + 10 = 70s
        # Path A -> C -> D duration is 10 + 20 + 10 = 40s
        self.assertEqual(duration, 70.0)
        self.assertEqual(crit_path, ["A", "B", "D"])

        # Node C should have slack of 30.0s
        self.assertAlmostEqual(dag.nodes["C"].slack, 30.0)
        self.assertFalse(dag.nodes["C"].is_critical)
        self.assertTrue(dag.nodes["B"].is_critical)

    def test_parallel_stages_partition(self):
        """Verify parallel stages partition independent resources into concurrent batches."""
        dag = DependencyDAG()
        dag.add_node("root1", "Root 1", "TypeR", 10.0)
        dag.add_node("root2", "Root 2", "TypeR", 10.0)
        dag.add_node("child1", "Child 1", "TypeC", 20.0)
        dag.add_node("child2", "Child 2", "TypeC", 20.0)
        dag.add_dependency("child1", "root1")
        dag.add_dependency("child2", "root2")

        stages = dag.get_stages()
        self.assertEqual(len(stages), 2)
        self.assertCountEqual(stages[0], ["root1", "root2"])
        self.assertCountEqual(stages[1], ["child1", "child2"])


if __name__ == "__main__":
    unittest.main()
