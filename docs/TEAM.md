# Team

| | Person 1 — EDA/RTL/Timing | Person 2 — GenAI/Optimization | Person 3 — Formal/Integration/Demo |
|---|---|---|---|
| **Skills** | SystemVerilog, Yosys, OpenSTA, SDC, OpenROAD | Python, LLM APIs, prompt engineering, optimization strategies | SymbiYosys, EQY, Python orchestration, Streamlit, Docker, Git |
| **Owns** | `rtl/benchmark/`, `rtl/testcases/`, `constraints/`, `libs/`, `synthesis/`, `sta/`, `openroad/` | `llm/`, `optimizer/` (except `engine.py`, co-owned), `experiments/`, `configs/llm.yaml`, `configs/optimizer.yaml` | `formal/`, `dashboard/`, `scripts/`, `tests/`, `.github/`, `optimizer/engine.py` (co-owned) |
| **Produces** | `timing_report.json`, `ppa_result.json` | `candidate_XXX.sv` + `candidate_manifest.json` | `formal_result.json`, `evaluation_result.json` |
| **Consumes** | `candidate_XXX.sv` (for re-synth/re-time) | `timing_report.json`, `evaluation_result.json` | `candidate_XXX.sv` + `candidate_manifest.json`, `timing_report.json` + `ppa_result.json` |
| **"Done" means** | Baseline synthesizes cleanly; timing reports parse to valid schema-matching JSON; re-synthesis of any candidate is consistent | Given a `timing_report.json`, produces ≥3 valid SV candidates with documented transformations; experiment log entry written | Formal check runs on any candidate pair and produces valid JSON; full loop runs end-to-end; dashboard displays results |

## Fill in names / GitHub handles

- Person 1:
- Person 2:
- Person 3: (you)
