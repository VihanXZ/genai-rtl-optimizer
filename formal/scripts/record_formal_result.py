"""Record a real EQY result against a candidate, matching this project's
documented formal_result_v1 schema.

Usage:
    python3 formal/scripts/record_formal_result.py --candidate-id candidate_004 --status PASS
"""
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
MANIFEST_PATH = REPO_ROOT / "rtl" / "candidates" / "candidate_manifest.json"
FORMAL_DIR = REPO_ROOT / "reports" / "formal"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-id", required=True)
    parser.add_argument("--status", required=True, choices=["PASS", "FAIL"])
    parser.add_argument("--tool", default="eqy")
    args = parser.parse_args()

    manifest = json.loads(MANIFEST_PATH.read_text())
    entry = next((c for c in manifest["candidates"] if c["candidate_id"] == args.candidate_id), None)
    if entry is None:
        raise SystemExit(f"No manifest entry for {args.candidate_id}")

    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    result = {
        "$schema": "formal_result_v1",
        "candidate_id": args.candidate_id,
        "baseline_rtl": entry.get("baseline_rtl"),
        "candidate_rtl": entry["file"],
        "module_name": entry["module_name"],
        "tool": args.tool,
        "equivalent": args.status == "PASS",
        "status": args.status,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    out_path = FORMAL_DIR / f"{args.candidate_id}_formal_result.json"
    out_path.write_text(json.dumps(result, indent=2))
    print(f"Recorded {args.status} for {args.candidate_id} -> {out_path}")


if __name__ == "__main__":
    main()
