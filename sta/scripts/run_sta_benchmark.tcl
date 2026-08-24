# OpenSTA script for Astera-V Benchmark
read_liberty libs/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog synthesis/netlists/astera_benchmark_synth.v
link_design astera_benchmark_top
read_sdc constraints/benchmark.sdc
report_checks -path_delay max -sort_by_slack
report_wns
report_tns
exit
