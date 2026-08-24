# Architecture

**Status: DRAFT — finalize together on Day 1.**

## Core principle

AI suggests. EDA measures. Formal verification decides whether the optimization is functionally safe.

## Pipeline

```
BENCHMARK RTL
     |
     v
  Yosys (synthesis)
     |
Gate-level netlist
     |
     v
 OpenSTA (timing analysis)
     |
Timing report + critical paths
     |
     v
Python engine -> LLM
     |
Optimization candidates (SystemVerilog)
     |
     v
Formal equivalence check (SymbiYosys / EQY)
    /        \
 FAIL        PASS
  |            |
Reject         v
           Re-synthesis + Re-STA
               |
               v
           PPA data (area, power, frequency)
               |
               v
          Candidate ranking
               |
               v
          Best candidate
               |
               +----> iterate if needed
```

## Repository layout

```
genai-rtl-optimizer/
├── rtl/
│   ├── benchmark/          # 50K-cell benchmark RTL (IMMUTABLE after baseline)
│   ├── testcases/          # Small RTL modules for development/testing
│   ├── candidates/         # GenAI-generated candidate RTLs
│   └── accepted/           # Formally-verified & timing-improved candidates
├── constraints/            # SDC clock/timing constraints
├── libs/                   # PDK liberty files (e.g., Sky130)
├── synthesis/               # Yosys scripts, netlists, logs
├── sta/                     # OpenSTA scripts, reports, logs
├── openroad/                # OpenROAD scripts, results, logs
├── formal/                  # SymbiYosys / EQY configs, results, logs
├── optimizer/                # engine.py, parser.py, ranker.py, config.py, utils.py
├── llm/                       # client.py, prompts/, strategies.py, postprocess.py
├── reports/                    # ppa/, formal/, final/
├── experiments/                 # log.jsonl (append-only), README.md
├── dashboard/                     # Streamlit app.py, pages/, components/
├── scripts/                        # Shell automation
├── tests/                           # Unit and integration tests
├── configs/                          # YAML configs
└── docs/                              # this folder
```

## Open questions for Day 1 sync

- [ ] Which PDK / cell library for the baseline (Sky130 assumed — confirm)
- [ ] Which RTL module for `rtl/testcases/test_counter.sv` — confirmed 8-bit counter, 1 clock
- [ ] LLM provider/model for `llm/client.py` (model-agnostic client per spec)
- [ ] Scoring weights for `evaluation_result.json` → `score.weighted_score` (v1)
