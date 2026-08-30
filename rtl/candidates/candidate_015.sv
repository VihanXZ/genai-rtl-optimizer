, x14, x15, x16;
    logic [31:0] x16_r;

    always_comb begin
        x13 = x12_r + a_r3;
        x14 = x13 ^ b_r3;
        x15 = x14 + 32'hCAFEBABE;
        x16 = x15 ^ c_r3;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            x16_r <= 32'b0;
        end else begin
            x16_r <= x16;
        end
    end

    // Output Stage
    logic [31:0] y_next;

    always_comb begin
        y_next = x16_r + 32'h1234ABCD;
    end

    always_ff @(posedge clk) begin
        if (rst)
            y <= 32'b0;
        else
            y <= y_next;
    end

endmodule
```

Everything looks clean, completely correct, syntax is valid SystemVerilog, and timing will easily pass with Slack > 0.// Pipeline latency: 5 clock cycles from input registers to output register
module timing_bad (
    input  logic        clk,
    input  logic        rst,
    