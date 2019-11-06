"""
Camber Bicep Compiler Wrapper and Template Analyzer.
Executes official Bicep CLI builds, captures diagnostics, and produces ARM JSON trees.
"""

from dataclasses import dataclass, field
import json
import os
from pathlib import Path
import subprocess
import time
from typing import Dict, List, Optional, Tuple


@dataclass
class CompilationResult:
    source_path: Path
    target_path: Optional[Path]
    success: bool
    duration_ms: float
    stdout: str
    stderr: str
    diagnostics: List[str] = field(default_factory=list)
    arm_template: Optional[Dict] = None


@dataclass
class ProjectCompilationSummary:
    total_files: int
    successful_files: int
    failed_files: int
    total_duration_ms: float
    results: List[CompilationResult] = field(default_factory=list)

    @property
    def is_clean(self) -> bool:
        return self.failed_files == 0


class BicepCompiler:
    """Interface to the Bicep CLI compiler."""

    def __init__(self, bicep_binary: str = "bicep", root_dir: Optional[Path] = None):
        self.bicep_binary = bicep_binary
        self.root_dir = root_dir or Path.cwd()

    def check_installed(self) -> Tuple[bool, str]:
        """Verify that the Bicep CLI is accessible on PATH."""
        try:
            proc = subprocess.run(
                [self.bicep_binary, "--version"],
                capture_output=True,
                text=True,
                check=False,
            )
            if proc.returncode == 0:
                return True, proc.stdout.strip()
            return False, proc.stderr.strip()
        except FileNotFoundError:
            return False, "Bicep CLI executable not found on PATH"

    def compile_file(
        self,
        file_path: Path,
        output_dir: Optional[Path] = None,
        retain_output: bool = False,
    ) -> CompilationResult:
        """Compile an individual .bicep or .bicepparam file."""
        abs_path = file_path.resolve()
        start_time = time.perf_counter()

        is_param = abs_path.suffix == ".bicepparam"
        cmd = [self.bicep_binary, "build-params" if is_param else "build", str(abs_path)]

        target_path: Optional[Path] = None
        if output_dir:
            output_dir.mkdir(parents=True, exist_ok=True)
            out_name = abs_path.stem + (".params.json" if is_param else ".arm.json")
            target_path = output_dir / out_name
            cmd.extend(["--outfile", str(target_path)])
        else:
            default_out = abs_path.with_suffix(".json")
            target_path = default_out

        proc = subprocess.run(
            cmd,
            cwd=str(self.root_dir),
            capture_output=True,
            text=True,
            check=False,
        )
        duration_ms = (time.perf_counter() - start_time) * 1000.0

        arm_content: Optional[Dict] = None
        if proc.returncode == 0 and target_path and target_path.exists():
            try:
                with open(target_path, "r", encoding="utf-8") as f:
                    arm_content = json.load(f)
            except Exception as e:
                proc.stderr += f"\nFailed to parse generated ARM JSON: {e}"

        if not retain_output and target_path and target_path.exists():
            try:
                target_path.unlink()
            except OSError:
                pass

        diagnostics = []
        for line in proc.stderr.splitlines():
            clean = line.strip()
            if clean and not clean.startswith("WARNING: The following experimental"):
                diagnostics.append(clean)

        return CompilationResult(
            source_path=file_path,
            target_path=target_path if retain_output else None,
            success=(proc.returncode == 0),
            duration_ms=duration_ms,
            stdout=proc.stdout,
            stderr=proc.stderr,
            diagnostics=diagnostics,
            arm_template=arm_content,
        )

    def discover_bicep_files(self, bicep_dir: Path) -> List[Path]:
        """Find all .bicep source files under the target directory."""
        return sorted(list(bicep_dir.rglob("*.bicep")))

    def discover_param_files(self, bicep_dir: Path) -> List[Path]:
        """Find all .bicepparam files under the target directory."""
        return sorted(list(bicep_dir.rglob("*.bicepparam")))

    def compile_all(
        self,
        bicep_dir: Path,
        output_dir: Optional[Path] = None,
        retain_output: bool = False,
    ) -> ProjectCompilationSummary:
        """Compile the entire suite of Bicep files and parameter files."""
        files = self.discover_bicep_files(bicep_dir) + self.discover_param_files(bicep_dir)
        results: List[CompilationResult] = []

        total_start = time.perf_counter()
        success_count = 0
        failure_count = 0

        for f in files:
            res = self.compile_file(f, output_dir=output_dir, retain_output=retain_output)
            results.append(res)
            if res.success:
                success_count += 1
            else:
                failure_count += 1

        total_duration = (time.perf_counter() - total_start) * 1000.0

        return ProjectCompilationSummary(
            total_files=len(files),
            successful_files=success_count,
            failed_files=failure_count,
            total_duration_ms=total_duration,
            results=results,
        )
