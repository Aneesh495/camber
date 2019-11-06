"""
Camber AST Parser and Declaration Extractor.
Parses native Bicep syntax and ARM JSON templates to build semantic token representations.
"""

from dataclasses import dataclass, field
import json
from pathlib import Path
import re
from typing import Any, Dict, List, Optional, Set


@dataclass
class ParameterDeclaration:
    name: str
    param_type: str
    default_value: Optional[str] = None
    is_secure: bool = False
    description: Optional[str] = None
    allowed_values: List[str] = field(default_factory=list)


@dataclass
class VariableDeclaration:
    name: str
    expression: str


@dataclass
class ResourceDeclaration:
    symbolic_name: str
    provider_type: str
    api_version: str
    is_existing: bool = False
    depends_on: List[str] = field(default_factory=list)
    parent_symbol: Optional[str] = None
    properties_preview: Dict[str, Any] = field(default_factory=dict)


@dataclass
class ModuleDeclaration:
    symbolic_name: str
    module_path: str
    depends_on: List[str] = field(default_factory=list)
    params: Dict[str, str] = field(default_factory=dict)


@dataclass
class OutputDeclaration:
    name: str
    output_type: str
    expression: str
    description: Optional[str] = None


@dataclass
class TypeDeclaration:
    name: str
    is_exported: bool
    definition: str


@dataclass
class BicepSourceAST:
    file_path: Path
    total_lines: int
    code_lines: int
    comment_lines: int
    blank_lines: int
    parameters: List[ParameterDeclaration] = field(default_factory=list)
    variables: List[VariableDeclaration] = field(default_factory=list)
    resources: List[ResourceDeclaration] = field(default_factory=list)
    modules: List[ModuleDeclaration] = field(default_factory=list)
    outputs: List[OutputDeclaration] = field(default_factory=list)
    types: List[TypeDeclaration] = field(default_factory=list)

    @property
    def comment_to_code_ratio(self) -> float:
        if self.code_lines == 0:
            return 0.0
        return round(self.comment_lines / self.code_lines, 4)


class BicepASTParser:
    """Fast recursive descent and regex-assisted parser for Bicep template sources."""

    RE_RESOURCE = re.compile(
        r"^\s*(?:resource)\s+([a-zA-Z0-9_]+)\s+'([^@]+)@([^']+)'\s*(?:=\s*(?:if\s*\([^)]*\)\s*)?\{|\s*existing\s*=\s*\{)",
        re.MULTILINE,
    )
    RE_MODULE = re.compile(
        r"^\s*(?:module)\s+([a-zA-Z0-9_]+)\s+'([^']+)'\s*=\s*(?:if\s*\([^)]*\)\s*)?\{",
        re.MULTILINE,
    )
    RE_PARAM = re.compile(
        r"^\s*param\s+([a-zA-Z0-9_]+)\s+([a-zA-Z0-9_\[\]]+)(?:\s*=\s*(.+))?$",
        re.MULTILINE,
    )
    RE_VAR = re.compile(
        r"^\s*var\s+([a-zA-Z0-9_]+)\s*=\s*(.+)$",
        re.MULTILINE,
    )
    RE_OUTPUT = re.compile(
        r"^\s*output\s+([a-zA-Z0-9_]+)\s+([a-zA-Z0-9_\[\]]+)\s*=\s*(.+)$",
        re.MULTILINE,
    )
    RE_TYPE = re.compile(
        r"^\s*type\s+([a-zA-Z0-9_]+)\s*=\s*(.+)$",
        re.MULTILINE,
    )

    def parse_file(self, file_path: Path) -> BicepSourceAST:
        """Parse an individual .bicep file into a typed BicepSourceAST."""
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        lines = content.splitlines()
        code_lines = 0
        comment_lines = 0
        blank_lines = 0
        in_multiline_comment = False

        for line in lines:
            stripped = line.strip()
            if not stripped:
                blank_lines += 1
                continue
            if in_multiline_comment:
                comment_lines += 1
                if "*/" in stripped:
                    in_multiline_comment = False
                continue
            if stripped.startswith("/*"):
                comment_lines += 1
                if "*/" not in stripped:
                    in_multiline_comment = True
                continue
            if stripped.startswith("//") or stripped.startswith("#"):
                comment_lines += 1
                continue
            code_lines += 1

        ast = BicepSourceAST(
            file_path=file_path,
            total_lines=len(lines),
            code_lines=code_lines,
            comment_lines=comment_lines,
            blank_lines=blank_lines,
        )

        for match in self.RE_PARAM.finditer(content):
            name, ptype, default_val = match.groups()
            preceding = content[: match.start()]
            decorators = preceding.splitlines()[-4:]
            is_secure = any("@secure()" in d for d in decorators)
            desc: Optional[str] = None
            for d in decorators:
                if "@description(" in d:
                    desc_match = re.search(r"@description\(['\"](.*)['\"]\)", d)
                    if desc_match:
                        desc = desc_match.group(1)
            ast.parameters.append(
                ParameterDeclaration(
                    name=name,
                    param_type=ptype,
                    default_value=default_val.strip() if default_val else None,
                    is_secure=is_secure,
                    description=desc,
                )
            )

        for match in self.RE_VAR.finditer(content):
            name, expr = match.groups()
            ast.variables.append(VariableDeclaration(name=name, expression=expr.strip()))

        for match in self.RE_OUTPUT.finditer(content):
            name, otype, expr = match.groups()
            ast.outputs.append(
                OutputDeclaration(
                    name=name,
                    output_type=otype,
                    expression=expr.strip(),
                )
            )

        for match in self.RE_RESOURCE.finditer(content):
            sym_name, prov_type, api_ver = match.groups()
            is_existing = "existing" in match.group(0)
            ast.resources.append(
                ResourceDeclaration(
                    symbolic_name=sym_name,
                    provider_type=prov_type,
                    api_version=api_ver,
                    is_existing=is_existing,
                )
            )

        for match in self.RE_MODULE.finditer(content):
            sym_name, mod_path = match.groups()
            ast.modules.append(
                ModuleDeclaration(
                    symbolic_name=sym_name,
                    module_path=mod_path,
                )
            )

        for match in self.RE_TYPE.finditer(content):
            name, tdef = match.groups()
            preceding = content[: match.start()]
            decorators = preceding.splitlines()[-3:]
            is_exported = any("@export()" in d for d in decorators)
            ast.types.append(
                TypeDeclaration(
                    name=name,
                    is_exported=is_exported,
                    definition=tdef.strip(),
                )
            )

        return ast

    def parse_arm_json(self, arm_dict: Dict[str, Any]) -> List[ResourceDeclaration]:
        """Extract resource specifications and explicit dependsOn links from compiled ARM JSON."""
        resources: List[ResourceDeclaration] = []
        raw_resources = arm_dict.get("resources", [])

        for r in raw_resources:
            r_name = r.get("name", "unnamed")
            r_type = r.get("type", "unknown")
            r_api = r.get("apiVersion", "unknown")
            deps = r.get("dependsOn", [])
            clean_deps = []
            for dep in deps:
                if isinstance(dep, str):
                    clean_deps.append(dep)

            resources.append(
                ResourceDeclaration(
                    symbolic_name=r_name,
                    provider_type=r_type,
                    api_version=r_api,
                    depends_on=clean_deps,
                    properties_preview=r.get("properties", {}),
                )
            )

        return resources
