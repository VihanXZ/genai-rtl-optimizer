
// Pipeline latency: 5 clock cycles from input sampling to final output y.
module dirty_timing_design (
    input  logic       clk,
    input  logic       rst,
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic [15:0] c,
    input  logic [15:0] d,
    output logic [15:0] y
);

    // Input registers
    logic [15:0] r_a, r_b, r_c, r_d;
    always_ff @(posedge clk) begin
        if (rst) begin
            r_a <= 16'h0;
            r_b <= 16'h0;
            r_c <= 16'h0;
            r_d <= 16'h0;
        end
        else begin
            r_a <= a;
            r_b <= b;
            r_c <= c;
            r_d <= d;
        end
    end

    // Stage 1 Combinational Logic
    logic [15:0] x1, x2, x3, x4, x5, x6, x7, x8;
    always_comb begin
        x1 = r_a + r_b;
        x2 = x1 ^ r_c;
