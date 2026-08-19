# Experiment tracking

Every optimization attempt is logged in `experiments/log.jsonl` — one JSON object per line, append-only.
See `docs/INTERFACES.md` for the full schema.

## Rules

1. Never delete entries. Mark rejected candidates with `"decision": "REJECT"`.
2. Log even failures — a FAIL is data too.
3. `experiment_id` format: `exp_YYYYMMDD_NNN`
4. `candidate_id` format: `candidate_NNN` (matches filename in `rtl/candidates/`)
5. If you hand-fix a generated candidate, log it as `"transformation": "manual_fix"`.
6. `rtl/accepted/` is append-only — never overwrite an accepted candidate.

## Why this matters for judging

The judges care about coverage of deliverables, innovation, and thought process. A complete,
honest experiment log — including rejected candidates — is direct evidence of the iteration
process, not just the final result.
