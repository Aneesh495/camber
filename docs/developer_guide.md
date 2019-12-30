# Camber Developer & Verification Guide

## 1. Prerequisites & Environment Setup

Camber is designed with zero external package dependencies. The engine runs on native Python 3 standard libraries and interacts directly with the official Bicep CLI.

### Prerequisites
- **Python**: Version 3.10+ (using standard library modules only)
- **Bicep CLI**: Version 0.20+ (v0.49.2 recommended)
- **Make**: Standard GNU Make utility

### Verification of Tools
```bash
# Verify Python 3
python3 --version

# Verify Bicep CLI
bicep --version
```

---

## 2. Command-Line Interface (CLI) Commands

The unified `./camber` executable provides tools for analyzing, verifying, and simulating cloud infrastructure:

```bash
# Display help and available commands
./camber --help

# Compile all Bicep source files and parameter files
./camber compile

# Compute dependency DAG, parallel stages, and critical path
./camber graph

# Execute discrete-event deployment simulation with Gantt timeline
./camber simulate --concurrency 20 --throttle-rate 0.05 --failure-rate 0.02

# Run static CIS Azure and NIST SP 800-53 security policy audit
./camber audit

# Calculate regional carbon emissions and monthly cloud OPEX
./camber carbon

# Execute all 5 verification gates in succession
./camber verify
```

---

## 3. Running Automated Test Suites

Camber provides comprehensive unit, integration, and regression test suites:

```bash
# Run all test suites via Python unittest discovery
python3 -m unittest discover -s tests -p "test_*.py" -v

# Run specific test modules
python3 -m unittest tests.test_bicep_compilation -v
python3 -m unittest tests.test_graph_dag -v
python3 -m unittest tests.test_simulator -v
python3 -m unittest tests.test_policy_evaluator -v
python3 -m unittest tests.test_cost_carbon -v
python3 -m unittest tests.test_cli -v
python3 -m unittest tests.test_regressions -v
python3 -m unittest tests.test_em_dash_audit -v

# Or use the top-level Makefile
make test
make verify
```

---

## 4. Coding Standards & Invariant Maintenance

When authoring new Bicep modules or engine extensions:
1. Every new `.bicep` file must compile with zero errors and zero warnings via `bicep build`.
2. Do not use em dashes in comments, docstrings, or markdown files. Run `make em-dash-audit` to verify compliance.
3. Every detected bug must be documented with a reproducing regression test in `tests/test_regressions.py`.
