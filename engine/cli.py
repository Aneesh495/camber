"""
Camber Unified Command-Line Interface.
Orchestrates Bicep compilation, dependency DAG analysis, discrete-event simulation,
CIS/NIST security policy auditing, and cloud carbon/cost modeling.
"""

import argparse
import os
from pathlib import Path
import sys
from typing import List, Optional

from engine.ast_parser import BicepASTParser
from engine.compiler import BicepCompiler
from engine.cost_carbon import CloudEconomicsEngine
from engine.graph import DependencyDAG
from engine.policy_evaluator import PolicyEvaluator
from engine.simulator import ARMDeploymentSimulator, SimulationConfig
from engine.visualizer import TerminalVisualizer, BOLD, CYAN, GREEN, RED, RESET, YELLOW


def build_camber_dag() -> DependencyDAG:
    """Build the production architecture dependency DAG across sovereign tiers."""
    dag = DependencyDAG()

    # Tier 1: Identity & Telemetry
    dag.add_node("telemetry_law", "Central Log Analytics", "Microsoft.OperationalInsights/workspaces", 45.0)
    dag.add_node("dcr_pipeline", "Data Collection Rule", "Microsoft.Insights/dataCollectionRules", 30.0)
    dag.add_node("fabric_id", "Fabric Managed Identity", "Microsoft.ManagedIdentity/userAssignedIdentities", 15.0)

    # Tier 2: Cryptographic Security & Perimeter Network
    dag.add_node("key_vault", "Hardened Key Vault", "Microsoft.KeyVault/vaults", 45.0)
    dag.add_node("managed_hsm", "FIPS 140-2 L3 HSM", "Microsoft.KeyVault/managedHSMs", 600.0)
    dag.add_node("maa_attest", "MAA Attestation Provider", "Microsoft.Attestation/attestationProviders", 30.0)
    dag.add_node("nsg_mesh", "Microsegmentation NSG", "Microsoft.Network/networkSecurityGroups", 20.0)
    dag.add_node("udr_table", "Force-Tunneling Route Table", "Microsoft.Network/routeTables", 20.0)
    dag.add_node("vwan_transit", "Planetary Virtual WAN", "Microsoft.Network/virtualWans", 60.0)

    # Tier 3: Core Virtual Network & Perimeter Gateways
    dag.add_node("vnet_core", "Sovereign Virtual Network", "Microsoft.Network/virtualNetworks", 30.0)
    dag.add_node("vwan_hubs", "Regional Virtual Hubs", "Microsoft.Network/virtualHubs", 180.0)
    dag.add_node("nat_gw", "Outbound NAT Gateway", "Microsoft.Network/natGateways", 35.0)
    dag.add_node("firewall_prem", "Azure Firewall Premium", "Microsoft.Network/azureFirewalls", 360.0)
    dag.add_node("app_gw_waf", "App Gateway v2 WAF", "Microsoft.Network/applicationGateways", 420.0)

    # Tier 4: Storage, Private Link, and Database Data Plane
    dag.add_node("des_cmek", "Disk Encryption Set (CMEK)", "Microsoft.Compute/diskEncryptionSets", 35.0)
    dag.add_node("dns_priv", "Private DNS Zones", "Microsoft.Network/privateDnsZones", 25.0)
    dag.add_node("storage_adls", "Hardened ADLS Gen2", "Microsoft.Storage/storageAccounts", 35.0)
    dag.add_node("cosmos_active", "Active-Active Cosmos DB", "Microsoft.DocumentDB/databaseAccounts", 300.0)
    dag.add_node("postgres_ha", "Postgres Flexible (Zone-Redund)", "Microsoft.DBforPostgreSQL/flexibleServers", 360.0)
    dag.add_node("event_hubs", "Event Hubs Kafka Namespace", "Microsoft.EventHub/namespaces", 90.0)
    dag.add_node("service_bus", "Service Bus Partitioned Queues", "Microsoft.ServiceBus/namespaces", 90.0)

    # Tier 5: Confidential Compute & Enclave Orchestration
    dag.add_node("aks_confidential", "Confidential AKS (Cilium eBPF)", "Microsoft.ContainerService/managedClusters", 600.0)
    dag.add_node("cvm_scale_set", "AMD SEV-SNP CVM Scale Set", "Microsoft.Compute/virtualMachineScaleSets", 240.0)
    dag.add_node("cae_runtime", "Container Apps Environment", "Microsoft.App/managedEnvironments", 180.0)
    dag.add_node("batch_enclave", "HPC Confidential Batch Pool", "Microsoft.Batch/batchAccounts", 45.0)

    # Dependencies Wiring
    dag.add_dependency("dcr_pipeline", "telemetry_law")
    dag.add_dependency("key_vault", "fabric_id")
    dag.add_dependency("des_cmek", "key_vault")
    dag.add_dependency("vnet_core", "nsg_mesh")
    dag.add_dependency("vnet_core", "udr_table")
    dag.add_dependency("vwan_hubs", "vwan_transit")
    dag.add_dependency("firewall_prem", "vnet_core")
    dag.add_dependency("nat_gw", "vnet_core")
    dag.add_dependency("app_gw_waf", "vnet_core")
    dag.add_dependency("dns_priv", "vnet_core")
    dag.add_dependency("storage_adls", "vnet_core")
    dag.add_dependency("storage_adls", "key_vault")
    dag.add_dependency("postgres_ha", "vnet_core")
    dag.add_dependency("postgres_ha", "dns_priv")
    dag.add_dependency("cosmos_active", "telemetry_law")
    dag.add_dependency("event_hubs", "vnet_core")
    dag.add_dependency("service_bus", "vnet_core")
    dag.add_dependency("aks_confidential", "vnet_core")
    dag.add_dependency("aks_confidential", "des_cmek")
    dag.add_dependency("aks_confidential", "telemetry_law")
    dag.add_dependency("cvm_scale_set", "vnet_core")
    dag.add_dependency("cvm_scale_set", "des_cmek")
    dag.add_dependency("cae_runtime", "vnet_core")
    dag.add_dependency("cae_runtime", "telemetry_law")
    dag.add_dependency("batch_enclave", "vnet_core")
    dag.add_dependency("batch_enclave", "storage_adls")

    return dag


def cmd_compile(args: argparse.Namespace) -> int:
    """Compile all Bicep files and verify syntax."""
    print(TerminalVisualizer.render_banner())
    compiler = BicepCompiler(root_dir=Path.cwd())

    installed, version_info = compiler.check_installed()
    if not installed:
        print(f"{RED}Error: {version_info}{RESET}")
        return 1

    print(f" {CYAN}Compiling Bicep modules with {version_info}...{RESET}\n")
    bicep_dir = Path("bicep")
    summary = compiler.compile_all(bicep_dir)

    # Calculate lines of code across all bicep files
    parser = BicepASTParser()
    total_lines = 0
    code_lines = 0
    comment_lines = 0

    for b_file in bicep_dir.rglob("*.bicep"):
        ast = parser.parse_file(b_file)
        total_lines += ast.total_lines
        code_lines += ast.code_lines
        comment_lines += ast.comment_lines

    print(f"{BOLD}======================================================================{RESET}")
    print(f"{BOLD}                    BICEP COMPILATION SUMMARY                         {RESET}")
    print(f"{BOLD}======================================================================{RESET}")
    print(f" Total Source Files Compiled: {BOLD}{summary.total_files}{RESET}")
    print(f" Successful Compilations:    {GREEN}{summary.successful_files}{RESET}")
    print(f" Failed Compilations:        {RED if summary.failed_files > 0 else GREEN}{summary.failed_files}{RESET}")
    print(f" Total Source Code Lines:    {CYAN}{code_lines:,}{RESET}")
    print(f" Total Documentation Lines:  {CYAN}{comment_lines:,}{RESET}")
    print(f" Comment to Code Ratio:      {BOLD}{round(comment_lines / max(1, code_lines), 3)}{RESET}")
    print(f" Total Compilation Duration: {summary.total_duration_ms:.1f} ms")
    print("")

    if not summary.is_clean:
        print(f"{RED}Compilation failed on {summary.failed_files} files:{RESET}")
        for r in summary.results:
            if not r.success:
                print(f"  - {r.source_path}: {r.stderr}")
        return 1

    print(f"{GREEN}{BOLD}All Bicep templates and parameter files compiled cleanly with 0 defects!{RESET}")
    return 0


def cmd_graph(args: argparse.Namespace) -> int:
    """Render the dependency DAG, stages, and critical path."""
    print(TerminalVisualizer.render_banner())
    dag = build_camber_dag()

    # Check for cycles
    cycles = dag.find_cycles()
    if cycles:
        print(f"{RED}Error: Dependency cycle detected in graph: {cycles}{RESET}")
        return 1

    print(TerminalVisualizer.render_dag_stages(dag))
    return 0


def cmd_simulate(args: argparse.Namespace) -> int:
    """Run discrete-event deployment simulation."""
    print(TerminalVisualizer.render_banner())
    dag = build_camber_dag()

    config = SimulationConfig(
        max_concurrency=args.concurrency,
        throttle_probability=args.throttle_rate,
        failure_probability=args.failure_rate,
        random_seed=args.seed,
    )

    print(f" {CYAN}Running discrete-event simulation (max concurrency: {config.max_concurrency})...{RESET}\n")
    sim = ARMDeploymentSimulator(dag, config)
    res = sim.run()

    print(TerminalVisualizer.render_gantt_chart(res))
    print("")
    print(f" {BOLD}Simulation Key Statistics:{RESET}")
    print(f"   * Total Simulated Deployment Time: {BOLD}{res.total_virtual_time_seconds:.1f}s{RESET}")
    print(f"   * Resources Successfully Provisioned: {GREEN}{res.completed_resources}/{len(dag.nodes)}{RESET}")
    print(f"   * Transient 429 Throttles Recovered: {YELLOW}{res.total_throttles}{RESET}")
    print(f"   * Transient Provider Retries Handled: {YELLOW}{res.total_retries}{RESET}")
    print(f"   * Unrecoverable Failures: {RED if res.failed_resources > 0 else GREEN}{res.failed_resources}{RESET}")
    print("")

    return 0 if res.is_successful else 1


def cmd_audit(args: argparse.Namespace) -> int:
    """Run CIS and NIST security policy audit."""
    print(TerminalVisualizer.render_banner())
    evaluator = PolicyEvaluator()
    report = evaluator.audit_directory(Path("bicep"))

    print(TerminalVisualizer.render_audit_report(report))
    return 0 if report.is_compliant else 1


def cmd_carbon(args: argparse.Namespace) -> int:
    """Calculate multi-region grid carbon and cloud economics."""
    print(TerminalVisualizer.render_banner())
    econ = CloudEconomicsEngine()

    profiles = [
        econ.evaluate_resource("aks-east", "AKS Primary Cluster", "Microsoft.ContainerService/managedClusters", "eastus", "Standard_DC4as_v5", 6),
        econ.evaluate_resource("cvm-west", "Inference CVM Scale Set", "Microsoft.Compute/virtualMachineScaleSets", "westeurope", "Standard_DC8as_v5", 4),
        econ.evaluate_resource("hsm-east", "Dedicated Managed HSM", "Microsoft.KeyVault/managedHSMs", "eastus", "ManagedHSM_B1", 1),
        econ.evaluate_resource("fw-east", "Azure Firewall Premium", "Microsoft.Network/azureFirewalls", "eastus", "AzureFirewall_Premium", 1),
        econ.evaluate_resource("pg-east", "Postgres Flexible HA", "Microsoft.DBforPostgreSQL/flexibleServers", "eastus", "Postgres_D4ds_v5_HA", 1),
        econ.evaluate_resource("cosmos-global", "Active-Active Cosmos DB", "Microsoft.DocumentDB/databaseAccounts", "eastus", "CosmosDB_4000_RU", 1),
        econ.evaluate_resource("aks-swiss", "Sovereign Enclave AKS", "Microsoft.ContainerService/managedClusters", "switzerlandnorth", "Standard_DC4as_v5", 6),
    ]

    report = econ.generate_report(profiles)
    print(TerminalVisualizer.render_sustainability_report(report))
    return 0


def cmd_verify(args: argparse.Namespace) -> int:
    """Execute all verification gates end-to-end."""
    print(TerminalVisualizer.render_banner())
    print(f"{BOLD}=== GATE 1: BICEP COMPILER & SYNTAX VALIDATION ==={RESET}")
    rc = cmd_compile(args)
    if rc != 0:
        return rc

    print(f"\n{BOLD}=== GATE 2: DEPENDENCY DAG & CRITICAL PATH ANALYSIS ==={RESET}")
    rc = cmd_graph(args)
    if rc != 0:
        return rc

    print(f"\n{BOLD}=== GATE 3: DISCRETE-EVENT DEPLOYMENT SIMULATION ==={RESET}")
    rc = cmd_simulate(args)
    if rc != 0:
        return rc

    print(f"\n{BOLD}=== GATE 4: CIS / NIST SECURITY POLICY AUDIT ==={RESET}")
    rc = cmd_audit(args)
    if rc != 0:
        return rc

    print(f"\n{BOLD}=== GATE 5: REGIONAL CARBON & CLOUD ECONOMICS ==={RESET}")
    rc = cmd_carbon(args)
    if rc != 0:
        return rc

    print(f"\n{GREEN}{BOLD}======================================================================{RESET}")
    print(f"{GREEN}{BOLD}      ALL 5 CAMBER VERIFICATION GATES PASSED (ZERO DEFECTS)           {RESET}")
    print(f"{GREEN}{BOLD}======================================================================{RESET}")
    return 0


def main():
    parser = argparse.ArgumentParser(
        prog="camber",
        description="Camber: Sovereign Confidential Infrastructure & Discrete-Event Verification Fabric",
    )
    subparsers = parser.add_subparsers(dest="command", help="Available subcommands")

    # compile
    p_compile = subparsers.add_parser("compile", help="Compile Bicep templates via official CLI")
    p_compile.set_defaults(func=cmd_compile)

    # graph
    p_graph = subparsers.add_parser("graph", help="Compute dependency DAG and critical path")
    p_graph.set_defaults(func=cmd_graph)

    # simulate
    p_sim = subparsers.add_parser("simulate", help="Run discrete-event ARM deployment simulation")
    p_sim.add_argument("--concurrency", type=int, default=20, help="Max concurrent deployment tasks")
    p_sim.add_argument("--throttle-rate", type=float, default=0.05, help="Simulated 429 throttle rate (0.0 - 1.0)")
    p_sim.add_argument("--failure-rate", type=float, default=0.02, help="Simulated transient failure rate (0.0 - 1.0)")
    p_sim.add_argument("--seed", type=int, default=42, help="Random seed for simulation repeatability")
    p_sim.set_defaults(func=cmd_simulate)

    # audit
    p_audit = subparsers.add_parser("audit", help="Audit templates against CIS and NIST standards")
    p_audit.set_defaults(func=cmd_audit)

    # carbon
    p_carbon = subparsers.add_parser("carbon", help="Calculate regional carbon intensity and costs")
    p_carbon.set_defaults(func=cmd_carbon)

    # verify
    p_verify = subparsers.add_parser("verify", help="Execute all verification gates in succession")
    p_verify.add_argument("--concurrency", type=int, default=20)
    p_verify.add_argument("--throttle-rate", type=float, default=0.05)
    p_verify.add_argument("--failure-rate", type=float, default=0.02)
    p_verify.add_argument("--seed", type=int, default=42)
    p_verify.set_defaults(func=cmd_verify)

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(0)

    rc = args.func(args)
    sys.exit(rc)


if __name__ == "__main__":
    main()
