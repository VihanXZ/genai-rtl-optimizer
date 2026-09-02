#!/bin/bash
# scripts/verify_equivalence.sh
# Formally verifies that the AI's optimized RTL is mathematically identical to the original RTL using EQY.

if [ "$#" -ne 3 ]; then
    echo "Usage: ./verify_equivalence.sh <gold_rtl.sv> <candidate_rtl.sv> <module_name>"
    exit 1
fi

GOLD=$(realpath $1)
CANDIDATE=$(realpath $2)
MODULE=$3

echo "==========================================="
echo " Formal Equivalence Checking (EQY)"
echo " Gold: $GOLD"
echo " Gate: $CANDIDATE"
echo " Module: $MODULE"
echo "==========================================="

mkdir -p eqy_work

# Generate the EQY config file dynamically
cat << EOF > eqy_work/check.eqy
[gold]
read_verilog -sv $GOLD
prep -top $MODULE

[gate]
read_verilog -sv $CANDIDATE
prep -top $MODULE

[strategy simple]
use sby
depth 10
EOF

# Run EQY
eqy -f eqy_work/check.eqy > eqy_work/eqy.log 2>&1

# Parse output
if grep -q "Successfully proved designs equivalent" eqy_work/eqy.log; then
    echo -e "[0;32m[PASS] The optimized RTL is mathematically EQUIVALENT to the original RTL![0m"
else
    echo -e "[0;31m[FAIL] Equivalence check failed. The AI broke the logic.[0m"
    echo "Check eqy_work/eqy.log for details."
fi
echo "==========================================="
