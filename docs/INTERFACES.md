# Interfaces

**Status: DRAFT — review as a team on Day 1 and commit once agreed.**
Any change after that requires a PR labeled `INTERFACE-CHANGE`, approved by all 3 members.

These JSON schemas are the API between team members. Files matching these schemas are how
Person 1, 2, and 3's code talk to each other without needing to read each other's internals.

---

## EDA → AI: `timing_report.json`

Producer: Person 1 (`optimizer/parser.py`)
Consumer: Person 2 (`llm/` module)

```json
{
  "$schema": "timing_report_v1",
  "module_name": "string",
  "clock_period_ns": 0.0,
  "clocks": [{ "name": "string", "period_ns": 0.0, "domain": "string" }],
  "wns_ns": 0.0,
  "tns_ns": 0.0,
  "num_violations": 0,
  "critical_paths": [
    {
      "startpoint": "string",
      "endpoint": "string",
      "clock_domain": "string",
      "path_delay_ns": 0.0,
      "slack_ns": 0.0,
      "path_depth": 0,
      "stages": [
        { "cell": "string", "type": "string", "pin": "string", "delay_ns": 0.0, "arrival_ns": 0.0 }
      ]
    }
  ],
  "violations": [
    { "startpoint": "string", "endpoint": "string", "clock_domain": "string",
      "required_ns": 0.0, "arrival_ns": 0.0, "slack_ns": 0.0, "severity": "string" }
  ],
  "cell_count": 0,
  "area_um2": 0.0,
  "rtl_source": "string",
  "timestamp": "ISO-8601"
}
```

---

## AI → Formal: `candidate_manifest.json`

Producer: Person 2 (`llm/` + `optimizer/`)
Consumer: Person 3 (`formal/`)

Candidate files: `rtl/candidates/candidate_{NNN}.sv` (zero-padded 3-digit)

```json
{
  "$schema": "candidate_manifest_v1",
  "experiment_id": "exp_YYYYMMDD_NNN",
  "baseline_rtl": "path/to/original.sv",
  "baseline_module": "string",
  "candidates": [
    {
      "candidate_id": "candidate_NNN",
      "file": "rtl/candidates/candidate_NNN.sv",
      "module_name": "string",
      "transformation": "pipelining|logic_restructure|retiming|fsm_opt",
      "description": "string",
      "target_path": "string",
      "prompt_version": "string",
      "llm_model": "string",
      "timestamp": "ISO-8601"
    }
  ]
}
```

---

## Formal → Evaluation: `formal_result.json`

Producer: Person 3 (`formal/`)
Consumer: Person 2 + Person 3 (`optimizer/`)

```json
{
  "$schema": "formal_result_v1",
  "candidate_id": "string",
  "baseline_rtl": "string",
  "candidate_rtl": "string",
  "module_name": "string",
  "tool": "eqy|symbiyosys",
  "equivalent": true,
  "status": "PASS|FAIL",
  "details": "string",
  "counterexample": { "cycle": 0, "diverging_signals": ["string"] },
  "runtime_seconds": 0.0,
  "timestamp": "ISO-8601",
  "log_file": "string"
}
```

---

## Evaluation → Optimizer: `evaluation_result.json`

Producer: Person 3 (`optimizer/ranker.py`)
Consumer: Person 2 (for iteration), Dashboard (for display)

```json
{
  "$schema": "evaluation_result_v1",
  "candidate_id": "string",
  "experiment_id": "string",
  "formal": { "equivalent": true, "status": "PASS|FAIL" },
  "timing": { "wns_ns": 0.0, "tns_ns": 0.0, "clock_period_ns": 0.0, "num_violations": 0, "max_frequency_mhz": 0.0 },
  "area": { "cell_count": 0, "area_um2": 0.0, "area_delta_percent": 0.0 },
  "power": { "total_power_mw": 0.0, "dynamic_power_mw": 0.0, "static_power_mw": 0.0, "power_delta_percent": 0.0 },
  "score": { "timing_improvement": 0.0, "area_penalty": 0.0, "power_penalty": 0.0, "weighted_score": 0.0, "scoring_version": "v1" },
  "decision": "ACCEPT|REJECT",
  "reason": "string",
  "timestamp": "ISO-8601"
}
```

---

## PPA Result: `ppa_result.json`

Producer: Person 1 (EDA scripts)
Consumer: All

```json
{
  "$schema": "ppa_result_v1",
  "module_name": "string",
  "rtl_source": "string",
  "synthesis_tool": "yosys",
  "sta_tool": "opensta",
  "pnr_tool": "openroad",
  "pdk": "sky130",
  "timing": { "clock_period_ns": 0.0, "wns_ns": 0.0, "tns_ns": 0.0, "num_violations": 0, "max_frequency_mhz": 0.0 },
  "area": { "cell_count": 0, "area_um2": 0.0 },
  "power": { "total_power_mw": 0.0, "dynamic_power_mw": 0.0, "static_power_mw": 0.0 },
  "timestamp": "ISO-8601"
}
```

---

## Experiment log entry (`experiments/log.jsonl`)

Append-only, one JSON object per line. Never delete entries; failed candidates are logged with `"decision": "REJECT"`.

```json
{
  "experiment_id": "exp_YYYYMMDD_NNN",
  "candidate_id": "candidate_NNN",
  "timestamp": "ISO-8601",
  "transformation": "pipelining|logic_restructure|retiming|fsm_opt|manual_fix",
  "target_path": "string",
  "baseline": { "wns_ns": 0.0, "tns_ns": 0.0, "frequency_mhz": 0.0, "area_um2": 0.0, "cell_count": 0, "power_mw": 0.0 },
  "result": { "wns_ns": 0.0, "tns_ns": 0.0, "frequency_mhz": 0.0, "area_um2": 0.0, "cell_count": 0, "power_mw": 0.0 },
  "deltas": { "wns_improvement_percent": 0.0, "tns_improvement_percent": 0.0, "frequency_improvement_percent": 0.0, "area_delta_percent": 0.0, "power_delta_percent": 0.0 },
  "formal_status": "PASS|FAIL|PENDING",
  "decision": "ACCEPT|REJECT",
  "reason": "string",
  "llm_model": "string",
  "llm_temperature": 0.0,
  "prompt_version": "string",
  "notes": "string"
}
```
