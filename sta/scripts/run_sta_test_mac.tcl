read_liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog synthesis/netlists/test_mac_5k_synth.v
link_design test_mac_5k
read_sdc constraints/test_mac.sdc
report_checks -path_delay max -sort_by_slack
report_wns
exit
