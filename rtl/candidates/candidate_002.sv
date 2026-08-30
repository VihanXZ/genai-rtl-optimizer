/*
 * Module: testcode_1
 *
 * Summary of Changes:
 * - Retimed the logic by utilizing the original dummy shift registers to pipeline
 *   the arithmetic block across clock cycles.
 * - The original structure had 3 input register stages plus 1 output register stage
 *   (4 cycles latency total), but performed a 32-bit multiply AND 32-bit addition 
 *   in a single combinational path between d3 registers and 'out'.
 * - Pipelined the calculation into 4 balanced stages:
 *     Stage 1: Sample/buffer inputs (a_stg1, b_stg1, c_stg1, d_stg1)
 *     Stage 2: Perform 32-bit multiplications (p1_stg2, p2_stg2)
 *     Stage 3: Perform 32-bit addition (sum_stg3)
 *     Stage 4: Drive output (out)
 * - Latency impact: 0 added cycles (latency remains exactly 4 clock cycles).
 */

module testcode_1 (
    input clk,
    input rst_n,
    input [31:0] a, b, c, d,
    output reg [31:0] out
);
    // Pipeline Stage 1: Input registers
    reg [31:0] a_stg1, b_stg1;
    reg [31:0] c_stg1, d_stg1;

    // Pipeline Stage 2: Product registers
    reg [31:0] p1_stg2;
    reg [31:0] p2_stg2;

    // Pipeline Stage 3: Sum register
    reg [31:0] sum_stg3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stg1   <= 32'd0;
            b_stg1   <= 32'd0;
            c_stg1   <= 32'd0;
            d_stg1   <= 32'd0;
            p1_stg2  <= 32'd0;
            p2_stg2  <= 32'd0;
            sum_stg3 <= 32'd0;
            out      <= 32'd0;
        end else begin
            // Stage 1: Sample inputs
            a_stg1   <= a;
            b_stg1   <= b;
            c_stg1   <= c;
            d_stg1   <= d;

            // Stage 2: Perform multiplications
            p1_stg2  <= a_stg1 * b_stg1;
            p2_stg2  <= c_stg1 * d_stg1;

            // Stage 3: Perform addition
            sum_stg3 <= p1_stg2 + p2_stg2;

            // Stage 4: Output stage
            out      <= sum_stg3;
        end
    end
endmodule