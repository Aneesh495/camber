"""
Strict invariant audit test verifying ZERO occurrences of em dashes
across the entire repository codebase, comments, strings, and documentation.
"""

from pathlib import Path
import unittest


class TestEmDashAudit(unittest.TestCase):
    """Enforces zero em dash violations throughout all files in the project."""

    # File extensions subject to audit
    AUDITED_EXTENSIONS = {
        ".bicep",
        ".bicepparam",
        ".py",
        ".json",
        ".md",
        ".sh",
        ".txt",
    }

    # Named files without extension subject to audit
    AUDITED_FILENAMES = {
        "Makefile",
        "LICENSE",
        "camber",
        ".gitignore",
        ".gitattributes",
    }

    def test_zero_em_dashes_in_repository(self):
        """Scan all repository files and verify zero em dashes exist."""
        root_dir = Path.cwd()
        violations = []

        for p in root_dir.rglob("*"):
            # Skip git internals, virtual environments, cache directories
            if any(part in p.parts for part in (".git", "__pycache__", ".pytest_cache", "venv", ".venv")):
                continue
            # Skip this test file itself to prevent self-detection of search patterns
            if p.name == "test_em_dash_audit.py":
                continue

            if p.suffix in self.AUDITED_EXTENSIONS or p.name in self.AUDITED_FILENAMES:
                try:
                    with open(p, "r", encoding="utf-8", errors="replace") as f:
                        lines = f.readlines()
                except Exception as e:
                    violations.append(f"Could not read {p}: {e}")
                    continue

                for line_idx, line in enumerate(lines, 1):
                    # Check for Unicode em dash (U+2014)
                    if "\u2014" in line:
                        violations.append(
                            f"{p.relative_to(root_dir)}:{line_idx} contains Unicode em dash (\\u2014): {line.strip()}"
                        )
                    # Check for Unicode en dash (U+2013)
                    if "\u2013" in line:
                        violations.append(
                            f"{p.relative_to(root_dir)}:{line_idx} contains Unicode en dash (\\u2013): {line.strip()}"
                        )
                    # Check for double hyphens used as prose punctuation (e.g., 'word -- word')
                    # while allowing CLI flags like '--help' or comment headers '---'
                    if " -- " in line:
                        violations.append(
                            f"{p.relative_to(root_dir)}:{line_idx} contains prose double-hyphen dash: {line.strip()}"
                        )

        self.assertEqual(
            len(violations),
            0,
            f"Found {len(violations)} em dash violations:\n" + "\n".join(violations),
        )


if __name__ == "__main__":
    unittest.main()
