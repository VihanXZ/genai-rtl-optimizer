"""Rank candidates for a given baseline module by real formal status first,
then reported latency and estimated critical path.

Usage:
    python3 optimizer/rank_candidates.py --module-name bad_mac_array
"""
import argparse
import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = REPO_ROOT / "rtl" / "candidates" / "candidate_manifest.json"
FORMAL_DIR = REPO_ROOT / "reports" / "formal"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--module-name", required=True)
    args = parser.parse_args()

    manifest = json.loads(MANIFEST_PATH.read_text())
    candidates = [c for c in manifest["candidates"] if c["module_name"] == args.module_name]

    rows = []
    for c in candidates:
        result_path = FORMAL_DIR / f"{c['candidate_id']}_formal_result.json"
        formal_status = "NOT VERIFIED"
        if result_path.exists():
            formal_status = json.loads(result_path.read_text())["status"]
        rows.append({
            "candidate_id": c["candidate_id"],
            "transformation": c["transformation"],
            "formal_status": formal_status,
            "latency_delta_cycles": c.get("latency_delta_cycles"),
            "estimated_critical_path_ns": c.get("estimated_critical_path_ns"),
        })

    def sort_key(r):
        passed = 0 if r["formal_status"] == "PASS" else 1
        latency = r["latency_delta_cycles"] if r["latency_delta_cycles"] is not None else 999
        crit_path = r["estimated_critical_path_ns"] if r["estimated_critical_path_ns"] is not None else 999.0
        return (passed, latency, crit_path)

    rows.sort(key=sort_key)

    print(f"\nRanking for {args.module_name} (best first):\n")
    print(f"{'Rank':<5}{'Candidate':<16}{'Strategy':<14}{'Formal':<14}{'+Latency':<10}{'Est. ns':<10}")
    for i, r in enumerate(rows, 1):
        print(f"{i:<5}{r['candidate_id']:<16}{r['transformation']:<14}{r['formal_status']:<14}"
              f"{str(r['latency_delta_cycles']):<10}{str(r['estimated_critical_path_ns']):<10}")


if __name__ == "__main__":
    main()
