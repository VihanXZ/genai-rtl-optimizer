/*
 * Optimization Summary:
 * - Critical Path Analysis:
 *   The original design experienced an 11.35 ns path delay in a single clock cycle:
 *   1. Stages 0 to 18 (0.00 ns to 5.64 ns): Multiplier logic (partial product generation and 
 *      compression using XOR, MAJ3, and A21O cells).
 *   2. Stages 19 to 38 (5.64 ns to 11.35 ns): Accumulation/addition logic dominated by a continuous 
 *      chain of 14 MAJ3_1 cells (each contributing ~0.37 ns delay from 6.71 ns to 11.11 ns).
 *
 * - Retiming / Pipelining Decision:
 *   The original code used 3 cycles of dummy shift registers (a_d1..a_d3, etc.) prior to a single 
 *   massive 32-bit (mult + add) computation stage. 
 *   By retiming these registers into the arithmetic computation path:
 *   1. Stage 1 captures inputs (a_d1, b_d1, c_d1, d_d1).
 *   2. Stage 2 executes multiplications (prod1_d2 = a_d1 * b_d1, prod2_d2 = c_d1 * d_d1), inserting 
 *      registers at the 5.64 ns mark right after partial product compression.
 *   3. Stage 3 executes addition (sum_d3 = prod1_d2 + prod2_d2), isolating the heavy MAJ3_1 
 *      carry-propagate adder chain (~5.71 ns delay).
 *   4. Stage 4 registers the final output (out <= sum_d3).
 *
 * - Latency:
 *   Preserves the original 4-cycle total input-to-output latency while reducing the critical 
 *   path delay from 11.35 ns to ~5.7 ns.
 */

module testcode_1 (
    input clk,
    input rst_n,
    input [31:0] a, b, c, d,
    output reg [31:0] out
);
    // Pipeline stage 1 registers: Input buffering
    reg [31:0] a_d1, b_d1, c_d1, d_d1;

    // Pipeline stage 2 registers: Intermediate products
    reg [31:0] prod1_d2, prod2_d2;

    // Pipeline stage 3 registers: Intermediate sum
    reg [31:0] sum_d3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_d1     <= 32'b0;
            b_d1     <= 32'b0;
            c_d1     <= 32'b0;
            d_d1     <= 32'b0;
            prod1_d2 <= 32'b0;
            prod2_d2 <= 32'b0;
            sum_d3   <= 32'b0;
            out      <= 32'b0;
        end else begin
            // Cycle 1: Register inputs
            a_d1     <= a;
            b_d1     <= b;
            c_d1     <= c;
            d_d1     <= d;

            // Cycle 2: Perform multiplication (breaks critical path before carry chain)
            prod1_d2 <= a_d1 * b_d1;
            prod2_d2 <= c_d1 * d_d1;

            // Cycle 3: Perform addition (isolates MAJ3 adder carry chain)
            sum_d3   <= prod1_d2 + prod2_d2;

            // Cycle 4: Output stage
            out      <= sum_d3;
        end
    end
endmodule