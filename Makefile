.PHONY: all compile lint test audit simulate graph carbon verify em-dash-audit clean

PYTHON ?= python3
BICEP ?= bicep

all: verify

compile:
	@echo "=== Compiling Bicep Templates ==="
	@$(PYTHON) -m engine.cli compile

lint:
	@echo "=== Linting Bicep Source Files ==="
	@find bicep -name "*.bicep" -exec $(BICEP) lint {} +

test:
	@echo "=== Running Test Suites ==="
	@$(PYTHON) -m unittest discover -s tests -p "test_*.py" -v

audit:
	@echo "=== Running CIS/NIST Security Policy Audit ==="
	@$(PYTHON) -m engine.cli audit

simulate:
	@echo "=== Running Discrete-Event Deployment Simulator ==="
	@$(PYTHON) -m engine.cli simulate

graph:
	@echo "=== Generating Dependency DAG and Critical Path ==="
	@$(PYTHON) -m engine.cli graph

carbon:
	@echo "=== Calculating Regional Grid Carbon and Cost ==="
	@$(PYTHON) -m engine.cli carbon

em-dash-audit:
	@echo "=== Auditing Repository for Zero Em Dash Invariant ==="
	@$(PYTHON) -m unittest tests.test_em_dash_audit -v

verify: compile test audit simulate graph carbon em-dash-audit
	@echo "==========================================================="
	@echo "  All Camber verification gates passed with zero defects!  "
	@echo "==========================================================="

clean:
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@find . -type f -name "*.pyc" -delete
	@find . -type f -name "*.arm.json" -delete
	@rm -rf out dist .pytest_cache
