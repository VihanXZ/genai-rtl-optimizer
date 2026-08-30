// Module with pipelined computation chain to resolve timing violation (-11.02 ns slack)
// Pipeline Latency: 5 clock cycles total (1 input reg stage + 3 internal pipeline stages + 1 output reg stage)

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

    // Pipeline Stage 1 signals & registers
    logic [31:0] x1, x2, x3, x4;
    logic [31:0] x4_r;
    logic [31:0] a_s1, b_s1, c_s1;

    // Pipeline Stage 2 signals & registers
    logic [31:0] x5, x6, x7, x8;
    logic [31:0] x8_r;
    logic [31:0] a_s2, b_s2, c_s2;

    // Pipeline Stage 3 signals & registers
    logic [31:0] x9, x10, x11, x12;
    logic [31:0] x12_r;
    logic [31:0] a_s3, b_s3, c_s3;

    // Pipeline Stage 4 signals & registers
    logic [31:0] x13, x14, x15, x16;
    logic [31:0] x16_r;

    // Output next signal
    logic [31:0] y_next;

    // Input Stage Registering
    always_ff @(posedge clk) begin
        if (rst) begin
            a_r <= 32'b0;
            b_r <= 32'b0;
            c_r <= 32'b0;
        end
        else begin
            a_r <= a;
            b_r <= b;
            c_r <= c;
        end
    end

    // Pipeline Stage 1 Computation
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
            a_s1 <= 32'b0;
            b_s1 <= 32'b0;
            c_s1 <= 32'b0;
        end
        else begin
            x4_r <= x4;
            a_s1 <= a_r;
            b_s1 <= b_r;
            c_s1 <= c_r;
        end
    end

    // Pipeline Stage 2 Computation
    always_comb begin
        x5 = x4_r + a_s1;
        x6 = x5 ^ 32'hA5A5A5A5;
        x7 = x6 + c_s1;
        x8 = x7 ^ a_s1;
    end

    // Pipeline Stage 2 Registers
    always_ff @(posedge clk) begin
        if (rst) begin
            x8_r <= 32'b0;
            a_s2 <= 32'b0;
            b_s2 <= 32'b0;
            c_s2 <= 32'b0;
        end
        else begin
            x8_r <= x8;
            a_s2 <= a_s1;
            b_s2 <= b_s1;
            c_s2 <= c_s1;
        end
    end

    // Pipeline Stage 3 Computation
    always_comb begin
        x9  = x8_r + 32'h31415926;
        x10 = x9 ^ b_s2;
        x11 = x10 + c_s2;
        x12 = x11 ^ 32'hDEADBEEF;
    end

    // Pipeline Stage 3 Registers
    always_ff @(posedge clk) begin
        if (rst) begin
            x12_r <= 32'b0;
            a_s3  <= 32'b0;
            b_s3  <= 32'b0;
            c_s3  <= 32'b0;
        end
        else begin
            x12_r <= x12;
            a_s3  <= a_s2;
            b_s3  <= b_s2;
            c_s3  <= c_s2;
        end
    end

    // Pipeline Stage 4 Computation
    always_comb begin
        x13 = x12_r + a_s3;
        x14 = x13 ^ b_s3;
        x15 = x14 + 32'hCAFEBABE;
        x16 = x15 ^ c_s3;
    end

    // Pipeline Stage 4 Registers
    always_ff @(posedge clk) begin
        if (rst) begin
            x16_r <= 32'b0;
        end
        else begin
            x16_r <= x16;
        end
    end

    // Output Stage Computation
    always_comb begin
        y_next = x16_r + 32'h1234ABCD;
    end

    // Output Register
    always_ff @(posedge clk) begin
        if (rst)
            y <= 32'b0;
        else
            y <= y_next;
    end

endmodule