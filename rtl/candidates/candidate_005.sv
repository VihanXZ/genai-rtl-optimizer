/*
 * Pipelined bad_counter
 *
 * Summary of Changes:
 * 1. The original unpipelined combinational path contained three chained 32-bit 
 *    multiplications (t1 = step*step, t2 = t1*step, t3 = t2*t1) followed by an 
 *    accumulator, leading to a path delay of 9.2 ns (violating the 4.0 ns target).
 * 2. Inserted pipeline registers between each multiplication stage to break the
 *    long combinational chain into three separate multiplier stages plus an addition stage.
 * 3. Each stage now executes at most one 32-bit multiplication (~2.8 ns delay), 
 *    comfortably meeting the 4.0 ns clock period target.
 *
 * Latency Impact:
 * - Introduces a 3-clock-cycle pipeline latency for the computation of `slow_step`
 *   from input `step`.
 */

module bad_counter (
    input logic clk,
    input logic rst_n,
    input logic [31:0] step,
    output logic [31:0] count
);

    // Stage 1 Pipeline Registers
    logic [31:0] t1_reg;
    logic [31:0] step_reg1;

    // Stage 2 Pipeline Registers
    logic [31:0] t2_reg;
    logic [31:0] t1_reg2;

    // Stage 3 Pipeline Register (slow_step)
    logic [31:0] slow_step_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t1_reg        <= 32'd0;
            step_reg1     <= 32'd0;
            t2_reg        <= 32'd0;
            t1_reg2       <= 32'd0;
            slow_step_reg <= 32'd0;
            count         <= 32'd0;
        end else begin
            // Stage 1: Calculate t1 = step * step
            t1_reg        <= step * step;
            step_reg1     <= step;

            // Stage 2: Calculate t2 = t1 * step
            t2_reg        <= t1_reg * step_reg1;
            t1_reg2       <= t1_reg;

            // Stage 3: Calculate t3 = t2 * t1
            slow_step_reg <= t2_reg * t1_reg2;

            // Stage 4: Accumulate step into count
            count         <= count + slow_step_reg + 32'd1;
        end
    end

endmodule