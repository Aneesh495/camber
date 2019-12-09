"""
Unit and integration tests for Bicep template compilation and ARM JSON generation.
"""

from pathlib import Path
import unittest

from engine.compiler import BicepCompiler


class TestBicepCompilation(unittest.TestCase):
    """Test suite verifying compilation of all Bicep modules and parameters."""

    @classmethod
    def setUpClass(cls):
        cls.compiler = BicepCompiler(root_dir=Path.cwd())
        cls.installed, cls.version_info = cls.compiler.check_installed()
        if not cls.installed:
            raise unittest.SkipTest("Bicep CLI is not available in environment")

    def test_bicep_cli_installed(self):
        """Verify Bicep CLI is accessible and returns version information."""
        self.assertTrue(self.installed)
        self.assertIn("Bicep CLI version", self.version_info)

    def test_compile_all_types(self):
        """Verify all user-defined type modules in bicep/types compile cleanly."""
        types_dir = Path("bicep/types")
        files = list(types_dir.glob("*.bicep"))
        self.assertGreater(len(files), 0, "Expected at least 1 type module")
        for b_file in files:
            res = self.compiler.compile_file(b_file, retain_output=False)
            self.assertTrue(res.success, f"Compilation failed for {b_file.name}: {res.stderr}")

    def test_compile_all_modules(self):
        """Verify all resource modules in bicep/modules compile cleanly."""
        modules_dir = Path("bicep/modules")
        files = list(modules_dir.rglob("*.bicep"))
        self.assertGreaterEqual(len(files), 20, "Expected at least 20 resource modules")
        for b_file in files:
            res = self.compiler.compile_file(b_file, retain_output=False)
            self.assertTrue(res.success, f"Compilation failed for {b_file.name}: {res.stderr}")

    def test_compile_all_blueprints(self):
        """Verify all production blueprints in bicep/blueprints compile cleanly."""
        blueprints_dir = Path("bicep/blueprints")
        files = list(blueprints_dir.glob("*.bicep"))
        self.assertGreaterEqual(len(files), 4, "Expected at least 4 blueprints")
        for b_file in files:
            res = self.compiler.compile_file(b_file, retain_output=False)
            self.assertTrue(res.success, f"Compilation failed for {b_file.name}: {res.stderr}")

    def test_compile_main_orchestrator(self):
        """Verify top-level main.bicep orchestrator compiles cleanly and produces valid ARM JSON."""
        main_file = Path("bicep/main.bicep")
        self.assertTrue(main_file.exists(), "bicep/main.bicep must exist")
        res = self.compiler.compile_file(main_file, retain_output=True)
        self.assertTrue(res.success, f"Compilation failed for main.bicep: {res.stderr}")
        self.assertIsNotNone(res.arm_template, "Expected parsed ARM JSON from main.bicep")
        self.assertIn("$schema", res.arm_template)
        self.assertIn("resources", res.arm_template)

    def test_compile_all_parameter_files(self):
        """Verify all environment parameter files in bicep/parameters compile cleanly."""
        params_dir = Path("bicep/parameters")
        files = list(params_dir.glob("*.bicepparam"))
        self.assertGreaterEqual(len(files), 4, "Expected at least 4 parameter files")
        for p_file in files:
            res = self.compiler.compile_file(p_file, retain_output=False)
            self.assertTrue(res.success, f"Compilation failed for {p_file.name}: {res.stderr}")


if __name__ == "__main__":
    unittest.main()
