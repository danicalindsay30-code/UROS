# program_kr260_xsdb.tcl
# ======================
# FALLBACK ONLY (not needed in the recorded hardware run). Use this if,
# after programming from Hardware Manager, Vivado says the debug hub /
# VIO / ILA cannot be found. That means the 100 MHz clock from the Zynq
# PS (pl_clk0) is not running.
#
# It configures the PS clocks with Vivado's generated psu_init, then
# loads the bitstream. Both files are kept in results/bitstream/.
#
#   1. Close Hardware Manager (only one tool can use the JTAG cable).
#   2. Power the KR260 without the SD card and wait 20 s.
#   3. Vivado Tcl Shell:
#        xsdb C:/dev/UROS/05_FPGA_implementation/Adaptive_equaliser/scripts/program_kr260_xsdb.tcl
#   4. Hardware Manager → Auto Connect → Refresh Device, load the .ltx.
#      Do not program again.

set dir C:/dev/UROS/05_FPGA_implementation/Adaptive_equaliser/results/bitstream

connect
puts [targets]

# 1. configure the PS: clocks (pl_clk0 = 100 MHz), PS-to-PL interface
targets -set -nocase -filter {name =~ "*PSU*"}
source $dir/psu_init.tcl
psu_init
after 500
psu_ps_pl_isolation_removal
psu_ps_pl_reset_config

# 2. load the bitstream into the programmable logic
fpga -file $dir/system_wrapper.bit
puts "done: PS initialised and bitstream loaded"
disconnect
