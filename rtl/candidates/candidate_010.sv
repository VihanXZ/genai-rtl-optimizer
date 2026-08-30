// Pipeline latency: 2 clock cycles for slow_step calculation before accumulator update
module bad_counter (
    input logic clk,
    input logic rst_n,
    input logic [15:0] step,
    output logic [15:0] count
);

    // Stage 1: Compute 15 * step = (step << 4) - step (1 subtraction)
    logic [15:0] step_mult15;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            step_mult15 <= 16'd0;
        else
            step_mult15 <= (step << 4) - step;
    end

    // Stage 2: Compute 125 * step_mult15 = 1875 * step = (step_mult15 << 7) - (step_mult15 << 1) - step_mult15 (2 subtractions)
    logic [15:0] slow_step;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            slow_step <= 16'd0;
        else
            slow_step <= ((step_mult15 << 7) - (step_mult15 << 1)) - step_mult15;
    end

    // Output accumulator stage: 2 additions per cycle (count + slow_step + 1)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 16'd0;
        else
            count <= count + slow_step + 16'd1;
    end

endmodule