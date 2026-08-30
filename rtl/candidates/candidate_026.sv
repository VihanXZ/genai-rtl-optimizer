module tester1 (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  op,
    output logic [31:0] y
);

    // Pipeline latency: 8 clock cycles
    // The long combinational chain (x1..x32, arithmetic, shifts, and multiplications)
    // is split across 8 pipeline stages to achieve positive timing slack at 4.0 ns clock period.

    // Stage 1 registers
    logic [31:0] r1_x1, r1_x2, r1_x3, r1_x4;
    logic [31:0] r1_a, r1_b;
    logic [2:0]  r1_op;
    logic [31:0] r1_ab;
    logic [31:0] r1_ash;

    // Stage 2 registers
    logic [31:0] r2_x5, r2_x6, r2_x7, r2_x8;
    logic [31:0] r2_a, r2_b;
    logic [2:0]  r2_op;
    logic [31:0] r2_ab;
    logic [31:0]