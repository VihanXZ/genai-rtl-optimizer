// LATENCY_DELTA_CYCLES: 2
/*
 * Latency Change Notice:
 * =======================
 * LATENCY_DELTA_CYCLES: 2
 * Total latency is now 3 clock cycles (compared to 1 clock cycle in the original module).
 *
 * Summary of Changes and Decision Rationale:
 * ===========================================
 * 1. Critical Path Analysis:
 *    The timing report showed a long linear cascade of 7 32-bit adders (sum1 through out),
 *    accumulating 1.60 ns of delay at each stage for a total critical path delay of 11.20 ns.
 *    Delay accumulated uniformly across all 7 adder stages.
 *
 * 2. Architectural Redesign:
 *    To eliminate the deep linear carry chain, the 8-input addition was restructured into a
 *    balanced binary adder tree with 3 pipelined register stages:
 *    - Stage 1 (Cycle 1): 4 parallel adders computing pairwise sums (a+b, c+d, e+f, g+h).
 *    - Stage 2 (Cycle 2): 2 parallel adders combining intermediate sums (abcd, efgh).
 *    - Stage 3 (Cycle 3): 1 final adder combining the two tree halves into 'out'.
 *
 * 3. Performance Impact:
 *    The critical path delay per clock period is reduced from 11.20 ns down to a single
 *    adder stage delay (~1.60 ns), drastically improving maximum operational frequency.
 */

module bad_adder_chain (
    input clk,
    input rst_n,
    input [31:0] a, b, c, d, e, f, g, h,
    output reg [31:0] out
);

    // Stage 1 pipeline registers (4 parallel additions)
    reg [31:0] sum_ab, sum_cd, sum_ef, sum_gh;

    // Stage 2 pipeline registers (2 parallel additions)
    reg [31:0] sum_abcd, sum_efgh;

    // Pipeline Stage 1: First level of binary adder tree
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_ab <= 32'd0;
            sum_cd <= 32'd0;
            sum_ef <= 32'd0;
            sum_gh <= 32'd0;
        end else begin
            sum_ab <= a + b;
            sum_cd <= c + d;
            sum_ef <= e + f;
            sum_gh <= g + h;
        end
    end

    // Pipeline Stage 2: Second level of binary adder tree
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_abcd <= 32'd0;
            sum_efgh <= 32'd0;
        end else begin
            sum_abcd <= sum_ab + sum_cd;
            sum_efgh <= sum_ef + sum_gh;
        end
    end

    // Pipeline Stage 3: Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 32'd0;
        end else begin
            out <= sum_abcd + sum_efgh;
        end
    end

endmodule