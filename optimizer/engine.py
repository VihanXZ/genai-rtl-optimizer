"""Closed-loop optimizer entry point.

Usage:
    python3 optimizer/engine.py --timing-report <path> --rtl-source <path> --module-name <name> [--transformation pipelining|retiming]
"""

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from llm.client import LLMClient
from llm.strategies import load_prompt

REPO_ROOT = Path(__file__).resolve().parent.parent
CANDIDATES_DIR = REPO_ROOT / "rtl" / "candidates"
MANIFEST_PATH = CANDIDATES_DIR / "candidate_manifest.json"


def next_candidate_id() -> str:
    CANDIDATES_DIR.mkdir(parents=True, exist_ok=True)
    numbers = []
    for f in CANDIDATES_DIR.glob("candidate_*.sv"):
        try:
            numbers.append(int(f.stem.split("_")[1]))
        except (IndexError, ValueError):
            continue
    n = max(numbers, default=0) + 1
    return f"candidate_{n:03d}"


def format_stage_breakdown(stages: list) -> str:
    if not stages:
        return "(no stage-level detail available)"
    lines = []
    prev_arrival = 0.0
    for stage in stages:
        arrival = stage.get("arrival_ns", 0.0)
        delay = stage.get("delay_ns", arrival - prev_arrival)
        cell = stage.get("cell", "?")
        pin = stage.get("pin", "?")
        lines.append(f"  {arrival:6.2f} ns  {pin:<20s} {cell:<30s} [+{delay:.2f} ns]")
        prev_arrival = arrival
    return "\n".join(lines)


def extract_latency_delta(candidate_sv: str) -> int:
    match = re.search(r"LATENCY_DELTA_CYCLES:\s*(-?\d+)", candidate_sv)
    if not match:
        print("WARNING: no LATENCY_DELTA_CYCLES marker found -- assuming 0")
        return 0
    return int(match.group(1))


def extract_estimated_critical_path(candidate_sv: str) -> float | None:
    match = re.search(r"ESTIMATED_CRITICAL_PATH_NS:\s*([\d.]+)", candidate_sv)
    if not match:
        print("WARNING: no ESTIMATED_CRITICAL_PATH_NS marker found")
        return None
    return float(match.group(1))


def main():
    parser = argparse.ArgumentParser(description="Generate an AI-suggested RTL candidate from a timing report.")
    parser.add_argument("--timing-report", required=True)
    parser.add_argument("--rtl-source", required=True)
    parser.add_argument("--module-name", required=True)
    parser.add_argument("--transformation", default="pipelining", help="pipelining or retiming")
    args = parser.parse_args()

    timing_report_path = REPO_ROOT / args.timing_report
    rtl_source_path = REPO_ROOT / args.rtl_source

    with open(timing_report_path) as f:
        report = json.load(f)

    if not report.get("critical_paths"):
        raise RuntimeError(
            f"No critical paths in {args.timing_report} -- nothing for the AI to optimize."
        )

    worst = min(report["critical_paths"], key=lambda p: p["slack_ns"])
    rtl_source = rtl_source_path.read_text()
    path_delay_ns = worst["stages"][-1]["arrival_ns"] if worst.get("stages") else None
    stage_breakdown = format_stage_breakdown(worst.get("stages", []))

    prompt = load_prompt(
        args.transformation,
        rtl_source=rtl_source,
        path_delay_ns=path_delay_ns,
        slack_ns=worst["slack_ns"],
        startpoint=worst["startpoint"],
        endpoint=worst["endpoint"],
        path_depth=worst.get("path_depth", "unknown"),
        stage_breakdown=stage_breakdown,
    )

    client = LLMClient()
    candidate_sv = client.generate(prompt)
    latency_delta = extract_latency_delta(candidate_sv)
    estimated_critical_path_ns = extract_estimated_critical_path(candidate_sv)

    cand_id = next_candidate_id()
    out_path = CANDIDATES_DIR / f"{cand_id}.sv"
    out_path.write_text(candidate_sv)

    manifest = {
        "$schema": "candidate_manifest_v1",
        "experiment_id": f"exp_{datetime.now().strftime('%Y%m%d')}_001",
        "baseline_rtl": args.rtl_source,
        "baseline_module": args.module_name,
        "candidates": [],
    }
    if MANIFEST_PATH.exists():
        manifest = json.loads(MANIFEST_PATH.read_text())

    manifest["candidates"].append({
        "candidate_id": cand_id,
        "file": f"rtl/candidates/{cand_id}.sv",
        "module_name": args.module_name,
        "baseline_rtl": args.rtl_source,
        "baseline_module": args.module_name,
        "transformation": args.transformation,
        "description": f"{args.transformation} applied along worst critical path ({worst['startpoint']} -> {worst['endpoint']})",
        "target_path": f"{worst['startpoint']} -> {worst['endpoint']}",
        "original_path_delay_ns": path_delay_ns,
        "latency_delta_cycles": latency_delta,
        "estimated_critical_path_ns": estimated_critical_path_ns,
        "prompt_version": "v1",
        "llm_model": client.model,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    })
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2))

    print(f"Wrote {out_path}")
    print(f"Updated {MANIFEST_PATH}")
    print(f"Reported latency delta: {latency_delta} cycle(s)")
    print(f"Reported estimated critical path: {estimated_critical_path_ns} ns (was {path_delay_ns} ns)")


if __name__ == "__main__":
    main()
