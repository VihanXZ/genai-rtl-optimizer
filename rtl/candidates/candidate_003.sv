/*
 * Pipelined Implementation of testcode_1
 *
 * Summary of Changes:
 * - Retimed the input shift registers into the arithmetic logic path to balance delay.
 * - Separated the 32-bit multiplications and the subsequent addition across pipeline stages:
 *     Stage 1: Input operand registers (a_d1, b_d1, c_d1, d_d1).
 *     Stage 2: Multiplier output registers (mult1, mult2).
 *     Stage 3: Adder output register (add_out).
 *     Stage 4: Output register (out).
 * - Critical Path Impact: Eliminates the long combinational path formed by cascading
 *   multipliers and an adder within a single clock cycle.
 * - Latency: Maintains exact original total latency of 4 clock cycles from input to output
 *   (no additional latency added to the module interface).
 */

module testcode_1 (
    input clk,
    input rst_n,
    input [31:0] a, b, c, d,
    output reg [31:0] out
);
    // Pipeline stage registers
    reg [31:0] a_d1, b_d1, c_d1, d_d1;
    reg [31:0] mult1, mult2;
    reg [31:0] add_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_d1    <= 32'b0;
            b_d1    <= 32'b0;
            c_d1    <= 32'b0;
            d_d1    <= 32'b0;
            mult1   <= 32'b0;
            mult2   <= 32'b0;
            add_out <= 32'b0;
            out     <= 32'b0;
        end else begin
            // Stage 1: Register inputs
            a_d1 <= a;
            b_d1 <= b;
            c_d1 <= c;
            d_d1 <= d;

            // Stage 2: Perform 32-bit multiplications
            mult1 <= a_d1 * b_d1;
            mult2 <= c_d1 * d_d1;

            // Stage 3: Perform 32-bit addition
            add_out <= mult1 + mult2;

            // Stage 4: Output register stage
            out <= add_out;
        end
    end
endmodule