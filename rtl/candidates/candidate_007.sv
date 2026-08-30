/*
 * Optimization Summary:
 * - Problem: The original module performed three sequential/cascaded 16-bit 
 *   multiplications (t1 = step^2, t2 = step^3, t3 = step^5) and a 16-bit addition 
 *   within a single combinational path. This produced a critical path delay of 
 *   5.17 ns, violating the 4.0 ns clock period budget (slack = -1.3 ns).
 * - Optimization: Implemented a 3-stage pipeline to compute slow_step (step^5). 
 *   Each pipeline stage executes at most one 16-bit multiplication per cycle:
 *     Stage 1: Computes t1 = step * step
 *     Stage 2: Computes t2 = t1 * step
 *     Stage 3: Computes slow_step = t2 * t1
 * - Result: Replaces the long 3-multiplier combinational chain with single-multiplier
 *   pipeline stages. Each stage's combinational delay is ~2.0-2.5 ns, comfortably
 *   under the 4.0 ns timing budget.
 * - Latency: Introduced a 3-cycle pipeline latency for step^5 calculation.
 */

module bad_counter (
    input logic clk,
    input logic rst_n,
    input logic [15:0] step,
    output logic [15:0] count
);

    // Stage 1 pipeline registers
    logic [15:0] step_r1;
    logic [15:0] t1_r1;

    // Stage 2 pipeline registers
    logic [15:0] t1_r2;
    logic [15:0] t2_r2;

    // Stage 3 pipeline register
    logic [15:0] slow_step;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step_r1   <= 16'd0;
            t1_r1     <= 16'd0;
            t1_r