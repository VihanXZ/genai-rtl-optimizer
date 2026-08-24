read_liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog synthesis/netlists/test_counter_sky130.v
link_design counter

read_sdc constraints/clocks.sdc

report_checks -path_delay max -format full_clock_expanded
report_wns
report_tns
