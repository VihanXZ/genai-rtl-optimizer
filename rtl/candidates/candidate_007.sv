// LATENCY_DELTA_CYCLES: 0
// ESTIMATED_CRITICAL_PATH_NS: 3.20

/*
 * Retiming Analysis and Implementation Details:
 * 
 * 1. Original Structure:
 *    - The original module performed four 16x16 multiplications and a 4-input 32-bit addition chain
 *      combinationally before registering the result at `out`.
 *    - Critical Path Delay: Multiplier (2.80 ns) + 3 Adder stages (3 * 1.60 ns = 4.80 ns) = 7.60 ns.
 *    - Total Latency: 1 clock cycle (inputs -> `out` register).
 * 
 * 2. Retiming Strategy (Zero-Latency Delta):
 *    - True zero-latency retiming (LATENCY_DELTA_CYCLES = 0) is achievable by moving the existing 
 *      register boundary backwards across the adder logic to register the outputs of the four 16x16 
 *      multipliers (`p0_reg`, `p1_reg`, `p2_reg`, `p3_reg`).
 *    - The overall cycle latency from input arrival to output validity remains exactly 1 clock cycle.
 * 
 * 3. Logic Rebalancing:
 *    - Pre-register path (Inputs -> Multipliers -> Product Registers): 
 *      Delay = 2.80 ns (16x16 multiplier).
 *    - Post-register path (Product Registers -> Balanced Adder Tree -> `out`):
 *      The adder chain is restructured into a balanced tree: (p0 + p1) + (p2 + p3).
 *      Delay = 2 adder levels * 1.60 ns = 3.20 ns.
 * 
 * 4. Critical Path Improvement:
 *    - New Estimated Critical Path: max(2.80 ns, 3.20 ns) = 3.20 ns.
 *    - Path delay reduced from 7.60 ns to 3.20 ns with 0 extra cycles of latency.
 */

module bad_mac_array (
    input clk,
    input rst_n,
    input [15:0] a0, a1, a2, a3,
    input [15:0] b0, b1, b2, b3,
    output [31:0] out
);

    // Relocated register boundary: register products after multiplication
    reg [31:0] p0_reg;
    reg [31:0] p1_reg;
    reg [31:0] p2_reg;
    reg [31:0] p3_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p0_reg <= 32'd0;
            p1_reg <= 32'd0;
            p2_reg <= 32'd0;
            p3_reg <= 32'd0;
        end else begin
            p0_reg <= a0 * b0;
            p1_reg <= a1 * b1;
            p2_reg <= a2 * b2;
            p3_reg <= a3 * b3;
        end
    end

    // Balanced combinational adder tree after intermediate registers
    wire [31:0] sum01 = p0_reg + p1_reg;
    wire [31:0] sum23 = p2_reg + p3_reg;

    assign out = sum01 + sum23;

endmodule