"""
Integration tests verifying execution and output formatting of the Camber CLI.
"""

from pathlib import Path
import subprocess
import sys
import unittest


class TestCamberCLI(unittest.TestCase):
    """Test suite executing CLI commands via subprocess."""

    @classmethod
    def setUpClass(cls):
        cls.root_dir = Path.cwd()
        cls.cli_entry = cls.root_dir / "camber"

    def _run_cli(self, *args) -> subprocess.CompletedProcess:
        cmd = [sys.executable, str(self.cli_entry)] + list(args)
        return subprocess.run(
            cmd,
            cwd=str(self.root_dir),
            capture_output=True,
            text=True,
            check=False,
        )

    def test_cli_help(self):
        """Verify --help returns exit code 0 and lists subcommands."""
        proc = self._run_cli("--help")
        self.assertEqual(proc.returncode, 0)
        self.assertIn("compile", proc.stdout)
        self.assertIn("graph", proc.stdout)
        self.assertIn("simulate", proc.stdout)
        self.assertIn("audit", proc.stdout)
        self.assertIn("carbon", proc.stdout)
        self.assertIn("verify", proc.stdout)

    def test_cli_graph(self):
        """Verify graph subcommand computes stages and returns 0."""
        proc = self._run_cli("graph")
        self.assertEqual(proc.returncode, 0, f"Error: {proc.stderr}")
        self.assertIn("PARALLEL DEPLOYMENT STAGES & CRITICAL PATH", proc.stdout)
        self.assertIn("CRITICAL", proc.stdout)

    def test_cli_simulate(self):
        """Verify simulate subcommand runs discrete event simulation."""
        proc = self._run_cli("simulate", "--concurrency", "15", "--seed", "42")
        self.assertEqual(proc.returncode, 0, f"Error: {proc.stderr}")
        self.assertIn("DISCRETE-EVENT SIMULATION GANTT TIMELINE", proc.stdout)
        self.assertIn("Total Simulated Deployment Time", proc.stdout)

    def test_cli_audit(self):
        """Verify audit subcommand evaluates security policies."""
        proc = self._run_cli("audit")
        self.assertEqual(proc.returncode, 0, f"Error: {proc.stderr}")
        self.assertIn("SOVEREIGN SECURITY & COMPLIANCE REPORT CARD", proc.stdout)
        self.assertIn("100.0%", proc.stdout)

    def test_cli_carbon(self):
        """Verify carbon subcommand outputs economic and sustainability metrics."""
        proc = self._run_cli("carbon")
        self.assertEqual(proc.returncode, 0, f"Error: {proc.stderr}")
        self.assertIn("REGIONAL CLOUD ECONOMICS & GRID CARBON FOOTPRINT", proc.stdout)
        self.assertIn("Total Monthly OPEX", proc.stdout)


if __name__ == "__main__":
    unittest.main()
