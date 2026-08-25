/*
 * Module: testcode_1
 *
 * Retiming and Pipelining Summary:
 * - The original design contained 3 redundant delay stages followed by a single stage
 *   executing two 32-bit multiplications and a 32-bit addition sequentially.
 *   This created a deep critical path (39 gate levels, ~11.35 ns delay).
 * - Retimed the pipeline stages across the existing 4-cycle latency budget:
 *     Stage 1 (Cycle 1): Register input operands (a_d1, b_d1, c_d1, d_d1).
 *     Stage 2 (Cycle 2): Perform parallel 32-bit multiplications (p1, p2).
 *     Stage 3 (Cycle 3): Perform 32-bit addition of the intermediate products (sum_reg).
 *     Stage 4 (Cycle 4): Register final output (out).
 * - Total pipeline latency remains unchanged at 4 clock cycles (0 extra cycles added).
 */

module testcode_1 (
    input clk,
    input rst_n,
    input [31:0] a, b, c, d,
    output reg [31:0] out
);
    // Pipeline registers across stages
    reg [31:0] a_d1, b_d1, c_d1, d_d1;
    reg [31:0] p1, p2;
    reg [31:0] sum_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_d1    <= 32'd0;
            b_d1    <= 32'd0;
            c_d1    <= 32'd0;
            d_d1    <= 32'd0;
            p1      <= 32'd0;
            p2      <= 32'd0;
            sum_reg <= 32'd0;
            out     <= 32'd0;
        end else begin
            // Stage 1: Register inputs
            a_d1 <= a;
            b_d1 <= b;
            c_d1 <= c;
            d_d1 <= d;

            // Stage 2: Perform 32-bit multiplications
            p1 <= a_d1 * b_d1;
            p2 <= c_d1 * d_d1;

            // Stage 3: Perform 32-bit addition
            sum_reg <= p1 + p2;

            // Stage 4: Drive registered output
            out <= sum_reg;
        end
    end
endmodule