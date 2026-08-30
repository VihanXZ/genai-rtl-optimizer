create_clock -name clk -period 4.0 [get_ports clk]
set_input_delay 0.5 -clock clk [all_inputs]
set_output_delay 0.5 -clock clk [all_outputs]
