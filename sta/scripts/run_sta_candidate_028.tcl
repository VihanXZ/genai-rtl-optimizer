read_liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog synthesis/netlists/candidate_028_synth.v
link_design tester1
read_sdc constraints/testcode_1.sdc
report_checks -path_delay max -sort_by_slack
report_wns
report_power
exit
