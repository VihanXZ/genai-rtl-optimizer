/*
 * Module: bad_counter
 * Optimization: Pipelined variable multiplications (step^5) to meet 4.0ns timing.
 * Each 16x16 multiply is split into 2 stages:
 *   Stage 1: Partial product generation (16x8-bit mults, ~2.5ns delay)
 *   Stage 2: Partial product accumulation (16-bit add, ~0.5ns delay)
 * Added pipeline latency: 7 clock cycles from step input to count update.
 */

module bad_counter (
    input logic clk,
    input logic rst_n,
    input logic [15:0] step,
    output logic [15:0] count
);

    // Stage 1: M1 partial products (step * step)
    logic [15:0] m1_pp0, m1_pp1;
    logic [15:0] step_d1;

    // Stage 2: M1 accumulation (t1 = step^2)
    logic [15:0] t1;
    logic [15:0] step_d2;

    // Stage 3: M2 partial products (t1 * step)
    logic [15:0] m2_pp0, m2_pp1;
    logic [15:0] t1_d1;

    // Stage 4: M2 accumulation (t2 = step^3)
    logic [15:0] t2;
    logic [15:0] t1_d2;

    // Stage 5: M3 partial products (t2 * t1)
    logic [15:0] m3_pp0, m3_pp1;

    // Stage 6: M3 accumulation (slow_step = step^5)
    logic [15:0] slow_step;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m1_pp0    <= 16'd0;
            m1_pp1    <= 16'd0;
            step_d1   <= 16'd0;

            t1        <= 16'd0;
            step_d2   <= 16'd0;

            m2_pp0    <= 16'd0;
            m2_pp1    <= 16'd0;
            t1_d1     <= 16'd0;

            t2        <= 16'd0;
            t1_d2     <= 16'd0;

            m3_pp0    <= 16'd0;
            m3_pp1    <= 16'd0;

            slow_step <= 16'd0;

            count     <= 16'd0;
        end else begin
            // Stage 1: Partial products for t1 = step * step
            m1_pp0    <= step * step[7:0];
            m1_pp1    <= step * step[15:8];
            step_d1   <= step;

            // Stage 2: Accumulate t1
            t1        <= m1_pp0 + (m1_pp1 << 8);
            step_d2   <= step_d1;

            // Stage 3: Partial products for t2 = t1 * step
            m2_pp0    <= t1 * step_d2[7:0];
            m2_pp1    <= t1 * step_d2[15:8];
            t1_d1     <= t1;

            // Stage 4: Accumulate t2
            t2        <= m2_pp0 + (m2_pp1 << 8);
            t1_d2     <= t1_d1;

            // Stage 5: Partial products for t3 = t2 * t1
            m3_pp0    <= t2 * t1_d2[7:0];
            m3_pp1    <= t2 * t1_d2[15:8];

            // Stage 6: Accumulate slow_step
            slow_step <= m3_pp0 + (m3_pp1 << 8);

            // Stage 7: Accumulate count
            count     <= count + slow_step + 16'd1;
        end
    end

endmodule