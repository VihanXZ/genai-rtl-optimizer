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
TIMING_REPORT = REPO_ROOT / "sta" / "reports" / "testcode_1_timing_report.json"
RTL_SOURCE_PATH = REPO_ROOT / "rtl" / "testcases" / "testcode_1.sv"
MODULE_NAME = "testcode_1"  # overriding JSON's "generic_module" -- see schema note
CANDIDATES_DIR = REPO_ROOT / "rtl" / "candidates"
MANIFEST_PATH = CANDIDATES_DIR / "candidate_manifest.json"


def next_candidate_id() -> str:
    CANDIDATES_DIR.mkdir(parents=True, exist_ok=True)
    existing = sorted(CANDIDATES_DIR.glob("candidate_*.sv"))
    n = len(existing) + 1
    return f"candidate_{n:03d}"


def main():
    with open(TIMING_REPORT) as f:
        report = json.load(f)

    if not report.get("critical_paths"):
        raise RuntimeError("No critical paths found in timing report")

    worst = min(report["critical_paths"], key=lambda p: p["slack_ns"])
    rtl_source = RTL_SOURCE_PATH.read_text()

    # path_delay_ns isn't in this report -- derive it from the last stage's
    # arrival time, since stages start counting from 0 at the startpoint.
    path_delay_ns = worst["stages"][-1]["arrival_ns"] if worst.get("stages") else None

    prompt = load_prompt(
        "pipelining",
        rtl_source=rtl_source,
        path_delay_ns=path_delay_ns,
        slack_ns=worst["slack_ns"],
        startpoint=worst["startpoint"],
        endpoint=worst["endpoint"],
        path_depth=worst.get("path_depth", "unknown"),
    )

    client = LLMClient()
    candidate_sv = client.generate(prompt)

    cand_id = next_candidate_id()
    out_path = CANDIDATES_DIR / f"{cand_id}.sv"
    out_path.write_text(candidate_sv)

    manifest = {
        "$schema": "candidate_manifest_v1",
        "experiment_id": f"exp_{datetime.now().strftime('%Y%m%d')}_001",
        "baseline_rtl": "rtl/testcases/testcode_1.sv",
        "baseline_module": MODULE_NAME,
        "candidates": [],
    }
    if MANIFEST_PATH.exists():
        manifest = json.loads(MANIFEST_PATH.read_text())

    manifest["candidates"].append({
        "candidate_id": cand_id,
        "file": f"rtl/candidates/{cand_id}.sv",
        "module_name": MODULE_NAME,
        "transformation": "pipelining",
        "description": f"Pipeline register inserted along worst critical path ({worst['startpoint']} -> {worst['endpoint']})",
        "target_path": f"{worst['startpoint']} -> {worst['endpoint']}",
        "prompt_version": "v1",
        "llm_model": client.model,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    })
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2))

    print(f"Wrote {out_path}")
    print(f"Updated {MANIFEST_PATH}")


if __name__ == "__main__":
    main()
