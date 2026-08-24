# Roadmap

| Phase | Days | Focus |
|---|---|---|
| 0 | 0–1 | Team setup — repo, docs, board |
| 1 | 1–3 | Environment — tools installed, test module working |
| 2 | 3–7 | Baseline EDA flow — Yosys + OpenSTA + parser + SDC |
| 3 | 7–14 | GenAI — LLM client, prompts, candidate generation |
| 4 | 10–18 | Formal verification — SymbiYosys/EQY flow |
| 5 | 14–20 | Closed-loop optimizer — full pipeline integration |
| 6 | 16–22 | Benchmark — 50K-cell design with 5 clocks, CDC, dividers |
| 7 | 22–25 | PPA comparison — baseline vs optimized |
| 8 | 20–27 | Dashboard — Streamlit visualization |
| 9 | 26–30 | Final report, demo, polish |

Final event day and presentations: **25 September**.

## Day 0

- [ ] Person 3 creates the GitHub repo with the full directory structure
- [ ] All 3 clone the repo, set up Python env, install tools (Yosys, OpenSTA, SymbiYosys)
- [ ] Person 1 creates `rtl/testcases/test_counter.sv` (8-bit counter, 1 clock)
- [ ] Person 1 writes a basic Yosys synthesis script + SDC, runs synthesis
- [ ] All 3 run the same synthesis locally to verify toolchain works

## Day 1

- [ ] Person 1 leads: run OpenSTA on the synthesized netlist, generate timing report
- [ ] All 3 examine the timing report, understand WNS/TNS/critical path
- [ ] Person 1 writes basic Python parser to extract timing data to JSON
- [ ] All 3 collaboratively finalize `docs/ARCHITECTURE.md` and `docs/INTERFACES.md`
- [ ] Person 3 sets up the GitHub Project board

## Day 2 — specialize

- [ ] Person 1: refine Yosys + OpenSTA scripts (parameterized for any module)
- [ ] Person 2: set up LLM API client, write first prompt template (pipelining)
- [ ] Person 3: write SymbiYosys equivalence config, test PASS + FAIL cases
- [ ] End of day: 15-min sync, each person demos what they built

### Day 2 exit criteria

- [ ] All 3 have working EDA toolchain locally
- [ ] Synthesis + STA works on the test module
- [ ] Timing report → JSON parser exists
- [ ] LLM API client connects and returns a response
- [ ] Formal equivalence check runs (PASS and FAIL)
- [ ] `docs/ARCHITECTURE.md` and `docs/INTERFACES.md` committed
- [ ] GitHub Project board is live
- [ ] Each person has their own branch with at least 1 commit
