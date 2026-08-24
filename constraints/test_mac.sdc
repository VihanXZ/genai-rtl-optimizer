# We constrain it to 500MHz (2.0ns period) to ensure it fails horribly
create_clock -name clk -period 2.0 [get_ports clk]
