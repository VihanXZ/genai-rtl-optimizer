"""Generate one candidate per available optimization strategy for the same
timing violation, so they can be compared and ranked.

Usage:
    python3 optimizer/generate_candidates.py --timing-report <path> --rtl-source <path> --module-name <name>
"""
import argparse
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from llm.strategies import STRATEGIES

REPO_ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--timing-report", required=True)
    parser.add_argument("--rtl-source", required=True)
    parser.add_argument("--module-name", required=True)
    args = parser.parse_args()

    for strategy in STRATEGIES:
        print(f"\n=== Generating candidate using '{strategy}' strategy ===")
        subprocess.run([
            sys.executable, str(REPO_ROOT / "optimizer" / "engine.py"),
            "--timing-report", args.timing_report,
            "--rtl-source", args.rtl_source,
            "--module-name", args.module_name,
            "--transformation", strategy,
        ], check=True)


if __name__ == "__main__":
    main()
