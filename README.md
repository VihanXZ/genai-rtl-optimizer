# genai-rtl-optimizer

**Nebula@BITS Goa — Astera Labs Hackathon**
Track: *Constraint Optimization through RTL Enhancement Using Generative AI*

## Core principle

> AI suggests. EDA measures. Formal verification decides whether the optimization is functionally safe.

## What this does

1. Analyze RTL against timing constraints (Yosys + OpenSTA)
2. Identify critical paths and timing violations
3. Use an LLM to recommend RTL optimizations (pipelining, logic restructuring, retiming, FSM optimization)
4. Formally verify the optimized RTL is functionally equivalent to the original (SymbiYosys / EQY)
5. Evaluate timing, area, power, and performance (OpenROAD)
6. Iterate until the best candidate is found
7. Present results via a Streamlit dashboard

## Pipeline

```
Benchmark RTL → Yosys (synthesis) → Gate-level netlist → OpenSTA (timing)
   → Timing report + critical paths → Python engine → LLM
   → Optimization candidates (SystemVerilog)
   → Formal equivalence check (SymbiYosys / EQY)
        FAIL → reject
        PASS → re-synthesis + re-STA → PPA data → candidate ranking → best candidate
   → iterate if needed
```

## Repo layout

See `docs/ARCHITECTURE.md` for the full breakdown. At a glance:

- `rtl/` — benchmark (immutable after baseline), testcases, LLM-generated candidates, accepted candidates
- `synthesis/`, `sta/`, `openroad/` — EDA flow scripts, netlists, reports (Person 1)
- `llm/`, `optimizer/` — LLM client, prompts, optimization loop (Person 2)
- `formal/`, `dashboard/` — equivalence checking, Streamlit UI (Person 3)
- `experiments/log.jsonl` — append-only log of every optimization attempt
- `docs/` — architecture, interfaces, roadmap, setup

## Team

See `docs/TEAM.md` for roles and ownership.

## Interfaces

See `docs/INTERFACES.md` for the JSON schemas that form the API between team members.
**Any schema change requires an `INTERFACE-CHANGE` labeled PR approved by all 3 members.**

## Setup

See `docs/SETUP.md`.

## Git workflow

- Never push directly to `main`. Always PR, at least 1 reviewer.
- Branch naming: `p1/{feature}`, `p2/{feature}`, `p3/{feature}`
- Commit format: `[COMPONENT] Description`
- Rebase on `main` before opening a PR.
- Squash merge to `main`.
