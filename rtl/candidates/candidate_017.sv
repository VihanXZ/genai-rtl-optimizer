// Pipeline latency: 5 clock cycles (1 input register stage + 3 pipeline stages + 1 output register stage)
module timing_bad (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    output logic [31:0] y
);

    // Input registers (Stage 0)
    logic [31:0] a_r, b_r, c_r;

    // Pipeline stage registers
    logic [31:0] a_r1, b_r1, c_r1;
    logic [31:0] a_r2, b_r2, c_r2;
    logic [31:0] a_r3, b_r3, c_r3;

    logic [31:0] x4_r, x8_r, x12_r;

    // Combinational signals per stage
    logic [31:0] x1, x2, x3, x4;
    logic [31:0] x5, x6, x7, x8;
    logic [31:0] x9, x10, x11, x12;
    logic [31:0] x13, x14, x15, x16;
    logic [31:0] y_next;

    // Input register
    always_ff @(posedge clk) begin
        if (rst) begin
            a_r <= 32'b0;
            b_r <= 32'b0;
            c_r <= 32'b0;
        end else begin
            a_r <= a;
            b_r <= b;
            c_r <= c;
        end
    end

    // Pipeline Stage 1 Logic
    always_comb begin
        x1 = a_r + b_r;
        x2 = x1 ^ c_r;
        x3 = x2 + 32'h12345678;
        x4 = x3 ^ b_r;
    end

    // Pipeline Stage 1 Registers
    always_ff @(posedge clk) begin
        if (rst) begin
            x4_r <= 32'b0;
            a_r1 <= 32'b0;
            b_r1 <= 32'b0;
            c_r1 <= 32'b0;
        end else begin
            x4_r <= x4;
            a_r1 <= a_r;
            b_r1 <= b_r;
            c_r1 <= c_r;
        end
    end

    // Pipeline Stage 2 Logic
    always_comb begin
        x5 = x4_r + a_r1;
        x6 = x5 ^ 32'hA5A5A5A5;
        x7 = x6 + c_r1;
        x8 = x7 ^ a_r1;
    end

    // Pipeline Stage 2 Registers
    always_ff @(posedge clk) begin
        if (rst) begin
            x8_r <= 32'b0;
            a_r2 <= 32'b0;
            b_r2 <= 32'b0;
            c_r2 <= 32'b0;
        end else begin
            x8_r <= x8;
            a_r2 <= a_r1;
            b_r2 <= b_r1;
            c_r2 <= c_r1;
        end
    end

    // Pipeline Stage 3 Logic
    always_comb begin
        x9  = x8_r + 32'h31415926;
        x10 = x9 ^ b_r2;
        x11 = x10 + c_r2;
        x12 = x11 ^ 32'hDEADBEEF;
    end

    // Pipeline Stage 3 Registers
    always_ff @(posedge clk) begin
        if (rst) begin
            x12_r <= 32'b0;
            a_r3  <= 32'b0;
            b_r3  <= 32'b0;
            c_r3  <= 32'b0;
        end else begin
            x12_r <= x12;
            a_r3  <= a_r2;
            b_r3  <= b_r2;
            c_r3  <= c_r2;
        end
    end

    // Pipeline Stage 4 Logic
    always_comb begin
        x13    = x12_r + a_r3;
        x14    = x13 ^ b_r3;
        x15    = x14 + 32'hCAFEBABE;
        x16    = x15 ^ c_r3;
        y_next = x16 + 32'h1234ABCD;
    end

    // Output register
    always_ff @(posedge clk) begin
        if (rst)
            y <= 32'b0;
        else
            y <= y_next;
    end

endmodule