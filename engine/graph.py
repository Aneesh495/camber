"""
Camber Dependency Graph Compiler and Critical Path Engine.
Builds resource dependency DAGs, verifies acyclicity via Tarjan's SCC algorithm,
computes Kahn topological orderings, and solves the Critical Path Method (CPM).
"""

from collections import defaultdict, deque
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Set, Tuple


@dataclass
class GraphNode:
    id: str
    name: str
    resource_type: str
    estimated_duration_seconds: float = 30.0
    earliest_start: float = 0.0
    earliest_finish: float = 0.0
    latest_start: float = 0.0
    latest_finish: float = 0.0
    slack: float = 0.0
    is_critical: bool = False
    dependencies: Set[str] = field(default_factory=set)
    dependents: Set[str] = field(default_factory=set)


# Standard baseline provisioning latency estimates for Azure Resource Providers (in seconds)
DEFAULT_RESOURCE_DURATIONS: Dict[str, float] = {
    "Microsoft.ContainerService/managedClusters": 600.0,
    "Microsoft.DBforPostgreSQL/flexibleServers": 360.0,
    "Microsoft.DocumentDB/databaseAccounts": 300.0,
    "Microsoft.Compute/virtualMachineScaleSets": 240.0,
    "Microsoft.Network/azureFirewalls": 360.0,
    "Microsoft.Network/applicationGateways": 420.0,
    "Microsoft.Network/virtualWans": 60.0,
    "Microsoft.Network/virtualHubs": 180.0,
    "Microsoft.KeyVault/vaults": 45.0,
    "Microsoft.KeyVault/managedHSMs": 600.0,
    "Microsoft.Storage/storageAccounts": 35.0,
    "Microsoft.Network/virtualNetworks": 30.0,
    "Microsoft.Network/networkSecurityGroups": 20.0,
    "Microsoft.Network/routeTables": 20.0,
    "Microsoft.Network/privateEndpoints": 60.0,
    "Microsoft.OperationalInsights/workspaces": 45.0,
    "Microsoft.EventHub/namespaces": 90.0,
    "Microsoft.ServiceBus/namespaces": 90.0,
    "Microsoft.Batch/batchAccounts": 45.0,
    "Microsoft.App/managedEnvironments": 180.0,
    "Microsoft.ManagedIdentity/userAssignedIdentities": 15.0,
    "Microsoft.Authorization/roleAssignments": 20.0,
    "Microsoft.Authorization/roleDefinitions": 25.0,
    "Microsoft.Authorization/policyDefinitions": 20.0,
    "Microsoft.Authorization/policySetDefinitions": 25.0,
    "Microsoft.Authorization/policyAssignments": 20.0,
}


class DependencyDAG:
    """Directed Acyclic Graph representing cloud infrastructure provisioning dependencies."""

    def __init__(self):
        self.nodes: Dict[str, GraphNode] = {}

    def add_node(
        self,
        node_id: str,
        name: str,
        resource_type: str,
        duration_seconds: Optional[float] = None,
    ) -> GraphNode:
        """Register a node in the graph."""
        if duration_seconds is None:
            duration_seconds = DEFAULT_RESOURCE_DURATIONS.get(resource_type, 30.0)

        if node_id not in self.nodes:
            self.nodes[node_id] = GraphNode(
                id=node_id,
                name=name,
                resource_type=resource_type,
                estimated_duration_seconds=duration_seconds,
            )
        return self.nodes[node_id]

    def add_dependency(self, dependent_id: str, depends_on_id: str) -> None:
        """Add a directed edge: dependent_id depends on depends_on_id."""
        if dependent_id not in self.nodes or depends_on_id not in self.nodes:
            return
        self.nodes[dependent_id].dependencies.add(depends_on_id)
        self.nodes[depends_on_id].dependents.add(dependent_id)

    def find_cycles(self) -> List[List[str]]:
        """Identify circular dependency components using Tarjan's Strongly Connected Components algorithm."""
        index = 0
        indices: Dict[str, int] = {}
        lowlinks: Dict[str, int] = {}
        on_stack: Set[str] = set()
        stack: List[str] = []
        sccs: List[List[str]] = []

        def strongconnect(v: str):
            nonlocal index
            indices[v] = index
            lowlinks[v] = index
            index += 1
            stack.append(v)
            on_stack.add(v)

            for w in self.nodes[v].dependencies:
                if w not in indices:
                    strongconnect(w)
                    lowlinks[v] = min(lowlinks[v], lowlinks[w])
                elif w in on_stack:
                    lowlinks[v] = min(lowlinks[v], indices[w])

            if lowlinks[v] == indices[v]:
                scc = []
                while True:
                    w = stack.pop()
                    on_stack.remove(w)
                    scc.append(w)
                    if w == v:
                        break
                if len(scc) > 1:
                    sccs.append(scc)

        for node_id in self.nodes:
            if node_id not in indices:
                strongconnect(node_id)

        return sccs

    def topological_sort(self) -> List[str]:
        """Compute execution order using Kahn's algorithm."""
        in_degrees = {n_id: len(node.dependencies) for n_id, node in self.nodes.items()}
        zero_in_degree = deque([n_id for n_id, deg in in_degrees.items() if deg == 0])
        order = []

        while zero_in_degree:
            curr = zero_in_degree.popleft()
            order.append(curr)

            for neighbor in self.nodes[curr].dependents:
                in_degrees[neighbor] -= 1
                if in_degrees[neighbor] == 0:
                    zero_in_degree.append(neighbor)

        if len(order) != len(self.nodes):
            cycles = self.find_cycles()
            raise ValueError(f"Dependency cycle detected in graph: {cycles}")

        return order

    def compute_critical_path(self) -> Tuple[List[str], float]:
        """
        Solve the Critical Path Method (CPM).
        Forward pass calculates earliest start/finish times.
        Backward pass calculates latest start/finish times and float slack.
        Returns the critical path node IDs and total critical duration in seconds.
        """
        order = self.topological_sort()

        # Forward Pass
        for node_id in order:
            node = self.nodes[node_id]
            if not node.dependencies:
                node.earliest_start = 0.0
            else:
                node.earliest_start = max(
                    self.nodes[dep_id].earliest_finish for dep_id in node.dependencies
                )
            node.earliest_finish = node.earliest_start + node.estimated_duration_seconds

        total_project_duration = max(node.earliest_finish for node in self.nodes.values()) if self.nodes else 0.0

        # Backward Pass
        reversed_order = list(reversed(order))
        for node_id in reversed_order:
            node = self.nodes[node_id]
            if not node.dependents:
                node.latest_finish = total_project_duration
            else:
                node.latest_finish = min(
                    self.nodes[dep_id].latest_start for dep_id in node.dependents
                )
            node.latest_start = node.latest_finish - node.estimated_duration_seconds
            node.slack = round(node.latest_start - node.earliest_start, 4)
            node.is_critical = abs(node.slack) < 1e-4

        critical_path = [node_id for node_id in order if self.nodes[node_id].is_critical]
        return critical_path, total_project_duration

    def get_stages(self) -> List[List[str]]:
        """Partition nodes into parallel deployment stages."""
        order = self.topological_sort()
        stages: List[List[str]] = []
        node_stage: Dict[str, int] = {}

        for node_id in order:
            node = self.nodes[node_id]
            if not node.dependencies:
                stage_idx = 0
            else:
                stage_idx = max(node_stage[dep] for dep in node.dependencies) + 1
            node_stage[node_id] = stage_idx

            while len(stages) <= stage_idx:
                stages.append([])
            stages[stage_idx].append(node_id)

        return stages
