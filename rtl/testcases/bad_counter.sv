module dirty_timing_design (
    input  logic       clk,
    input  logic       rst,
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic [15:0] c,
    input  logic [15:0] d,
    output logic [15:0] y
);

    logic [15:0] r_a, r_b, r_c, r_d;

    logic [15:0] x1,  x2,  x3,  x4;
    logic [15:0] x5,  x6,  x7,  x8;
    logic [15:0] x9,  x10, x11, x12;
    logic [15:0] x13, x14, x15, x16;
    logic [15:0] x17, x18, x19, x20;
    logic [15:0] x21, x22, x23, x24;
    logic [15:0] x25, x26, x27, x28;
    logic [15:0] x29, x30, x31, x32;

    // Input registers
    always_ff @(posedge clk) begin
        if (rst) begin
            r_a <= 16'h0;
            r_b <= 16'h0;
            r_c <= 16'h0;
            r_d <= 16'h0;
        end
        else begin
            r_a <= a;
            r_b <= b;
            r_c <= c;
            r_d <= d;
        end
    end

    // INTENTIONALLY TERRIBLE LONG COMBINATIONAL DATAPATH
    always_comb begin

        x1  = r_a + r_b;
        x2  = x1 ^ r_c;
        x3  = x2 + r_d;
        x4  = x3 ^ 16'h1357;

        x5  = x4 + r_a;
        x6  = x5 ^ r_b;
        x7  = x6 + r_c;
        x8  = x7 ^ r_d;

        x9  = x8 + x1;
        x10 = x9 ^ x2;
        x11 = x10 + x3;
        x12 = x11 ^ x4;

        x13 = x12 + x5;
        x14 = x13 ^ x6;
        x15 = x14 + x7;
        x16 = x15 ^ x8;

        x17 = x16 + x9;
        x18 = x17 ^ x10;
        x19 = x18 + x11;
        x20 = x19 ^ x12;

        x21 = x20 + x13;
        x22 = x21 ^ x14;
        x23 = x22 + x15;
        x24 = x23 ^ x16;

        x25 = x24 + x17;
        x26 = x25 ^ x18;
        x27 = x26 + x19;
        x28 = x27 ^ x20;

        x29 = x28 + x21;
        x30 = x29 ^ x22;
        x31 = x30 + x23;
        x32 = x31 ^ x24;

    end

    // Output register
    always_ff @(posedge clk) begin
        if (rst)
            y <= 16'h0;
        else
            y <= x32;
    end

endmodule