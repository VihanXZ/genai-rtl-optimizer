"""Closed-loop optimizer entry point (early version).

Reads a timing report + RTL source, generates a candidate via the LLM,
and writes it out with a manifest entry. Formal verification and
re-synthesis integration come in later phases.
"""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from llm.client import LLMClient
from llm.strategies import load_prompt

REPO_ROOT = Path(__file__).resolve().parent.parent
TIMING_REPORT = REPO_ROOT / "sta" / "reports" / "tester1_timing_report.json"
RTL_SOURCE_PATH = REPO_ROOT / "rtl" / "testcases" / "tester1.sv"
MODULE_NAME = "tester1"  # Remember, this is the actual module name inside benchmark/uart_tx.sv!

CANDIDATES_DIR = REPO_ROOT / "rtl" / "candidates"
MANIFEST_PATH = CANDIDATES_DIR / "candidate_manifest.json"

# Clock constraint (must match your .sdc file)
CLOCK_PERIOD_NS = 4.0


def next_candidate_id():
    CANDIDATES_DIR.mkdir(parents=True, exist_ok=True)
    existing = sorted(CANDIDATES_DIR.glob("candidate_*.sv"))
    n = len(existing) + 1
    return "candidate_{:03d}".format(n)


def summarize_path_stages(stages):
    """Create a compact summary of the gate-level path instead of dumping every gate."""
    if not stages:
        return "No gate-level data available."

    lines = []
    total_delay = stages[-1].get("arrival_ns", 0.0)
    num_stages = len(stages)

    # Count gate types
    gate_counts = {}
    for s in stages:
        cell = s.get("cell", "unknown")
        # Extract the base gate name (e.g., sky130_fd_sc_hd__maj3_1 -> maj3)
        parts = cell.split("__")
        if len(parts) >= 2:
            base = parts[1].rsplit("_", 1)[0]
        else:
            base = cell
        gate_counts[base] = gate_counts.get(base, 0) + 1

    lines.append("Total path delay: {:.2f} ns across {} gates".format(total_delay, num_stages))
    lines.append("Gate breakdown:")
    for gate, count in sorted(gate_counts.items(), key=lambda x: -x[1]):
        lines.append("  - {} x {} ({})".format(
            count, gate,
            "MULTIPLIER/ADDER carry chain - VERY SLOW" if gate in ("maj3", "fa") else
            "XOR logic" if "xor" in gate or "xnor" in gate else
            "compound gate" if any(x in gate for x in ("a21", "o21")) else
            "flip-flop" if "dfr" in gate else
            "basic gate"
        ))

    # Show the key timing milestones
    lines.append("")
    lines.append("Timing milestones along the path:")
    milestones = [0, len(stages)//4, len(stages)//2, 3*len(stages)//4, len(stages)-1]
    for idx in milestones:
        if idx < len(stages):
            s = stages[idx]
            lines.append("  Gate {}: {:.2f} ns - {}".format(idx, s["arrival_ns"], s["cell"]))

    return "\n".join(lines)


def main():
    with open(TIMING_REPORT) as f:
        report = json.load(f)

    if not report.get("critical_paths"):
        raise RuntimeError("No critical paths found in timing report")

    worst = min(report["critical_paths"], key=lambda p: p["slack_ns"])
    rtl_source = RTL_SOURCE_PATH.read_text()

    # path_delay_ns: derive from the last stage's arrival time
    path_delay_ns = worst["stages"][-1]["arrival_ns"] if worst.get("stages") else None

    # Create a compact summary instead of dumping every gate
    path_stages_str = summarize_path_stages(worst.get("stages", []))

    prompt = load_prompt(
        "pipelining",
        rtl_source=rtl_source,
        path_delay_ns=path_delay_ns,
        slack_ns=worst["slack_ns"],
        startpoint=worst["startpoint"],
        endpoint=worst["endpoint"],
        path_depth=worst.get("path_depth", "unknown"),
        path_stages=path_stages_str,
        clock_period_ns=CLOCK_PERIOD_NS,
        clock_period_2x_ns=CLOCK_PERIOD_NS * 2,
    )

    # Save the final prompt for debugging
    debug_path = REPO_ROOT / "sta" / "reports" / "last_prompt_sent.txt"
    debug_path.write_text(prompt)

    client = LLMClient()
    candidate_sv = client.generate(prompt)

    cand_id = next_candidate_id()
    out_path = CANDIDATES_DIR / "{}.sv".format(cand_id)
    out_path.write_text(candidate_sv)

    manifest = {
        "$schema": "candidate_manifest_v1",
        "experiment_id": "exp_{}_001".format(datetime.now().strftime("%Y%m%d")),
        "baseline_rtl": str(RTL_SOURCE_PATH.relative_to(REPO_ROOT)),
        "baseline_module": MODULE_NAME,
        "candidates": [],
    }
    if MANIFEST_PATH.exists():
        manifest = json.loads(MANIFEST_PATH.read_text())

    desc = "Timing optimization along worst critical path ({sp} -> {ep})".format(
        sp=worst["startpoint"], ep=worst["endpoint"]
    )
    target = "{sp} -> {ep}".format(sp=worst["startpoint"], ep=worst["endpoint"])

    manifest["candidates"].append({
        "candidate_id": cand_id,
        "file": "rtl/candidates/{}.sv".format(cand_id),
        "module_name": MODULE_NAME,
        "transformation": "pipelining",
        "description": desc,
        "target_path": target,
        "prompt_version": "v1",
        "llm_model": client.model,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    })
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2))

    print("Wrote {}".format(out_path))
    print("Updated {}".format(MANIFEST_PATH))


if __name__ == "__main__":
    main()
