// LATENCY_DELTA_CYCLES: 1
// ESTIMATED_CRITICAL_PATH_NS: 3.20

/*
 * Pipelining & Timing Optimization Summary:
 * -----------------------------------------
 * Analysis of Original Critical Path (7.60 ns):
 * 1. 16x16 Multiplier stage: 2.80 ns (largest single gate stage delay).
 * 2. Linear Adder Chain: 3 stages at 1.60 ns each = 4.80 ns total.
 *
 * Changes Made:
 * 1. Inserted pipeline registers (p0, p1, p2, p3) immediately after the multiplication 
 *    operations. This isolates the 2.80 ns multiplier delay to Stage 1.
 * 2. Restructured the 3-stage linear adder chain into a balanced 2-level adder tree 
 *    in Stage 2: (p0 + p1) + (p2 + p3). This limits Stage 2 delay to 2 * 1.60 ns = 3.20 ns.
 * 3. Latency Impact: Introduces 1 additional clock cycle of latency (total 2 cycles from 
 *    inputs to output register).
 *
 * Resulting Estimated Critical Path:
 * - Stage 1 (Multipliers): 2.80 ns
 * - Stage 2 (Adder Tree):  3.20 ns
 * - New Critical Path:      3.20 ns (slack improved by 4.40 ns)
 */

module bad_mac_array (
    input clk,
    input rst_n,
    input [15:0] a0, a1, a2, a3,
    input [15:0] b0, b1, b2, b3,
    output reg [31:0] out
);
    // Pipeline Stage 1 Registers (Product Accumulation)
    reg [31:0] p0, p1, p2, p3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p0 <= 32'd0;
            p1 <= 32'd0;
            p2 <= 32'd0;
            p3 <= 32'd0;
        end else begin
            p0 <= a0 * b0;
            p1 <= a1 * b1;
            p2 <= a2 * b2;
            p3 <= a3 * b3;
        end
    end

    // Pipeline Stage 2 Register (Balanced Adder Tree Output)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 32'd0;
        end else begin
            out <= (p0 + p1) + (p2 + p3);
        end
    end

endmodule