#!/bin/bash
# scripts/evaluate_candidate.sh
# Automates the evaluation of an AI-generated candidate Verilog file.

if [ -z "$1" ]; then
    echo "Usage: ./evaluate_candidate.sh <path_to_candidate.sv>"
    exit 1
fi

CANDIDATE=$1
MODULE_NAME=${2:-$(basename "$CANDIDATE")}
MODULE_NAME="${MODULE_NAME%.*}"
BASENAME=$(basename "$CANDIDATE")
BASENAME="${BASENAME%.*}"

echo "==========================================="
echo " Evaluating Candidate: $BASENAME (Module: $MODULE_NAME)"
echo "==========================================="

# 1. Generate Yosys Script
echo "[1/4] Generating Synthesis Script..."
cat << EOF > synthesis/scripts/synth_${BASENAME}.ys
read_verilog -sv $CANDIDATE
hierarchy -top $MODULE_NAME
synth -top $MODULE_NAME
dfflibmap -liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib
stat -liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib
clean
write_verilog synthesis/netlists/${BASENAME}_synth.v
EOF

# 2. Run Yosys
echo "[2/4] Running Yosys Synthesis (This takes a few seconds)..."
yosys synthesis/scripts/synth_${BASENAME}.ys > synthesis/logs/${BASENAME}_synth.log

# 3. Generate STA Script
echo "[3/4] Generating STA Script..."
cat << EOF > sta/scripts/run_sta_${BASENAME}.tcl
read_liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog synthesis/netlists/${BASENAME}_synth.v
link_design $MODULE_NAME
read_sdc constraints/testcode_1.sdc
report_checks -path_delay max -sort_by_slack
report_wns
report_power
exit
EOF

# 4. Run OpenSTA & Parse
echo "[4/4] Running OpenSTA & Parsing JSON Scorecard..."
sta sta/scripts/run_sta_${BASENAME}.tcl > sta/reports/${BASENAME}_timing.rpt
python3 optimizer/parser.py sta/reports/${BASENAME}_timing.rpt sta/reports/${BASENAME}_timing_report.json

echo "==========================================="
echo "✅ Done! Final scorecard saved to: sta/reports/${BASENAME}_timing_report.json"
echo ""
echo "--- AI SCORECARD QUICK VIEW ---"
grep -E '"wns_ns"|"num_violations"' sta/reports/${BASENAME}_timing_report.json
echo "==========================================="

# 5. Extract PPA for Dashboard
echo "[5/5] Extracting PPA Metrics..."
python3 scripts/extract_ppa.py sta/reports/${BASENAME}_timing.rpt synthesis/logs/${BASENAME}_synth.log sta/reports/${BASENAME}_ppa_report.json
