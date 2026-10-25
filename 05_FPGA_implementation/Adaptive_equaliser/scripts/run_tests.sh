#!/usr/bin/env bash
# Runs every equaliser testbench in Vivado's simulator (xsim), no GUI.
# Usage (Git Bash):  scripts/run_tests.sh          all tests
#                    scripts/run_tests.sh tb_eq  one test
set -e
VIV=/c/AMDDesignTools/2026.1/Vivado/bin
HERE=$(cd "$(dirname "$0")" && pwd)
SRC="$HERE/../rtl"
TB="$HERE/../tb"
WORK="$HERE/../build/sim"
mkdir -p "$WORK" && cd "$WORK"

TESTS=${1:-"tb_cmult tb_cma_error tb_complex_fir tb_butterfly tb_cma_update tb_eq tb_eq_board"}

"$VIV/xvlog.bat" -sv "$SRC/eq_pkg.sv" "$SRC/cmult.sv" "$SRC/complex_fir.sv" "$SRC/butterfly.sv" \
    "$SRC/cma_error.sv" "$SRC/cma_update.sv" "$SRC/cma_equaliser.sv" "$SRC/eq_board_top.sv" \
    "$TB"/*.sv > compile.log 2>&1 || { grep -E "ERROR" compile.log; exit 1; }

for t in $TESTS; do
    "$VIV/xelab.bat" -debug off -s "${t}_snap" "$t" > "elab_$t.log" 2>&1 || { grep -E "ERROR" "elab_$t.log"; exit 1; }
    "$VIV/xsim.bat" "${t}_snap" -R 2>&1 | grep -E "PASS|FAIL|ERROR|got|exp|loaded|first|TIMEOUT|cannot|rows" || true
done
