# Setup

## Prerequisites (all 3 members install these)

- Python 3.10+
- [Yosys](https://github.com/YosysHQ/yosys) (synthesis)
- [OpenSTA](https://github.com/The-OpenROAD-Project/OpenSTA) (timing analysis)
- [SymbiYosys](https://github.com/YosysHQ/sby) + a SAT solver (e.g. Boolector or Yices2) (formal equivalence)
- [OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD) (P&R, PPA) — Person 1 primarily, but everyone should be able to run it
- Git

## Clone and install

```bash
git clone <repo-url>
cd genai-rtl-optimizer
make setup          # creates venv, installs requirements.txt
```

## Environment variables

Copy `.env.example` to `.env` (not committed — see `.gitignore`) and fill in:

```
LLM_API_KEY=...
LLM_PROVIDER=anthropic   # or openai, etc.
```

## Verify your toolchain (Day 0)

```bash
yosys -V
sta -help
sby --help
```

If any of these fail, flag it in the team channel immediately — Day 0 exit criteria requires
all 3 members to have a working local toolchain before specializing on Day 2.

## Running the pieces

```bash
make synth       # Person 1: Yosys synthesis
make sta         # Person 1: OpenSTA timing
make formal       # Person 3: SymbiYosys/EQY equivalence check
make optimize     # closed-loop optimizer
make dashboard    # Streamlit UI
make test         # pytest
```
