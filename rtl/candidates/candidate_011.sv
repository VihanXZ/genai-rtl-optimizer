// Pipeline Latency: 3 cycles for multiplication/addition pipeline + 1 cycle for count accumulation.
module bad_counter (
    input logic clk,
    input logic rst_n,
    input logic [15:0] step,
    output logic [15:0] count
);

    // Stage 1 pipeline registers
    logic [15:0] r0, r1, r2, r3;
    // Stage 2 pipeline registers
    logic [15:0] s0, s1;
    // Stage 3 pipeline register
    logic [15:0] slow_step_p1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r0           <= 16'd0;
            r1           <= 16'd0;
            r2           <= 16'd0;
            r3           <= 16'd0;
            s0           <= 16'd0;
            s1           <= 16'd0;
            slow_step_p1 <= 16'd0;
            count        <= 16'd0;
        end else begin
            // Stage 1: Shift-and-add decomposition of 1875 * step (Max 1 add per term, ~1.5 ns)
            // 1875 = 1024 + 512 + 256 + 64 + 16 + 2 + 1
            r0 <= (step << 10) + (step << 9);
            r1 <= (step << 8)  + (step << 6);
            r2 <= (step << 4)  + (step << 1);
            r3 <= step;

            // Stage 2: Sum partial terms (Max 1 add per term, ~1.5 ns)
            s0 <= r0 + r1;
            s1 <= r2 + r3;

            // Stage 3: Combine final sum and add 1 (Max 2 chained adds, ~3.0 ns < 4.0 ns)
            slow_step_p1 <= s0 + s1 + 16'd1;

            // Stage 4: Accumulate into output counter (Max 1 add, ~1.5 ns)
            count <= count + slow_step_p1;
        end
    end

endmodule