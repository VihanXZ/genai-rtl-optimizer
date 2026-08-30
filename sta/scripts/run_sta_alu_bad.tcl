read_liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog synthesis/netlists/alu_bad_synth.v
link_design timing_bad
read_sdc constraints/testcode_1.sdc
report_checks -path_delay max -sort_by_slack
report_wns
exit
