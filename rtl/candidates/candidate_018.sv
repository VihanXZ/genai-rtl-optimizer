// Pipeline latency: 3 clock cycles (1 input stage, 1 intermediate pipeline stage, 1 output stage)
module timing_bad (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    output logic [31:0] y
);

    // Stage 1: Input registers
    logic [31:0] a_r, b_r, c_r;

    always_ff @(posedge clk) begin
        if (rst) begin
            a_r <= 32'b0;
            b_r <= 32'b0;
            c_r <= 32'b0;
        end
        else begin
            a_r <= a;
            b_r <= b;
            c_r <= c;
        end
    end

    // Group 1 Combinational Logic (x1 to x8)
    logic [31:0] x1, x2, x3, x4, x5, x6, x7, x8;

    always_comb begin
        x1 = a_r + b_r;
        x2 = x1 ^ c_r;
        x3 = x2 + 32'h12345678;
        