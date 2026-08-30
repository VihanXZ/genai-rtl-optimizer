module tester1 (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  op,
    output logic [31:0] y
);

    logic [31:0] add_chain;
    logic [31:0] sub_chain;
    logic [31:0] mul_chain;
    logic [31:0] shift_chain;
    logic [31:0] result;

    always_comb begin
        add_chain = (a << 1) + (b << 1) + 32'h12345678;
        sub_chain = -(b << 1) - 32'h87654321;
        mul_chain = a * b * 32'd3;
        shift_chain = (((a << b[4:0]) ^ b) >> a[4:0]) ^ a;

        case (op)
            3'b000: result = add_chain;
            3'b001: result = sub_chain;
            3'b010: result = a & b;
            3'b011: result = a | b;
            3'b100: result = a ^ b;
            3'b101: result = shift_chain;
            3'b110: result = ((a << b[4:0]) ^ b) >> a[4:0];
            3'b111: result = mul_chain;
            default: result = 32'b0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst)
            y <= 32'b0;
        else
            y <= result;
    end
endmodule
