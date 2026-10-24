# vivado_build.tcl
# ================
# Builds the KR260 bitstream for the CMA equaliser hardware test, same
# structure as your matched filter board project (mf_board_test):
#
#   Zynq PS  pl_clk0 = 100 MHz ──► eq_board_top, VIO, ILA
#   VIO      probe_out0 ──► rst   (starts at 1: design held in reset)
#            probe_in0..3 ◄── done, pass, out_count, err_count
#   ILA      out_valid, yx_re, yx_im, yy_re, yy_im (4096 samples,
#            storage qualification on, so it can store outputs only)
#
# Run from Git Bash:
#   /c/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -source vivado_build.tcl
# Output: vivado/eq_board.runs/impl_1/system_wrapper.bit (+ .ltx probes file)
#         results/eq_utilization.rpt, results/eq_timing.rpt

set root [file normalize [file dirname [info script]]]
set proj $root/vivado

create_project eq_board $proj -part xck26-sfvc784-2LV-c -force
set_property board_part xilinx.com:kr260_som:part0:2.0 [current_project]

# ---- sources ---------------------------------------------------------
add_files [list \
    $root/src/eq_pkg.sv $root/src/cmult.sv $root/src/complex_fir.sv \
    $root/src/butterfly.sv $root/src/cma_error.sv $root/src/cma_update.sv \
    $root/src/cma_equaliser.sv $root/src/eq_board_top.sv \
    $root/vectors/N5/eq_in_rom.mem $root/vectors/N5/eq_ref_rom.mem]
set_property file_type SystemVerilog [get_files *.sv]
update_compile_order -fileset sources_1

# ---- block design ------------------------------------------------------
create_bd_design system

create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1"} [get_bd_cells zynq_ultra_ps_e_0]
# no AXI masters needed: the PS only supplies the 100 MHz clock
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 {0} CONFIG.PSU__USE__M_AXI_GP1 {0} \
                         CONFIG.PSU__USE__M_AXI_GP2 {0} \
                         CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100}] [get_bd_cells zynq_ultra_ps_e_0]

create_bd_cell -type module -reference eq_board_top eq_top

create_bd_cell -type ip -vlnv xilinx.com:ip:vio vio_0
set_property -dict [list CONFIG.C_NUM_PROBE_IN {4} CONFIG.C_NUM_PROBE_OUT {1} \
    CONFIG.C_PROBE_IN0_WIDTH {1} CONFIG.C_PROBE_IN1_WIDTH {1} \
    CONFIG.C_PROBE_IN2_WIDTH {16} CONFIG.C_PROBE_IN3_WIDTH {16} \
    CONFIG.C_PROBE_OUT0_WIDTH {1} CONFIG.C_PROBE_OUT0_INIT_VAL {0x1}] [get_bd_cells vio_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:ila ila_0
set_property -dict [list CONFIG.C_NUM_OF_PROBES {5} CONFIG.C_DATA_DEPTH {4096} \
    CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_MONITOR_TYPE {Native} \
    CONFIG.C_PROBE0_WIDTH {1} CONFIG.C_PROBE1_WIDTH {16} CONFIG.C_PROBE2_WIDTH {16} \
    CONFIG.C_PROBE3_WIDTH {16} CONFIG.C_PROBE4_WIDTH {16}] [get_bd_cells ila_0]

set clk [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
connect_bd_net $clk [get_bd_pins eq_top/clk] [get_bd_pins vio_0/clk] [get_bd_pins ila_0/clk]

connect_bd_net [get_bd_pins vio_0/probe_out0] [get_bd_pins eq_top/rst]
connect_bd_net [get_bd_pins eq_top/done]      [get_bd_pins vio_0/probe_in0]
connect_bd_net [get_bd_pins eq_top/pass]      [get_bd_pins vio_0/probe_in1]
connect_bd_net [get_bd_pins eq_top/out_count] [get_bd_pins vio_0/probe_in2]
connect_bd_net [get_bd_pins eq_top/err_count] [get_bd_pins vio_0/probe_in3]

connect_bd_net [get_bd_pins eq_top/out_valid] [get_bd_pins ila_0/probe0]
connect_bd_net [get_bd_pins eq_top/yx_re]     [get_bd_pins ila_0/probe1]
connect_bd_net [get_bd_pins eq_top/yx_im]     [get_bd_pins ila_0/probe2]
connect_bd_net [get_bd_pins eq_top/yy_re]     [get_bd_pins ila_0/probe3]
connect_bd_net [get_bd_pins eq_top/yy_im]     [get_bd_pins ila_0/probe4]

validate_bd_design
save_bd_design

set wrapper [make_wrapper -files [get_files system.bd] -top]
add_files -norecurse $wrapper
set_property top system_wrapper [current_fileset]
update_compile_order -fileset sources_1

# ---- build ---------------------------------------------------------------
launch_runs synth_1 -jobs 8
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

open_run impl_1
file mkdir $root/results
report_utilization -hierarchical -file $root/results/eq_utilization_hier.rpt
report_utilization -file $root/results/eq_utilization.rpt
report_timing_summary -max_paths 5 -file $root/results/eq_timing.rpt
puts "BUILD DONE"
