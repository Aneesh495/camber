"""
Camber Discrete-Event Deployment Simulator.
Simulates Azure Resource Manager (ARM) engine scheduling, concurrency bounds,
transient HTTP 429 throttling, exponential backoff with jitter, and fault injection.
"""

from collections import defaultdict
from dataclasses import dataclass, field
import heapq
import random
import time
from typing import Dict, List, Optional, Set, Tuple

from engine.graph import DependencyDAG, GraphNode


@dataclass(order=True)
class SimulationEvent:
    timestamp: float
    event_type: str = field(compare=False)
    resource_id: str = field(compare=False)
    payload: Dict = field(default_factory=dict, compare=False)


@dataclass
class ResourceStateRecord:
    resource_id: str
    name: str
    status: str
    scheduled_time: float = 0.0
    start_time: float = 0.0
    end_time: float = 0.0
    retry_count: int = 0
    throttle_count: int = 0
    failure_reason: Optional[str] = None

    @property
    def duration(self) -> float:
        return max(0.0, self.end_time - self.start_time)


@dataclass
class SimulationConfig:
    max_concurrency: int = 20
    max_requests_per_second: float = 10.0
    throttle_probability: float = 0.05
    failure_probability: float = 0.02
    max_retry_attempts: int = 5
    base_backoff_seconds: float = 2.0
    max_backoff_seconds: float = 60.0
    enable_jitter: bool = True
    random_seed: int = 42


@dataclass
class SimulationResult:
    total_virtual_time_seconds: float
    completed_resources: int
    failed_resources: int
    total_retries: int
    total_throttles: int
    event_log: List[Tuple[float, str, str]] = field(default_factory=list)
    resource_records: Dict[str, ResourceStateRecord] = field(default_factory=dict)

    @property
    def is_successful(self) -> bool:
        return self.failed_resources == 0


class ARMDeploymentSimulator:
    """Discrete-event simulation engine for ARM deployment pipelines."""

    def __init__(self, dag: DependencyDAG, config: Optional[SimulationConfig] = None):
        self.dag = dag
        self.config = config or SimulationConfig()
        self.rng = random.Random(self.config.random_seed)

    def run(self) -> SimulationResult:
        """Execute the discrete event simulation."""
        event_queue: List[SimulationEvent] = []
        current_time = 0.0
        active_jobs = 0
        completed: Set[str] = set()
        failed: Set[str] = set()

        records: Dict[str, ResourceStateRecord] = {
            node_id: ResourceStateRecord(
                resource_id=node_id,
                name=node.name,
                status="PENDING",
            )
            for node_id, node in self.dag.nodes.items()
        }

        event_log: List[Tuple[float, str, str]] = []

        # Find initial ready nodes (nodes with 0 dependencies)
        for node_id, node in self.dag.nodes.items():
            if not node.dependencies:
                records[node_id].status = "READY"
                heapq.heappush(
                    event_queue,
                    SimulationEvent(
                        timestamp=current_time,
                        event_type="RESOURCE_READY",
                        resource_id=node_id,
                    ),
                )

        waiting_queue: List[str] = []
        recent_request_timestamps: List[float] = []

        def log_event(t: float, event_type: str, r_id: str):
            event_log.append((round(t, 2), event_type, r_id))

        total_retries = 0
        total_throttles = 0

        while event_queue or waiting_queue:
            # Drain ready tasks from waiting queue if concurrency and rate limits permit
            while waiting_queue and active_jobs < self.config.max_concurrency:
                # Rate limit pruning
                cutoff = current_time - 1.0
                recent_request_timestamps = [
                    ts for ts in recent_request_timestamps if ts >= cutoff
                ]

                if len(recent_request_timestamps) >= self.config.max_requests_per_second:
                    # Rate limit exceeded, schedule wakeup at oldest timestamp + 1.0s
                    earliest = recent_request_timestamps[0]
                    next_slot = earliest + 1.001
                    if next_slot > current_time:
                        heapq.heappush(
                            event_queue,
                            SimulationEvent(
                                timestamp=next_slot,
                                event_type="SLOT_AVAILABLE",
                                resource_id="",
                            ),
                        )
                        break

                candidate_id = waiting_queue.pop(0)
                recent_request_timestamps.append(current_time)
                active_jobs += 1

                rec = records[candidate_id]
                rec.status = "IN_PROGRESS"
                rec.start_time = current_time
                log_event(current_time, "START_PROVISIONING", candidate_id)

                # Simulate transient throttle (HTTP 429)
                is_throttled = self.rng.random() < self.config.throttle_probability
                if is_throttled and rec.retry_count < self.config.max_retry_attempts:
                    rec.status = "THROTTLED"
                    rec.throttle_count += 1
                    total_throttles += 1
                    active_jobs -= 1

                    backoff = min(
                        self.config.max_backoff_seconds,
                        self.config.base_backoff_seconds * (2 ** rec.retry_count),
                    )
                    if self.config.enable_jitter:
                        backoff += self.rng.uniform(0.1, 1.0)
                    retry_time = current_time + backoff
                    rec.retry_count += 1
                    log_event(current_time, "HTTP_429_THROTTLED", candidate_id)

                    heapq.heappush(
                        event_queue,
                        SimulationEvent(
                            timestamp=retry_time,
                            event_type="RESOURCE_READY",
                            resource_id=candidate_id,
                        ),
                    )
                    continue

                # Simulate transient provider failure
                is_failed = self.rng.random() < self.config.failure_probability
                if is_failed:
                    if rec.retry_count < self.config.max_retry_attempts:
                        rec.status = "TRANSIENT_FAILURE"
                        rec.retry_count += 1
                        total_retries += 1
                        active_jobs -= 1
                        backoff = self.config.base_backoff_seconds * (2 ** rec.retry_count)
                        if self.config.enable_jitter:
                            backoff += self.rng.uniform(0.5, 2.0)
                        retry_time = current_time + backoff
                        log_event(current_time, "TRANSIENT_FAILURE", candidate_id)

                        heapq.heappush(
                            event_queue,
                            SimulationEvent(
                                timestamp=retry_time,
                                event_type="RESOURCE_READY",
                                resource_id=candidate_id,
                            ),
                        )
                        continue
                    else:
                        # Terminal failure
                        rec.status = "FAILED"
                        rec.end_time = current_time
                        active_jobs -= 1
                        failed.add(candidate_id)
                        log_event(current_time, "TERMINAL_FAILURE", candidate_id)
                        continue

                # Normal provisioning duration with slight stochastic noise
                base_duration = self.dag.nodes[candidate_id].estimated_duration_seconds
                actual_duration = max(1.0, self.rng.gauss(base_duration, base_duration * 0.05))
                finish_time = current_time + actual_duration

                heapq.heappush(
                    event_queue,
                    SimulationEvent(
                        timestamp=finish_time,
                        event_type="RESOURCE_COMPLETED",
                        resource_id=candidate_id,
                    ),
                )

            if not event_queue:
                break

            event = heapq.heappop(event_queue)
            current_time = max(current_time, event.timestamp)

            if event.event_type == "RESOURCE_READY":
                waiting_queue.append(event.resource_id)
                log_event(current_time, "QUEUED", event.resource_id)

            elif event.event_type == "SLOT_AVAILABLE":
                pass

            elif event.event_type == "RESOURCE_COMPLETED":
                active_jobs -= 1
                completed.add(event.resource_id)
                rec = records[event.resource_id]
                rec.status = "COMPLETED"
                rec.end_time = current_time
                log_event(current_time, "COMPLETED", event.resource_id)

                # Check downstream dependents
                for dependent_id in self.dag.nodes[event.resource_id].dependents:
                    if records[dependent_id].status == "PENDING":
                        # If all dependencies are completed, queue it
                        dep_node = self.dag.nodes[dependent_id]
                        if all(d in completed for d in dep_node.dependencies):
                            records[dependent_id].status = "READY"
                            heapq.heappush(
                                event_queue,
                                SimulationEvent(
                                    timestamp=current_time,
                                    event_type="RESOURCE_READY",
                                    resource_id=dependent_id,
                                ),
                            )

        return SimulationResult(
            total_virtual_time_seconds=round(current_time, 2),
            completed_resources=len(completed),
            failed_resources=len(failed),
            total_retries=total_retries,
            total_throttles=total_throttles,
            event_log=event_log,
            resource_records=records,
        )
