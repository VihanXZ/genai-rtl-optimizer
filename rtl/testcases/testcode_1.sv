module testcode_1 (
    input clk,
    input rst_n,
    input [31:0] a, b, c, d,
    output reg [31:0] out
);
    // 3 extra cycles of latency at the input
    reg [31:0] a_d1, a_d2, a_d3;
    reg [31:0] b_d1, b_d2, b_d3;
    reg [31:0] c_d1, c_d2, c_d3;
    reg [31:0] d_d1, d_d2, d_d3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_d1 <= 0; a_d2 <= 0; a_d3 <= 0;
            b_d1 <= 0; b_d2 <= 0; b_d3 <= 0;
            c_d1 <= 0; c_d2 <= 0; c_d3 <= 0;
            d_d1 <= 0; d_d2 <= 0; d_d3 <= 0;
            out <= 0;
        end else begin
            // Dummy shift registers (opportunity for retiming)
            a_d1 <= a; a_d2 <= a_d1; a_d3 <= a_d2;
            b_d1 <= b; b_d2 <= b_d1; b_d3 <= b_d2;
            c_d1 <= c; c_d2 <= c_d1; c_d3 <= c_d2;
            d_d1 <= d; d_d2 <= d_d1; d_d3 <= d_d2;
            
            // Unpipelined arithmetic block (Will fail timing massively)
            // A 32-bit multiplier + adder takes ~20ns in Sky130
            out <= (a_d3 * b_d3) + (c_d3 * d_d3);
        end
    end
endmodule
