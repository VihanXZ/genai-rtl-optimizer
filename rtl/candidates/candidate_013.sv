// Pipeline latency: 2 clock cycles for slow_step calculation (3 cycles total to count update)
module bad_counter (
    input logic clk,
    input logic rst_n,
    input logic [11:0] step,
    output logic [11:0] count
);

    logic [11:0] step_m15;
    logic [11:0] slow_step;

    // Pipeline Stage 1 & Stage 2:
    // slow_step = step * 1875 = (step * 15) * 125
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step_m15  <= 12'd0;
            slow_step <= 12'd0;
        end else begin
            // Stage 1: step * 15 = (step << 4) - step [1 subtraction]
            step_m15  <= (step << 4) - step;
            // Stage 2: step_m15 * 125 = (step_m15 << 7) - (step_m15 << 2) + step_m15 [2 chained additions]
            slow_step <= (step_m15 << 7) - (step_m15 << 2) + step_m15;
        end
    end

    // Accumulator Stage: count update [2 additions]
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 12'd0;
        else
            count <= count + slow_step + 12'd1;
    end

endmodule