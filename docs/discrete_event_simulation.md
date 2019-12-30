# Discrete-Event Deployment Simulation Specification

## 1. Mathematical Modeling of the ARM Scheduling Engine

Cloud deployments do not occur instantaneously or sequentially: they operate as a discrete-event distributed workflow subject to concurrency caps, provider latency distributions, transient throttling, and dependency constraints.

Camber includes a native discrete-event simulator that models Azure Resource Manager (ARM) scheduling dynamics using priority queue event scheduling:

$$\mathcal{E} = \{(t_i, e_i, r_i) \mid t_i \in \mathbb{R}^+, e_i \in \text{EventType}, r_i \in \text{ResourceID}\}$$

Where virtual time advances monotonically to the head timestamp of the priority queue:

$$t_{\text{current}} = \min_{(t, e, r) \in \mathcal{E}} t$$

---

## 2. Queueing Theory & Concurrency Invariants

The simulator enforces a dual-constraint scheduling window:

1. **Maximum Active Concurrency ($C_{\max}$)**: At most $C_{\max}$ deployment tasks may execute simultaneously:
$$N_{\text{active}}(t) \le C_{\max}$$

2. **Leaky Bucket Request Rate ($R_{\max}$)**: Egress dispatch rates are bounded within any rolling 1.0-second window:
$$\left| \{ \tau \in \text{Dispatches} \mid t - 1.0 \le \tau \le t \} \right| \le R_{\max}$$

---

## 3. Throttling & Exponential Backoff with Jitter

When rate limits or provider quotas are exceeded, the simulated ARM engine returns an HTTP 429 Too Many Requests response. Camber implements exponential backoff with full randomized jitter to prevent thundering herd resynchronization:

$$\text{Backoff}(k) = \min\left(T_{\max}, T_{\text{base}} \cdot 2^k\right) + \text{Uniform}(0, J)$$

Where $k$ is the attempt counter, $T_{\text{base}} = 2.0\text{s}$, $T_{\max} = 60.0\text{s}$, and $J$ is the jitter spread.
