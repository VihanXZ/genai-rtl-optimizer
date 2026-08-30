#!/bin/bash
# scripts/evaluate_benchmark.sh
# Automates the evaluation of the full Astera benchmark SoC.

echo "==========================================="
echo " Evaluating Full Benchmark SoC"
echo "==========================================="

# 1. Generate Yosys Script
echo "[1/4] Generating Synthesis Script..."
cat << EOF > synthesis/scripts/synth_benchmark.ys
read_verilog -sv rtl/benchmark/*.v rtl/benchmark/*.sv
hierarchy -top astera_benchmark_top
synth -top astera_benchmark_top
dfflibmap -liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib
clean
write_verilog synthesis/netlists/astera_benchmark_top_synth.v
EOF

# 2. Run Yosys
echo "[2/4] Running Yosys Synthesis (This takes a while)..."
yosys synthesis/scripts/synth_benchmark.ys > synthesis/logs/benchmark_synth.log

# 3. Generate STA Script
echo "[3/4] Generating STA Script..."
cat << EOF > sta/scripts/run_sta_benchmark.tcl
read_liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog synthesis/netlists/astera_benchmark_top_synth.v
link_design astera_benchmark_top
read_sdc constraints/astera_benchmark.sdc
report_checks -path_delay max -sort_by_slack
report_wns
exit
EOF

# 4. Run OpenSTA & Parse
echo "[4/4] Running OpenSTA & Parsing JSON Scorecard..."
sta sta/scripts/run_sta_benchmark.tcl > sta/reports/astera_benchmark_top_timing.rpt
python3 optimizer/parser.py sta/reports/astera_benchmark_top_timing.rpt sta/reports/astera_benchmark_top_timing_report.json

echo "==========================================="
echo "✅ Done! Final scorecard saved to: sta/reports/astera_benchmark_top_timing_report.json"
