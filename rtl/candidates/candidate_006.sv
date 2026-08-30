// LATENCY_DELTA_CYCLES: 0
// ESTIMATED_CRITICAL_PATH_NS: 4.80
/*
 * RETIMING / TIMING CLOSURE ANALYSIS:
 * 
 * 1. Register Boundaries:
 *    The original module contains only a single output register stage (`out`) and no
 *    internal or input register stages. Strict register movement (moving registers
 *    across existing logic boundaries) cannot be performed without additional internal
 *    pipeline registers.
 *
 * 2. Logic Restructuring for Zero-Latency Timing Improvement:
 *    Since addition is associative and commutative, the 7-stage linear adder chain:
 *      ((((((a + b) + c) + d) + e) + f) + g) + h
 *    accumulating 11.20 ns of delay (7 x 1.60 ns) in a single clock cycle, was restructured
 *    into a balanced binary adder tree:
 *      Level 1: (a + b), (c + d), (e + f), (g + h)   [1.60 ns]
 *      Level 2: ((a+b) + (c+d)), ((e+f) + (g+h))      [3.20 ns]
 *      Level 3: sum_abcd + sum_efgh                    [4.80 ns]
 *
 * 3. Result:
 *    True zero-latency retiming/restructuring was achieved (LATENCY_DELTA_CYCLES = 0).
 *    The critical path logic depth was reduced from 7 gates (11.20 ns) to 3 gates (4.80 ns).
 */

module bad_adder_chain (
    input clk,
    input rst_n,
    input [31:0] a, b, c, d, e, f, g, h,
    output reg [31:0] out
);

    // Level 1 Adders (Depth 1: 1.60 ns)
    wire [31:0] sum_ab = a + b;
    wire [31:0] sum_cd = c + d;
    wire [31:0] sum_ef = e + f;
    wire [31:0] sum_gh = g + h;

    // Level 2 Adders (Depth 2: 3.20 ns)
    wire [31:0] sum_abcd = sum_ab + sum_cd;
    wire [31:0] sum_efgh = sum_ef + sum_gh;

    // Level 3 Adder & Register Boundary (Depth 3: 4.80 ns)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out <= 32'd0;
        else
            out <= sum_abcd + sum_efgh;
    end

endmodule