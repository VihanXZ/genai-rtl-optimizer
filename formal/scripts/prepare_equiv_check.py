"""Auto-generate an EQY equivalence-check config for a candidate.

Two things happen automatically here:
1. If the candidate reports added latency (latency_delta_cycles > 0), a
   delay-matched wrapper is generated around the original RTL, so the
   comparison is fair -- same total latency on both sides.
2. The strategy cascade is ordered based on whether the candidate contains
   multiplication/division. Confirmed from EQY's own docs: a `timeout` on
   an sby-based strategy makes EQY automatically try the next strategy if
   the current one doesn't finish in time -- so instead of betting on one
   solver, we genuinely try several, escalating automatically.

Scope note: port-list parsing assumes a simple, single-module, ANSI-style
port list with a standard clk/rst_n and one final output port (matching
our current test designs).

Usage:
    python3 formal/scripts/prepare_equiv_check.py --candidate-id candidate_004
"""

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
MANIFEST_PATH = REPO_ROOT / "rtl" / "candidates" / "candidate_manifest.json"


def extract_port_names(port_block: str) -> list[str]:
    names = []
    for line in port_block.split(","):
        line = re.sub(r"\b(input|output|inout|reg|wire|logic)\b", "", line)
        line = re.sub(r"\[[^\]]*\]", "", line).strip()
        if line:
            names.append(line)
    return names


def has_mult_or_div(sv_text: str) -> bool:
    """Check for real multiply/divide operators, ignoring comments."""
    code = re.sub(r"//.*", "", sv_text)
    code = re.sub(r"/\*.*?\*/", "", code, flags=re.DOTALL)
    return bool(re.search(r"[^=!<>]\*(?!\))|(?<!/)/(?!/)", code))


def build_strategy_block(sv_text: str) -> tuple[str, str]:
    """Return (strategy_block, reason) -- the .eqy strategy section text and
    a short explanation of why this ordering was chosen, based on real,
    confirmed results from this project's own testing."""
    if has_mult_or_div(sv_text):
        reason = (
            "Multiplication/division detected -- SAT k-induction historically "
            "struggles here, so we skip straight to SMT solvers: Bitwuzla first "
            "(specialized for bit-vector arithmetic), Boolector as a timed "
            "fallback, Z3 as an uncapped last resort."
        )
        block = """[strategy primary]
use sby
depth 6
engine smtbmc bitwuzla
timeout 600

[strategy fallback]
use sby
depth 6
engine smtbmc boolector
timeout 600

[strategy last_resort]
use sby
depth 6
engine smtbmc z3
"""
    else:
        reason = (
            "No multiplication/division detected -- plain SAT k-induction has "
            "proven fast and reliable for addition/logic-only designs in our "
            "testing, so it's tried first, with SMT solvers as fallbacks."
        )
        block = """[strategy quick]
use sat
depth 10

[strategy fallback]
use sby
depth 6
engine smtbmc bitwuzla
timeout 600

[strategy last_resort]
use sby
depth 6
engine smtbmc z3
"""
    return block, reason


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-id", required=True)
    args = parser.parse_args()

    manifest = json.loads(MANIFEST_PATH.read_text())
    entry = next((c for c in manifest["candidates"] if c["candidate_id"] == args.candidate_id), None)
    if entry is None:
        sys.exit(f"No manifest entry found for {args.candidate_id}")

    module_name = entry["module_name"]
    baseline_rtl_rel = entry.get("baseline_rtl", manifest.get("baseline_rtl"))
    baseline_rtl = REPO_ROOT / baseline_rtl_rel
    candidate_file_rel = entry["file"]
    candidate_path = REPO_ROOT / candidate_file_rel
    latency_delta = entry.get("latency_delta_cycles", 0)

    strategy_block, reason = build_strategy_block(candidate_path.read_text())
    print(f"Strategy ordering: {reason}\n")

    eqy_dir = REPO_ROOT / "formal" / "scripts"
    eqy_dir.mkdir(parents=True, exist_ok=True)
    eqy_path = eqy_dir / f"{module_name}_{args.candidate_id}_equiv.eqy"

    if latency_delta <= 0:
        eqy_path.write_text(f"""[gold]
read -sv {baseline_rtl_rel}
prep -top {module_name}

[gate]
read -sv {candidate_file_rel}
prep -top {module_name}

{strategy_block}""")
        print(f"No added latency reported -- wrote direct comparison config:\n  {eqy_path}")
        print(f"\nRun with:\n  eqy {eqy_path.relative_to(REPO_ROOT)}")
        return

    original_text = baseline_rtl.read_text()
    port_match = re.search(rf"module\s+{re.escape(module_name)}\s*\((.*?)\)\s*;", original_text, re.DOTALL)
    if not port_match:
        sys.exit(f"Could not find port list for module {module_name} in {baseline_rtl}")
    port_block = port_match.group(1)
    port_decls = port_block.strip()
    ports = extract_port_names(port_block)

    clk = next((p for p in ports if "clk" in p.lower()), "clk")
    rst = next((p for p in ports if "rst" in p.lower()), "rst_n")
    out_port = ports[-1]

    width_match = re.search(rf"output\s+(?:reg\s+)?(\[[^\]]+\])?\s*{re.escape(out_port)}\b", original_text)
    width = width_match.group(1) if width_match and width_match.group(1) else ""

    core_name = f"{module_name}_core"
    core_text = re.sub(rf"\bmodule\s+{re.escape(module_name)}\b", f"module {core_name}", original_text, count=1)
    core_path = baseline_rtl.parent / f"{module_name}_core.sv"
    core_path.write_text(core_text)

    conns = [f".{p}(out_orig)" if p == out_port else f".{p}({p})" for p in ports]
    port_conns = ",\n        ".join(conns)

    reg_chain = ["out_orig"] + [f"out_d{i}" for i in range(1, latency_delta)]
    reg_decls = "\n    ".join(f"reg {width} {r};" for r in reg_chain[1:])
    reset_lines = "\n            ".join(f"{r} <= 'd0;" for r in reg_chain[1:])
    shift_lines = "\n            ".join(f"{reg_chain[i]} <= {reg_chain[i-1]};" for i in range(1, len(reg_chain)))
    final_reg = reg_chain[-1]

    wrapper_text = f"""// Auto-generated by formal/scripts/prepare_equiv_check.py
// Wraps the original {module_name} with {latency_delta} extra output
// register(s), matching {args.candidate_id}'s reported LATENCY_DELTA_CYCLES,
// so equivalence checking compares both designs at the same total latency.
module {module_name} (
    {port_decls}
);
    wire {width} out_orig;
    {reg_decls}

    {core_name} original_inst (
        {port_conns}
    );

    always @(posedge {clk} or negedge {rst}) begin
        if (!{rst}) begin
            {reset_lines}
            {out_port} <= 'd0;
        end else begin
            {shift_lines}
            {out_port} <= {final_reg};
        end
    end
endmodule
"""
    wrapper_path = baseline_rtl.parent / f"{module_name}_gold_delayed.sv"
    wrapper_path.write_text(wrapper_text)

    eqy_path.write_text(f"""[gold]
read -sv {core_path.relative_to(REPO_ROOT)} {wrapper_path.relative_to(REPO_ROOT)}
prep -top {module_name}

[gate]
read -sv {candidate_file_rel}
prep -top {module_name}

{strategy_block}""")
    print(f"Detected {latency_delta} cycle(s) of added latency -- generated delay-matched wrapper:")
    print(f"  {core_path.relative_to(REPO_ROOT)}")
    print(f"  {wrapper_path.relative_to(REPO_ROOT)}")
    print(f"Config: {eqy_path.relative_to(REPO_ROOT)}")
    print(f"\nRun with:\n  eqy {eqy_path.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
