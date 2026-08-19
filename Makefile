.PHONY: setup synth sta formal optimize dashboard test clean

setup:
	python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt

# Person 1: run Yosys synthesis on a given module
synth:
	@echo "TODO (Person 1): call synthesis/scripts/*.ys via yosys"

# Person 1: run OpenSTA timing analysis
sta:
	@echo "TODO (Person 1): call sta/scripts/*.tcl via sta"

# Person 3: run formal equivalence check
formal:
	@echo "TODO (Person 3): call formal/scripts/*.sby via sby"

# Person 2/3: run the closed-loop optimizer
optimize:
	@echo "TODO: python optimizer/engine.py"

# Person 3: launch the dashboard
dashboard:
	streamlit run dashboard/app.py

test:
	pytest tests/ -v

clean:
	find . -name "__pycache__" -exec rm -rf {} +
	rm -rf synthesis/netlists/* synthesis/logs/* sta/logs/* openroad/logs/* formal/logs/*
