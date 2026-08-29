/*
 * Module: bad_adder_chain
 * 
 * Summary of Changes:
 * 1. Inserted a pipeline register stage to split the 7-stage adder chain into two 
 *    parallel 4-stage addition paths (sum_abcd and sum_efgh) followed by a final addition stage.
 * 2. Latency Impact: Adds 1 additional clock cycle of latency. Total output latency is now 
 *    2 clock cycles (previously 1 cycle).
 *
 * Rationale & Timing Breakdown Analysis:
 * - The original critical path accumulated 1.60 ns of delay per 32-bit addition stage, 
 *   reaching 11.20 ns across all 7 cumulative additions (sum1 through sum6 to out).
 * - By stage 4 (sum4), cumulative delay reaches 6.40 ns. 
 * - Splitting the additions into two 4-input trees (a+b+c+d and e+f+g+h) executed in parallel 
 *   during Stage 1 caps the Stage 1 critical path at 6.40 ns (3 additions).
 * - Stage 2 performs the final addition (1.60 ns).
 * - This reduces the worst-case critical path delay from 11.20 ns down to 6.40 ns, 
 *   significantly improving overall setup slack.
 */

module bad_adder_chain (
    input clk,
    input rst_n,
    input [31:0] a, b, c, d, e, f, g, h,
    output reg [31:0] out
);

    // Stage 1 pipeline registers
    reg [31:0] sum_abcd;
    reg [31:0] sum_efgh;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_abcd <= 32'd0;
            sum_efgh <= 32'd0;
            out      <= 32'd0;
        end else begin
            // Stage 1: Partial sums (3 adder stages in series per path = ~4.8ns to ~6.4ns path delay)
            sum_abcd <= (((a + b) + c) + d);
            sum_efgh <= (((e + f) + g) + h);

            // Stage 2: Final sum (1 adder stage = ~1.6ns path delay)
            out      <= sum_abcd + sum_efgh;
        end
    end

endmodule