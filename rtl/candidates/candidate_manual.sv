// MANUAL FIX: Split the 6 chained operations into 2 pipeline stages.
// Stage 1 computes t1, t2, t3. Stage 2 computes t4, t5, t6.
// Pipeline latency: 2 clock cycles.

module bad_counter (
    input logic clk,
    input logic rst_n,
    input logic [15:0] step,
    output logic [15:0] count
);

    // Stage 1 pipeline registers
    logic [15:0] s1_t1, s1_t2, s1_t3;
    logic [15:0] s1_step;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_t1 <= 16'd0;
            s1_t2 <= 16'd0;
            s1_t3 <= 16'd0;
            s1_step <= 16'd0;
        end else begin
            s1_t1 <= step * 7;
            s1_t2 <= step * 7 + step * 13;
            s1_t3 <= (step * 7 + step * 13) + (step * 7) * 5;
            s1_step <= step;
        end
    end

    // Stage 2: continue computation using registered values
    logic [15:0] slow_step;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slow_step <= 16'd0;
            count <= 16'd0;
        end else begin
            logic [15:0] t4, t5, t6;
            t4 = s1_t3 + s1_t2 * 3;
            t5 = t4 + s1_t3 * 9;
            t6 = t5 + t4 * 11;
            slow_step <= t6;
            count <= count + slow_step + 16'd1;
        end
    end

endmodule
