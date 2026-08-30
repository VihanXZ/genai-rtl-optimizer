/*
 * Module: bad_counter (Pipelined)
 *
 * Summary of Changes:
 * 1. Pipelined the multi-stage 16-bit multiplication chain (step^5) to fix timing violations.
 *    The original single-cycle combinational calculation (t1 = step*step, t2 = t1*step,
 *    t3 = t2*t1) resulted in a 5.17 ns delay, exceeding the 4.0 ns clock period constraint.
 * 2. Split the computation into three pipeline register stages:
 *    - Stage 1: Computes t1_reg = step * step; passes step_reg1 = step.
 *    - Stage 2: Computes t2_reg = t1_reg * step_reg1; passes t1_reg2 = t1_reg.
 *    - Stage 3: Computes slow_step = t2_reg * t1_reg2.
 * 3. Stage 4 accumulates slow_step into count (count <= count + slow_step + 1).
 *
 * Latency / Functional Impact:
 * - Introduces 3 clock cycles of pipeline latency from the step input to the calculated
 *   slow_step value being accumulated into count.
 * - Reduces maximum combinational path delay per clock period well below the 4.0 ns limit.
 */

module bad_counter (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] step,
    output logic [15:0] count
);

    logic [15:0] t1_reg;
    logic [15:0] step_reg1;
    logic [15:0] t2_reg;
    logic [15:0] t1_reg2;
    logic [15:0] slow_step;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t1_reg    <= 16'd0;
            step_reg1 <= 16'd0;
            t2_reg    <= 16'd0;
            t1_reg2   <= 16'd0;
            slow_step <= 16'd0;
            count     <= 16'd0;
        end else begin
            // Pipeline Stage 1: Calculate step^2 and pass step along
            t1_reg    <= step * step;
            step_reg1 <= step;

            // Pipeline Stage 2: Calculate step^3 and pass step^2 along
            t2_reg    <= t1_reg * step_reg1;
            t1_reg2   <= t1_reg;

            // Pipeline Stage 3: Calculate step^5
            slow_step <= t2_reg * t1_reg2;

            // Pipeline Stage 4: Accumulate into counter
            count     <= count + slow_step + 16'd1;
        end
    end

endmodule