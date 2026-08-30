module timing_medium (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    output logic [31:0] y
);

    logic [31:0] a_r, b_r, c_r;
    logic [31:0] x1, x2, x3, x4, x5, x6, x7, x8;
    logic [31:0] y_next;

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

    always_comb begin
        x1 = a_r + b_r;
        x2 = x1 ^ c_r;
        x3 = x2 + 32'h12345678;
        x4 = x3 ^ b_r;

        x5 = x4 + a_r;
        x6 = x5 ^ 32'hA5A5A5A5;
        x7 = x6 + c_r;
        x8 = x7 ^ a_r;

        y_next = x8 + 32'h31415926;
    end

    always_ff @(posedge clk) begin
        if (rst)
            y <= 32'b0;
        else
            y <= y_next;
    end

endmodule