module miter (
  input  [  0:0] \__pi_clk ,
  input  [ 31:0] \__pi_data ,
  input  [ 31:0] \__pi_key ,
  input  [  2:0] \__pi_op ,
  input  [  0:0] \__pi_rst ,
`ifdef DIRECT_CROSS_POINTS
`else
`endif
  output [ 31:0] \__po_y__gold ,
  output [ 31:0] \__po_y__gate
);
  \gold.tester1.y gold (
    .\__pi_clk (\__pi_clk ),
    .\__pi_data (\__pi_data ),
    .\__pi_key (\__pi_key ),
    .\__pi_op (\__pi_op ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_y (\__po_y__gold )
  );
  \gate.tester1.y gate (
    .\__pi_clk (\__pi_clk ),
    .\__pi_data (\__pi_data ),
    .\__pi_key (\__pi_key ),
    .\__pi_op (\__pi_op ),
    .\__pi_rst (\__pi_rst ),
`ifdef DIRECT_CROSS_POINTS
`else
`endif
    .\__po_y (\__po_y__gate )
  );
`ifdef ASSUME_DEFINED_INPUTS
  miter_def_prop #(1, "assume") \__pi_clk__assume (\__pi_clk );
  miter_def_prop #(32, "assume") \__pi_data__assume (\__pi_data );
  miter_def_prop #(32, "assume") \__pi_key__assume (\__pi_key );
  miter_def_prop #(3, "assume") \__pi_op__assume (\__pi_op );
  miter_def_prop #(1, "assume") \__pi_rst__assume (\__pi_rst );
`endif
`ifndef DIRECT_CROSS_POINTS
`endif
`ifdef CHECK_MATCH_POINTS
`endif
`ifdef CHECK_OUTPUTS
  miter_cmp_prop #(32, "assert") \__po_y__assert (\__po_y__gold , \__po_y__gate );
`endif
`ifdef COVER_DEF_CROSS_POINTS
  `ifdef DIRECT_CROSS_POINTS
  `else
  `endif
`endif
`ifdef COVER_DEF_GOLD_MATCH_POINTS
`endif
`ifdef COVER_DEF_GATE_MATCH_POINTS
`endif
`ifdef COVER_DEF_GOLD_OUTPUTS
  miter_def_prop #(32, "cover") \__po_y__gold_cover (\__po_y__gold );
`endif
`ifdef COVER_DEF_GATE_OUTPUTS
  miter_def_prop #(32, "cover") \__po_y__gate_cover (\__po_y__gate );
`endif
endmodule
module miter_cmp_prop #(parameter WIDTH=1, parameter TYPE="assert") (input [WIDTH-1:0] in_gold, in_gate);
  reg okay;
  integer i;
  always @* begin
    okay = 1;
    for (i = 0; i < WIDTH; i = i+1)
      okay = okay && (in_gold[i] === 1'bx || in_gold[i] === in_gate[i]);
  end
  generate
    if (TYPE == "assert") always @* assert(okay);
    if (TYPE == "assume") always @* assume(okay);
    if (TYPE == "cover")  always @* cover(okay);
  endgenerate
endmodule
module miter_def_prop #(parameter WIDTH=1, parameter TYPE="assert") (input [WIDTH-1:0] in);
  wire okay = ^in !== 1'bx;
  generate
    if (TYPE == "assert") always @* assert(okay);
    if (TYPE == "assume") always @* assume(okay);
    if (TYPE == "cover")  always @* cover(okay);
  endgenerate
endmodule
module \gold.tester1.y (
  input  [  0:0] \__pi_clk ,
  input  [ 31:0] \__pi_data ,
  input  [ 31:0] \__pi_key ,
  input  [  2:0] \__pi_op ,
  input  [  0:0] \__pi_rst ,
  output [ 31:0] \__po_y
);
endmodule
module \gate.tester1.y (
  input  [  0:0] \__pi_clk ,
  input  [ 31:0] \__pi_data ,
  input  [ 31:0] \__pi_key ,
  input  [  2:0] \__pi_op ,
  input  [  0:0] \__pi_rst ,
  output [ 31:0] \__po_y
);
endmodule
