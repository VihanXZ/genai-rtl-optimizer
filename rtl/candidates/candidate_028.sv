// 2-stage pipelined version of tester1 (total latency: 2 clock cycles)
module tester1 (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  op,
    output logic [31:0] y
);

    // Pipeline Stage 1 intermediate signals
    logic [31:0] add1, add2;
    logic [31:0] sub1, sub2;
    logic [31:0] mul1;
    logic [31:0] s1, s2;

    // Pipeline Registers between Stage 1 and Stage 2
    logic [31:0] a_reg, b_reg;
    logic [2:0]  op_reg;
    logic [31:0] add2_reg;
    logic [31:0] sub2_reg;
    logic [31:0] mul1_reg;
    logic [31:0] s2_reg;

    // Pipeline Stage 2 intermediate signals
    logic [31:0] add3, add4;
    logic [31:0] sub3, sub4;
    logic [31:0] mul2;
    logic [31:0] s3, s4;
    logic [31:0] result;

    // First group of logic (Stage 1)
    always_comb begin
        add1 = a + b;
        add2 = add1 + 32'h12345678;

        sub1 = a - b;
        sub2 = sub1 - 32'h87654321;

        mul1 = a * b;

        s1 = (a << b[4:0]);
        s2 = s1 ^ b;
    end

    // Stage 1 Pipeline Registers
    always_ff @(posedge clk) begin
        if (rst) begin
            a_reg    <= 32'b0;
            b_reg    <= 32'b0;
            op_reg   <= 3'b0;
            add2_reg <= 32'b0;
            sub2_reg <= 32'b0;
            mul1_reg <= 32'b0;
            s2_reg   <= 32'b0;
        end else begin
            a_reg    <= a;
            b_reg    <= b;
            op_reg   <= op;
            add2_reg <= add2;
            sub2_reg <= sub2;
            mul1_reg <= mul1;
            s2_reg   <= s2;
        end
    end

    // Second group of logic (Stage 2)
    always_comb begin
        add3 = add2_reg + a_reg;
        add4 = add3 + b_reg;

        sub3 = sub2_reg - a_reg;
        sub4 = sub3 - b_reg;

        mul2 = mul1_reg * 32'd3;

        s3 = (s2_reg >> a_reg[4:0]);
        s4 = s3 ^ a_reg;

        case (op_reg)
            3'b000: result = add4;
            3'b001: result = sub4;
            3'b010: result = a_reg & b_reg;
            3'b011: result = a_reg | b_reg;
            3'b100: result = a_reg ^ b_reg;
            3'b101: result = s4;
            3'b110: result = s3;
            3'b111: result = mul2;
            default: result = 32'b0;
        endcase
    end

    // Output Register (Stage 2 FF)
    always_ff @(posedge clk) begin
        if (rst)
            y <= 32'b0;
        else
            y <= result;
    end

endmodule