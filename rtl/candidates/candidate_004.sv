/*
 * Module: bad_counter (Pipelined Version)
 *
 * Summary of Changes:
 * - The original design chained three 32-bit multipliers in a single combinational
 *   path (t1 = step * step; t2 = t1 * step; t3 = t2 * t1;), leading to a 39-stage
 *   critical path with a delay of 9.2 ns.
 * - To achieve timing closure, the multiplication chain is split into a 3-stage pipeline,
 *   performing one 32-bit multiplication per stage.
 *
 * Latency:
 * - Inserting pipeline registers introduces 3 clock cycles of latency from when
 *   a new `step` value is sampled until `slow_step` is computed and applied to `count`.
 */

module bad_counter (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] step,
    output logic [31:0] count
);

    // Stage 1 registers
    logic [31:0] step_r1;
    logic [31:0] t1_r1;

    // Stage 2 registers
    logic [31:0] t1_r2;
    logic [31:0] t2_r2;

    // Stage 3 register (slow_step)
    logic [31:0] slow_step;

    // Pipeline Stage 1: Compute step^2 and forward step
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step_r1 <= 32'd0;
            t1_r1   <= 32'd0;
        end else begin
            step_r1 <= step;
            t1_r1   <= step * step;
        end
    end

    // Pipeline Stage 2: Compute step^3 and forward step^2
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t1_r2 <= 32'd0;
            t2_r2 <= 32'd0;
        end else begin
            t1_r2 <= t1_r1;
            t2_r2 <= t1_r1 * step_r1;
        end
    end

    // Pipeline Stage 3: Compute step^5 (slow_step)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slow_step <= 32'd0;
        end else begin
            slow_step <= t2_r2 * t1_r2;
        end
    end

    // Accumulator Stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 32'd0;
        end else begin
            count <= count + slow_step + 32'd1;
        end
    end

endmodule