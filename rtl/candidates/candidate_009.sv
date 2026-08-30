// Pipelined & Shift-Add Optimized Counter
// Replaced chained constant multipliers with a balanced shift-add tree for (1875 * step).
// Added 1 cycle pipeline latency for step calculation to meet the 4.0 ns timing constraint.

module bad_counter (
    input logic clk,
    input logic rst_n,
    input logic [15:0] step,
    output logic [15:0] count
);

    // Stage 1: Balanced shift-add tree for (1875 * step + 1)
    // 1875 = 1024 + 512 + 256 + 64 + 16 + 2 + 1
    logic [15:0] t1, t2, t3, t4, t5, t6, step_inc_comb;
    
    always_comb begin
        t1 = (step << 10) + (step << 9);
        t2 = (step << 8)  + (step << 6);
        t3 = (step << 4)  + (step << 1);
        t4 = step + 16'd1;
        t5 = t1 + t2;
        t6 = t3 + t4;
        step_inc_comb = t5 + t6;
    end

    // Stage 1 Pipeline Register
    logic [15:0] step_inc_q;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            step_inc_q <= 16'd0;
        else
            step_inc_q <= step_inc_comb;
    end

    // Stage 2: Accumulator register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 16'd0;
        else
            count <= count + step_inc_q;
    end

endmodule