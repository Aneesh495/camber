"""
Camber Terminal Visualizer.
Renders ASCII/Unicode dependency DAGs, deployment Gantt charts, and compliance report cards.
"""

from typing import Dict, List, Optional
from engine.cost_carbon import ArchitectureSustainabilityReport
from engine.graph import DependencyDAG
from engine.policy_evaluator import AuditReport
from engine.simulator import SimulationResult


# Terminal ANSI color escapes
RESET = "\033[0m"
BOLD = "\033[1m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"
GRAY = "\033[90m"


class TerminalVisualizer:
    """Renders formatted ASCII and Unicode visual reports to terminal output."""

    @staticmethod
    def render_banner() -> str:
        banner = f"""{CYAN}{BOLD}
  ██████╗ █████╗ ███╗   ███╗██████╗ ███████╗██████╗ 
 ██╔════╝██╔══██╗████╗ ████║██╔══██╗██╔════╝██╔══██╗
 ██║     ███████║██╔████╔██║██████╔╝█████╗  ██████╔╝
 ██║     ██╔══██║██║╚██╔╝██║██╔══██╗██╔══╝  ██╔══██╗
 ╚██████╗██║  ██║██║ ╚═╝ ██║██████╔╝███████╗██║  ██║
  ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝
{RESET}{GRAY} Sovereign Confidential Infrastructure & Discrete-Event Verification Fabric{RESET}
"""
        return banner

    @staticmethod
    def render_dag_stages(dag: DependencyDAG) -> str:
        """Render parallel stages of the dependency DAG."""
        stages = dag.get_stages()
        crit_nodes, total_duration = dag.compute_critical_path()
        crit_set = set(crit_nodes)

        lines = [
            f"{BOLD}======================================================================{RESET}",
            f"{BOLD}           PARALLEL DEPLOYMENT STAGES & CRITICAL PATH                 {RESET}",
            f"{BOLD}======================================================================{RESET}",
            f" Total Resources: {len(dag.nodes)} | Parallel Stages: {len(stages)} | Critical Path Duration: {total_duration:.1f}s",
            "",
        ]

        for idx, stage in enumerate(stages):
            stage_header = f"{CYAN}[Stage {idx + 1}]{RESET} ({len(stage)} concurrent resources)"
            lines.append(stage_header)
            for node_id in stage:
                node = dag.nodes[node_id]
                is_crit = node_id in crit_set
                marker = f"{RED}*{RESET}" if is_crit else " "
                crit_tag = f" {RED}(CRITICAL){RESET}" if is_crit else ""
                lines.append(
                    f"  {marker} {BOLD}{node.name}{RESET} [{GRAY}{node.resource_type}{RESET}]"
                    f" ~{node.estimated_duration_seconds:.0f}s{crit_tag}"
                )
            lines.append("")

        lines.append(f"{RED}*{RESET} = Critical Path member with zero float/slack")
        return "\n".join(lines)

    @staticmethod
    def render_gantt_chart(sim_result: SimulationResult, width: int = 40) -> str:
        """Render discrete-event simulation timeline as an ASCII Gantt chart."""
        max_time = sim_result.total_virtual_time_seconds
        if max_time <= 0:
            return "No simulation timeline recorded."

        lines = [
            f"{BOLD}======================================================================{RESET}",
            f"{BOLD}               DISCRETE-EVENT SIMULATION GANTT TIMELINE               {RESET}",
            f"{BOLD}======================================================================{RESET}",
            f" Total Virtual Time: {max_time:.2f}s | Completed: {sim_result.completed_resources} | Throttles: {sim_result.total_throttles}",
            "",
        ]

        # Sort resources by start time
        sorted_records = sorted(
            sim_result.resource_records.values(), key=lambda r: (r.start_time, r.end_time)
        )

        for rec in sorted_records:
            start_ratio = min(1.0, rec.start_time / max_time)
            end_ratio = min(1.0, rec.end_time / max_time)

            lead_spaces = int(start_ratio * width)
            bar_len = max(1, int((end_ratio - start_ratio) * width))

            status_color = GREEN if rec.status == "COMPLETED" else RED
            bar = "█" * bar_len

            label = f"{rec.name[:20]:<20}"
            timeline_str = f"{' ' * lead_spaces}{status_color}{bar}{RESET}"
            time_info = f"{rec.start_time:>5.1f}s -> {rec.end_time:>5.1f}s"
            retries = f" (retries: {rec.retry_count})" if rec.retry_count > 0 else ""

            lines.append(f" {label} | {timeline_str:<{width + 10}} | {time_info}{retries}")

        return "\n".join(lines)

    @staticmethod
    def render_audit_report(report: AuditReport) -> str:
        """Render CIS/NIST security policy compliance report card."""
        score_color = GREEN if report.score_percentage >= 90.0 else (YELLOW if report.score_percentage >= 70.0 else RED)

        lines = [
            f"{BOLD}======================================================================{RESET}",
            f"{BOLD}              SOVEREIGN SECURITY & COMPLIANCE REPORT CARD             {RESET}",
            f"{BOLD}======================================================================{RESET}",
            f" Frameworks: CIS Azure Benchmark v2.0 | NIST SP 800-53 Rev 5",
            f" Compliance Score: {score_color}{BOLD}{report.score_percentage}%{RESET} ({report.passed_checks}/{report.total_checks} controls passing)",
            "",
        ]

        for f in report.findings:
            status_tag = f"{GREEN}[PASS]{RESET}" if f.passed else f"{RED}[FAIL]{RESET}"
            sev_color = RED if f.rule.severity in ("CRITICAL", "HIGH") else YELLOW
            sev_tag = f"{sev_color}{f.rule.severity}{RESET}"
            lines.append(f" {status_tag} {BOLD}{f.rule.rule_id}{RESET} ({sev_tag}): {f.rule.title}")
            lines.append(f"        Target: {f.target_file.name} | {GRAY}{f.evidence}{RESET}")
            if not f.passed:
                lines.append(f"        {YELLOW}Remediation:{RESET} {f.rule.remediation}")
            lines.append("")

        return "\n".join(lines)

    @staticmethod
    def render_sustainability_report(report: ArchitectureSustainabilityReport) -> str:
        """Render regional cost and grid carbon emissions summary."""
        lines = [
            f"{BOLD}======================================================================{RESET}",
            f"{BOLD}           REGIONAL CLOUD ECONOMICS & GRID CARBON FOOTPRINT           {RESET}",
            f"{BOLD}======================================================================{RESET}",
            f" Total Monthly OPEX: {GREEN}${report.total_monthly_cost_usd:,.2f}{RESET}",
            f" Total Monthly Energy: {CYAN}{report.total_monthly_energy_kwh:,.2f} kWh{RESET}",
            f" Total Monthly Carbon: {YELLOW}{report.total_monthly_carbon_kg_co2e:,.2f} kg CO2e{RESET}",
            "",
            f" {BOLD}Regional Continental Breakdown:{RESET}",
        ]

        for loc, data in report.regional_breakdown.items():
            lines.append(
                f"   * {BOLD}{loc:<20}{RESET} : "
                f"Cost: ${data['cost_usd']:>8.2f} | "
                f"Energy: {data['energy_kwh']:>7.1f} kWh | "
                f"Carbon: {data['carbon_kg']:>6.1f} kg CO2e"
            )

        if report.green_recommendations:
            lines.append("")
            lines.append(f" {BOLD}Green Infrastructure Recommendations:{RESET}")
            for rec in report.green_recommendations:
                lines.append(f"   - {rec}")

        return "\n".join(lines)
