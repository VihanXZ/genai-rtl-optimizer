module counter (
    input  logic       clk,
    input  logic       rst,
    output logic [3:0] q
);

always_ff @(posedge clk) begin
    if (rst)
        q <= 4'b0;
    else
        q <= q + 1'b1;
end

endmodule
