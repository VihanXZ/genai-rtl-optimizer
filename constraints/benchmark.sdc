# Astera-V Benchmark SDC Constraints
create_clock -name clk_cpu -period 5.0 [get_ports clk_cpu]
create_clock -name clk_aes -period 6.67 [get_ports clk_aes]
create_clock -name clk_fpu -period 3.33 [get_ports clk_fpu]
create_clock -name clk_mem -period 2.5 [get_ports clk_mem]
create_clock -name clk_periph -period 10.0 [get_ports clk_periph]
set_clock_groups -asynchronous -group {clk_cpu} -group {clk_aes} -group {clk_fpu} -group {clk_mem} -group {clk_periph}
