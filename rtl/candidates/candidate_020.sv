// Pipeline latency: 5 clock cycles from inputs (a, b, c, d) to output y (1 input reg stage + 3 pipeline reg stages + 1 output reg stage)
module dirty_timing_design (
    input  logic        clk,
    input  logic        rst,
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic [15:0] c,
    input  logic [15:0] d,
    output logic [15:0] y
);

    // Input registers
    logic [15:0] r_a, r_b, r_c, r_d;

    always_ff @(posedge clk) begin
        if (rst) begin
            r_a <= 16'h0;
            r_b <= 16'h0;
            r_c <= 16'h0;
            r_d <= 16'h0;
        end else begin
            r_a <= a;
            r_b <= b;
            r_c <= c;
            r_d <= d;
        end
    end

    // Stage 1 Combinational Logic & Registers
    logic [15:0] x1, x2, x3, x4, x5, x6, x7, x8;
    logic [15:0] r_x1, r_x2, r_x3, r_x4, r_x5, r_x6, r_x7, r_x8;

    always_comb begin
        x1 = r_a + r_b;
        x2 = x1 ^ r_c;
        x3 = x2 + r_d;
        x4 = x3 ^ 16'h1357;
        x5 = x4 + r_a;
        x6 = x5 ^ r_b;
        x7 = x6 + r_c;
        x8 = x7 ^ r_d;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_x1 <= 16'h0;
            r_x2 <= 16'h0;
            r_x3 <= 16'h0;
            r_x4 <= 16'h0;
            r_x5 <= 16'h0;
            r_x6 <= 16'h0;
            r_x7 <= 16'h0;
            r_x8 <= 16'h0;
        end else begin
            r_x1 <= x1;
            r_x2 <= x2;
            r_x3 <= x3;
            r_x4 <= x4;
            r_x5 <= x5;
            r_x6 <= x6;
            r_x7 <= x7;
            r_x8 <= x8;
        end
    end

    // Stage 2 Combinational Logic & Registers
    logic [15:0] x9, x10, x11, x12, x13, x14, x15, x16;
    logic [15:0] r_x9, r_x10, r_x11, r_x12, r_x13, r_x14, r_x15, r_x16;

    always_comb begin
        x9  = r_x8 + r_x1;
        x10 = x9 ^ r_x2;
        x11 = x10 + r_x3;
        x12 = x11 ^ r_x4;
        x13 = x12 + r_x5;
        x14 = x13 ^ r_x6;
        x15 = x14 + r_x7;
        x16 = x15 ^ r_x8;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_x9  <= 16'h0;
            r_x10 <= 16'h0;
            r_x11 <= 16'h0;
            r_x12 <= 16'h0;
            r_x13 <= 16'h0;
            r_x14 <= 16'h0;
            r_x15 <= 16'h0;
            r_x16 <= 16'h0;
        end else begin
            r_x9  <= x9;
            r_x10 <= x10;
            r_x11 <= x11;
            r_x12 <= x12;
            r_x13 <= x13;
            r_x14 <= x14;
            r_x15 <= x15;
            r_x16 <= x16;
        end
    end

    // Stage 3 Combinational Logic & Registers
    logic [15:0] x17, x18, x19, x20, x21, x22, x23, x24;
    logic [15:0] r_x17, r_x18, r_x19, r_x20, r_x21, r_x22, r_x23, r_x24;

    always_comb begin
        x17 = r_x16 + r_x9;
        x18 = x17 ^ r_x10;
        x19 = x18 + r_x11;
        x20 = x19 ^ r_x12;
        x21 = x20 + r_x13;
        x22 = x21 ^ r_x14;
        x23 = x22 + r_x15;
        x24 = x23 ^ r_x16;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            r_x17 <= 16'h0;
            r_x18 <= 16'h0;
            r_x19 <= 16'h0;
            r_x20 <= 16'h0;
            r_x21 <= 16'h0;
            r_x22 <= 16'h0;
            r_x23 <= 16'h0;
            r_x24 <= 16'h0;
        end else begin
            r_x17 <= x17;
            r_x18 <= x18;
            r_x19 <= x19;
            r_x20 <= x20;
            r_x21 <= x21;
            r_x22 <= x22;
            r_x23 <= x23;
            r_x24 <= x24;
        end
    end

    // Stage 4 Combinational Logic
    logic [15:0] x25, x26, x27, x28, x29, x30, x31, x32;

    always_comb begin
        x25 = r_x24 + r_x17;
        x26 = x25 ^ r_x18;
        x27 = x26 + r_x19;
        x28 = x27 ^ r_x20;
        x29 = x28 + r_x21;
        x30 = x29 ^ r_x22;
        x31 = x30 + r_x23;
        x32 = x31 ^ r_x24;
    end

    // Output register
    always_ff @(posedge clk) begin
        if (rst)
            y <= 16'h0;
        else
            y <= x32;
    end

endmodule