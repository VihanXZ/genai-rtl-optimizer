#!/usr/bin/env python3
"""run_pipeline.py — Master Orchestrator for GenAI RTL Optimizer.

Automates the full closed-loop flow:
  1. Baseline PPA extraction (Yosys + OpenSTA)
  2. AI optimization via Gemini 3.1 Pro (Pipelining + Retiming tournament)
  3. Formal equivalence verification via EQY + Yices2
  4. Optimized PPA extraction
  5. Before vs After comparison report

Usage:
    python3 run_pipeline.py --input rtl/testcases/tester2.sv --module tester2
    python3 run_pipeline.py --input rtl/testcases/test_adder_chain.sv --module test_adder_chain --strategies pipelining
"""

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import textwrap
from datetime import datetime, timezone
from pathlib import Path

# ─── Constants ───────────────────────────────────────────────────────────────
REPO_ROOT = Path(__file__).resolve().parent
CANDIDATES_DIR = REPO_ROOT / "rtl" / "candidates"
REPORTS_DIR = REPO_ROOT / "reports"
EQY_WORK_DIR = REPO_ROOT / "eqy_work"
MAX_RETRIES = 3
EQY_TIMEOUT_SECONDS = 600  # 10-minute timeout for AES crypto blocks


# ─── Utility Helpers ─────────────────────────────────────────────────────────

def banner(title: str):
    """Print a formatted section banner."""
    width = 60
    print("\n" + "═" * width)
    print(f"  {title}")
    print("═" * width)


def run_shell(cmd: str, cwd: Path = REPO_ROOT, timeout: int | None = None) -> subprocess.CompletedProcess:
    """Run a shell command and return the result."""
    return subprocess.run(
        cmd, shell=True, cwd=cwd,
        capture_output=True, text=True,
        timeout=timeout,
    )


def next_candidate_id() -> str:
    """Get the next candidate ID number."""
    CANDIDATES_DIR.mkdir(parents=True, exist_ok=True)
    numbers = []
    for f in CANDIDATES_DIR.glob("candidate_*.sv"):
        try:
            numbers.append(int(f.stem.split("_")[1]))
        except (IndexError, ValueError):
            continue
    n = max(numbers, default=0) + 1
    return f"candidate_{n:03d}"


# ─── Step 1: Baseline PPA ────────────────────────────────────────────────────

def step1_baseline_ppa(input_file: Path, module_name: str) -> dict:
    """Run Yosys + OpenSTA on the original RTL and extract PPA metrics."""
    banner("STEP 1: Baseline PPA Extraction")
    basename = input_file.stem

    result = run_shell(
        f"./scripts/evaluate_candidate.sh {input_file} {module_name}"
    )
    print(result.stdout)
    if result.returncode != 0:
        print(f"⚠️  evaluate_candidate.sh stderr:\n{result.stderr}")

    # Read the PPA report
    ppa_path = REPO_ROOT / "sta" / "reports" / f"{basename}_ppa_report.json"
    timing_path = REPO_ROOT / "sta" / "reports" / f"{basename}_timing_report.json"

    if not ppa_path.exists():
        print(f"❌ PPA report not found at {ppa_path}")
        sys.exit(1)

    with open(ppa_path) as f:
        ppa = json.load(f)

    print(f"  ✅ Baseline WNS:   {ppa.get('wns_ns', 'N/A')} ns")
    print(f"  ✅ Baseline Area:  {ppa.get('area_um2', 'N/A')} μm²")
    print(f"  ✅ Baseline Power: {ppa.get('power_watts', 'N/A')} W")

    return {
        "ppa": ppa,
        "timing_report_path": str(timing_path),
        "ppa_report_path": str(ppa_path),
    }


# ─── Step 2: AI Optimization ─────────────────────────────────────────────────

def step2_generate_candidate(
    timing_report_path: str,
    rtl_source_path: Path,
    module_name: str,
    strategy: str,
    previous_error: str | None = None,
    previous_candidate: str | None = None,
) -> dict | None:
    """Call engine.py to generate an AI candidate using the given strategy."""
    print(f"\n  🤖 Generating candidate with strategy: {strategy} ...")

    cmd = (
        f"{sys.executable} optimizer/engine.py "
        f"--timing-report {timing_report_path} "
        f"--rtl-source {rtl_source_path} "
        f"--module-name {module_name} "
        f"--transformation {strategy}"
    )
    if previous_error:
        cmd += f" --previous-error {shlex.quote(previous_error)}"
    if previous_candidate:
        cmd += f" --previous-candidate {shlex.quote(previous_candidate)}"

    result = run_shell(cmd)

    print(result.stdout)
    if result.returncode != 0:
        print(f"  ❌ engine.py failed:\n{result.stderr}")
        return None

    # Parse the output to find the candidate file
    match = re.search(r"Wrote (.+\.sv)", result.stdout)
    if not match:
        print("  ❌ Could not parse candidate path from engine.py output")
        return None

    candidate_path = Path(match.group(1))
    candidate_sv = candidate_path.read_text()

    # Extract latency delta
    latency_match = re.search(r"LATENCY_DELTA_CYCLES:\s*(-?\d+)", candidate_sv)
    latency_delta = int(latency_match.group(1)) if latency_match else 0

    # Extract estimated critical path
    cp_match = re.search(r"ESTIMATED_CRITICAL_PATH_NS:\s*([\d.]+)", candidate_sv)
    estimated_cp = float(cp_match.group(1)) if cp_match else None

    print(f"  ✅ Candidate: {candidate_path.name}")
    print(f"  ✅ Latency delta: {latency_delta} cycle(s)")
    print(f"  ✅ Estimated critical path: {estimated_cp} ns")

    return {
        "candidate_path": str(candidate_path),
        "candidate_name": candidate_path.name,
        "strategy": strategy,
        "latency_delta": latency_delta,
        "estimated_cp": estimated_cp,
    }


# ─── Step 3: Ghost Wrapper Generation ────────────────────────────────────────

def generate_ghost_wrapper(
    gold_path: Path,
    module_name: str,
    latency_delta: int,
) -> Path:
    """Generate a ghost wrapper around the gold RTL to match pipeline latency."""
    print(f"\n  👻 Generating Ghost Wrapper (latency_delta={latency_delta}) ...")

    gold_source = gold_path.read_text()

    # 1. Extract the module header (everything up to the closing `);`)
    header_match = re.search(rf"(module\s+{module_name}\s*\(.*?\);)", gold_source, re.DOTALL)
    if not header_match:
        print("  ❌ Could not parse module header from gold RTL!")
        return gold_path
    
    module_header = header_match.group(1)

    # 2. Extract output port names and widths
    outputs = []
    for line in module_header.split("\n"):
        if "output" in line:
            width_match = re.search(r"\[(.*?)\]", line)
            width = f"[{width_match.group(1)}]" if width_match else ""
            # Strip the entire bracketed width before splitting to avoid capturing spaces/colons inside
            line_no_brackets = re.sub(r"\[.*?\]", "", line)
            parts = line_no_brackets.replace(",", " ").split()
            names = [p for p in parts if p not in ("output", "logic", "wire", "reg")]
            for name in names:
                outputs.append({"name": name, "width": width})

    # 3. Build the wrapper
    renamed_module = f"{module_name}_original"
    
    delay_lines = []
    connections = []
    for out in outputs:
        w = out["width"]
        oname = out["name"]
        connections.append(f".{oname}({oname}_original)")
        delay_lines.append(f"    logic {w} {oname}_original;")
        
        if latency_delta > 1:
            for i in range(1, latency_delta):
                delay_lines.append(f"    logic {w} {oname}_d{i};")
        
        delay_lines.append(f"    always_ff @(posedge clk) begin")
        delay_lines.append(f"        if (!reset_n) begin")
        if latency_delta > 1:
            for i in range(1, latency_delta):
                delay_lines.append(f"            {oname}_d{i} <= '0;")
        delay_lines.append(f"            {oname} <= '0;")
        delay_lines.append(f"        end else begin")
        
        if latency_delta == 1:
            delay_lines.append(f"            {oname} <= {oname}_original;")
        else:
            delay_lines.append(f"            {oname}_d1 <= {oname}_original;")
            for i in range(1, latency_delta - 1):
                delay_lines.append(f"            {oname}_d{i+1} <= {oname}_d{i};")
            delay_lines.append(f"            {oname} <= {oname}_d{latency_delta-1};")
        delay_lines.append(f"        end")
        delay_lines.append(f"    end")
        
    wrapper_sv = f"""{module_header}
    // Ghost Wrapper: adds {latency_delta} cycle(s) of delay
{chr(10).join(delay_lines)}

    {renamed_module} u_original (
        .*,
        {', '.join(connections)}
    );
endmodule
"""

    # Append the original module source (renamed)
    renamed_gold = gold_source.replace(
        f"module {module_name}",
        f"module {renamed_module}",
        1
    )

    wrapper_path = gold_path.parent / f"{module_name}_wrapper.sv"
    wrapper_path.write_text(wrapper_sv + "\n" + renamed_gold)

    print(f"  ✅ Ghost Wrapper written to: {wrapper_path.name}")
    return wrapper_path


# ─── Step 3: Formal Equivalence Check ────────────────────────────────────────

def step3_verify_equivalence(
    gold_path: Path,
    candidate_path: Path,
    module_name: str,
    latency_delta: int,
) -> dict:
    """Run EQY with Yices2 to verify functional equivalence."""
    banner("STEP 3: Formal Equivalence Verification (EQY + Yices2)")

    # If latency changed, generate ghost wrapper
    effective_gold = gold_path
    if latency_delta > 0:
        effective_gold = generate_ghost_wrapper(gold_path, module_name, latency_delta)

    # Run the verify script with a timeout
    try:
        result = run_shell(
            f"./scripts/verify_equivalence.sh {effective_gold} {candidate_path} {module_name}",
            timeout=EQY_TIMEOUT_SECONDS,
        )
        stdout = result.stdout
        stderr = result.stderr
        timed_out = False
    except subprocess.TimeoutExpired:
        stdout = ""
        stderr = f"EQY timed out after {EQY_TIMEOUT_SECONDS} seconds"
        timed_out = True

    print(stdout)

    # Parse result
    passed = "[PASS]" in stdout
    error_msg = ""

    if timed_out:
        error_msg = f"TIMEOUT: EQY did not finish within {EQY_TIMEOUT_SECONDS}s. The circuit may be too complex for formal verification."
        print(f"  ⏰ {error_msg}")
    elif not passed:
        # Try to extract the specific error from the log
        eqy_log = EQY_WORK_DIR / "eqy.log"
        if eqy_log.exists():
            log_content = eqy_log.read_text()
            # Check for syntax errors
            syntax_err = re.search(r"ERROR: (.+)", log_content)
            if syntax_err:
                error_msg = syntax_err.group(1)
            # Check for partition failures
            partition_fail = re.findall(r"Failed to prove equivalence of partition (\S+)", log_content)
            if partition_fail:
                error_msg = f"Logic mismatch in partitions: {', '.join(partition_fail)}"
        print(f"  ❌ Equivalence check FAILED: {error_msg}")
    else:
        print(f"  ✅ Equivalence check PASSED!")

    return {
        "passed": passed,
        "timed_out": timed_out,
        "error_msg": error_msg,
    }


# ─── Step 4: Optimized PPA ───────────────────────────────────────────────────

def step4_optimized_ppa(candidate_path: Path, module_name: str) -> dict:
    """Run Yosys + OpenSTA on the AI-optimized candidate."""
    banner("STEP 4: Optimized PPA Extraction")
    basename = Path(candidate_path).stem

    result = run_shell(
        f"./scripts/evaluate_candidate.sh {candidate_path} {module_name}"
    )
    print(result.stdout)
    if result.returncode != 0:
        print(f"⚠️  evaluate_candidate.sh stderr:\n{result.stderr}")

    ppa_path = REPO_ROOT / "sta" / "reports" / f"{basename}_ppa_report.json"
    if not ppa_path.exists():
        print(f"❌ PPA report not found at {ppa_path}")
        return {"wns_ns": None, "area_um2": None, "power_watts": None}

    with open(ppa_path) as f:
        ppa = json.load(f)

    print(f"  ✅ Optimized WNS:   {ppa.get('wns_ns', 'N/A')} ns")
    print(f"  ✅ Optimized Area:  {ppa.get('area_um2', 'N/A')} μm²")
    print(f"  ✅ Optimized Power: {ppa.get('power_watts', 'N/A')} W")

    return ppa


# ─── Step 5: Comparison Report ───────────────────────────────────────────────

def step5_comparison_report(
    module_name: str,
    baseline_ppa: dict,
    optimized_ppa: dict,
    candidate_info: dict,
) -> dict:
    """Generate the Before vs After comparison report."""
    banner("STEP 5: Optimization Results")

    def pct_change(before, after):
        if before is None or after is None or before == 0:
            return "N/A"
        change = ((after - before) / abs(before)) * 100
        return f"{change:+.1f}%"

    b_wns = baseline_ppa.get("wns_ns")
    o_wns = optimized_ppa.get("wns_ns")
    b_area = baseline_ppa.get("area_um2")
    o_area = optimized_ppa.get("area_um2")
    b_power = baseline_ppa.get("power_watts")
    o_power = optimized_ppa.get("power_watts")

    report = {
        "module": module_name,
        "candidate": candidate_info.get("candidate_name", "N/A"),
        "strategy": candidate_info.get("strategy", "N/A"),
        "latency_delta": candidate_info.get("latency_delta", 0),
        "baseline": baseline_ppa,
        "optimized": optimized_ppa,
        "improvements": {
            "wns_change": pct_change(b_wns, o_wns),
            "area_change": pct_change(b_area, o_area),
            "power_change": pct_change(b_power, o_power),
        },
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    # Print the formatted table
    print(f"""
╔══════════════════════════════════════════════════════════╗
║        OPTIMIZATION RESULTS: {module_name:<28s}║
╠═════════════════╦═══════════════╦═══════════════╦═══════╣
║ Metric          ║ Before        ║ After         ║ Δ     ║
╠═════════════════╬═══════════════╬═══════════════╬═══════╣
║ WNS (ns)        ║ {str(b_wns):>13s} ║ {str(o_wns):>13s} ║ {pct_change(b_wns, o_wns):>5s} ║
║ Area (μm²)      ║ {str(b_area):>13s} ║ {str(o_area):>13s} ║ {pct_change(b_area, o_area):>5s} ║
║ Power (W)       ║ {str(b_power):>13s} ║ {str(o_power):>13s} ║ {pct_change(b_power, o_power):>5s} ║
╠═════════════════╬═══════════════╩═══════════════╩═══════╣
║ Strategy        ║ {candidate_info.get('strategy', 'N/A'):<39s}║
║ Candidate       ║ {candidate_info.get('candidate_name', 'N/A'):<39s}║
║ Latency Added   ║ {str(candidate_info.get('latency_delta', 0)) + ' cycle(s)':<39s}║
║ EQY Status      ║ ✅ PASS (Formally Verified)              ║
╚═════════════════╩═════════════════════════════════════════╝
""")

    # Save the report
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    report_path = REPORTS_DIR / f"comparison_{module_name}.json"
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2)
    print(f"  📄 Full report saved to: {report_path}")

    return report


# ─── Main Pipeline ───────────────────────────────────────────────────────────

def run_pipeline(input_file: Path, module_name: str, strategies: list[str]):
    """Execute the full optimization pipeline."""

    print("""
    ╔═══════════════════════════════════════════════════════╗
    ║                                                       ║
    ║       🚀 GenAI RTL Optimizer — Master Pipeline 🚀     ║
    ║                                                       ║
    ║   Gemini 3.1 Pro  ·  EQY + Yices2  ·  Sky130 PDK     ║
    ║                                                       ║
    ╚═══════════════════════════════════════════════════════╝
    """)

    print(f"  📁 Input RTL:    {input_file}")
    print(f"  📦 Module:       {module_name}")
    print(f"  🎯 Strategies:   {', '.join(strategies)}")
    print(f"  🔄 Max Retries:  {MAX_RETRIES}")
    print(f"  ⏰ EQY Timeout:  {EQY_TIMEOUT_SECONDS}s")

    # ── Step 1: Baseline PPA ─────────────────────────────────────────────
    baseline = step1_baseline_ppa(input_file, module_name)
    baseline_ppa = baseline["ppa"]
    timing_report_path = baseline["timing_report_path"]

    # Check if there are actually timing violations to fix
    if baseline_ppa.get("wns_ns", 0) >= 0:
        print("\n  ⚠️  WNS >= 0: No timing violations detected!")
        print("  The circuit already meets timing. Nothing to optimize.")
        print("  Exiting pipeline.")
        return

    # ── Step 2 + 3: Tournament — Try each strategy with retries ──────────
    banner("STEP 2: AI Optimization Tournament")
    print(f"  Running {len(strategies)} strateg{'y' if len(strategies)==1 else 'ies'}: {', '.join(strategies)}")

    verified_candidates = []  # Candidates that passed EQY

    for strategy in strategies:
        print(f"\n{'─' * 50}")
        print(f"  🏆 TOURNAMENT: Strategy = {strategy.upper()}")
        print(f"{'─' * 50}")

        prev_error = None
        prev_cand_path_str = None

        for attempt in range(1, MAX_RETRIES + 1):
            print(f"\n  ── Attempt {attempt}/{MAX_RETRIES} ──")

            # Generate candidate
            candidate_info = step2_generate_candidate(
                timing_report_path, input_file, module_name, strategy, prev_error, prev_cand_path_str
            )
            if candidate_info is None:
                print(f"  ❌ Candidate generation failed on attempt {attempt}")
                continue

            candidate_path = Path(candidate_info["candidate_path"])
            latency_delta = candidate_info["latency_delta"]

            # Verify equivalence
            eqy_result = step3_verify_equivalence(
                input_file, candidate_path, module_name, latency_delta
            )

            if eqy_result["passed"]:
                print(f"\n  🎉 Strategy '{strategy}' PASSED EQY on attempt {attempt}!")
                candidate_info["eqy_attempts"] = attempt
                verified_candidates.append(candidate_info)
                break  # Move on to the next strategy
            else:
                print(f"\n  ❌ Attempt {attempt} failed: {eqy_result['error_msg'][:80]}")
                if attempt < MAX_RETRIES:
                    print(f"  🔄 Retrying with a new prompt...")
                    prev_error = eqy_result["error_msg"]
                    prev_cand_path_str = str(candidate_path)

        else:
            print(f"\n  💀 Strategy '{strategy}' failed all {MAX_RETRIES} attempts. Discarding.")

    # ── Check if we have any winners ─────────────────────────────────────
    if not verified_candidates:
        banner("PIPELINE RESULT: NO VERIFIED CANDIDATES")
        print("  ❌ All strategies failed formal verification.")
        print("  ❌ No candidates passed the EQY equivalence check.")
        print("  💡 Suggestions:")
        print("     - Try a simpler circuit")
        print("     - Increase MAX_RETRIES")
        print("     - Check the prompt templates in llm/prompts/")
        return

    # ── Step 4 + 5: PPA + Comparison for all verified candidates ─────────
    banner(f"EVALUATING {len(verified_candidates)} VERIFIED CANDIDATE(S)")

    best_candidate = None
    best_wns_improvement = float("-inf")

    for cand in verified_candidates:
        print(f"\n  📊 Evaluating: {cand['candidate_name']} ({cand['strategy']})")

        optimized_ppa = step4_optimized_ppa(
            Path(cand["candidate_path"]), module_name
        )

        report = step5_comparison_report(
            module_name, baseline_ppa, optimized_ppa, cand
        )

        # Track the best candidate by WNS improvement
        o_wns = optimized_ppa.get("wns_ns")
        b_wns = baseline_ppa.get("wns_ns")
        if o_wns is not None and b_wns is not None:
            improvement = o_wns - b_wns  # Less negative = better
            if improvement > best_wns_improvement:
                best_wns_improvement = improvement
                best_candidate = cand

    # ── Final Summary ────────────────────────────────────────────────────
    if best_candidate and len(verified_candidates) > 1:
        banner("🏆 TOURNAMENT WINNER")
        print(f"  Best candidate:  {best_candidate['candidate_name']}")
        print(f"  Strategy:        {best_candidate['strategy']}")
        print(f"  WNS improvement: {best_wns_improvement:+.2f} ns")

    banner("PIPELINE COMPLETE ✅")


# ─── CLI Entry Point ─────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="GenAI RTL Optimizer — Master Pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent("""
            Examples:
              python3 run_pipeline.py --input rtl/testcases/tester2.sv --module tester2
              python3 run_pipeline.py --input rtl/testcases/test_adder_chain.sv --module test_adder_chain --strategies pipelining
              python3 run_pipeline.py --input rtl/testcases/tester2.sv --module tester2 --strategies pipelining retiming
        """),
    )
    parser.add_argument(
        "--input", required=True,
        help="Path to the input RTL file (relative to repo root)",
    )
    parser.add_argument(
        "--module", required=True,
        help="Top-level module name",
    )
    parser.add_argument(
        "--strategies", nargs="+", default=["pipelining", "retiming", "restructure", "fsm_opt"],
        choices=["pipelining", "retiming", "restructure", "fsm_opt"],
        help="Optimization strategies to try (default: both)",
    )
    parser.add_argument(
        "--max-retries", type=int, default=MAX_RETRIES,
        help=f"Max retries per strategy (default: {MAX_RETRIES})",
    )
    parser.add_argument(
        "--eqy-timeout", type=int, default=EQY_TIMEOUT_SECONDS,
        help=f"EQY timeout in seconds (default: {EQY_TIMEOUT_SECONDS})",
    )

    args = parser.parse_args()

    # Override module-level constants with CLI args
    import run_pipeline as _self
    _self.MAX_RETRIES = args.max_retries
    _self.EQY_TIMEOUT_SECONDS = args.eqy_timeout

    input_file = REPO_ROOT / args.input
    if not input_file.exists():
        print(f"❌ Input file not found: {input_file}")
        sys.exit(1)

    run_pipeline(input_file, args.module, args.strategies)


if __name__ == "__main__":
    main()
