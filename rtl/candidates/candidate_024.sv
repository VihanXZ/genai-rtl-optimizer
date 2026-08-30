// Pipeline latency: 8 clock cycles
module tester1 (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  op,
    output logic [31:0] y
);

    // Stage 1 registers
    logic [31:0] a_stg1, b_stg1;
    logic [2:0]  op_stg1;
    logic [31:0] x2_stg1, x3_stg1, x4_stg1;

    // Stage 2 registers
    logic [31:0] a_stg2, b_stg2;
    logic [2:0]  op_stg2;
    logic [31:0] x4_stg2, x6_stg2, x7_stg2, x8_stg2;

    // Stage 3 registers
    logic [31:0] a_stg3, b_stg3;
    logic [2:0]  op_stg3;
    logic [31:0] x8_stg3, x10_stg3, x11_stg3, x12_stg3;

    // Stage 4 registers
    logic