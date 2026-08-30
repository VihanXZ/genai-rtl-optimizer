// Pipeline latency: 2 clock cycles
module tester1 (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] data,
    input  logic [31:0] key,
    input  logic [2:0]  op,
    output logic [31:0] y
);

    // Stage 1 signals
    logic [31:0] x1_s1, x2_s1, x3_s1, x4_s1;
    logic [31:0] transformed_s1;
    logic [31:0] rotated_s1;

    // Pipeline registers
    logic [31:0] x1_r, x3_r, x4_r;
    logic [31:0] transformed_r, rotated_r;
    logic [31:0] data_r, key_r;
    logic [2:0]  op_r;

    // Stage 2 signals
    logic [31:0] checksum_s2;
    logic [31:0] result_s2;

    // Stage 1 combinational logic
    always_comb begin
        x1_s1 = data + key;
        x2_s1 = x1_s1 ^ 32'hA5A5A5A5;
        x3_s1 = x2_s1 + {data[15:0], data[31:16]};
        x4_s1 = x3_s1 ^ {key[7:0], key[31:8]};

        transformed_s1 = (data ^ key) + x2_s1;

        rotated_s1 =
            (data << key[4:0]) |
            (data >> (32 - key[4:0]));
    end

    // Pipeline registers update
    always_ff @(posedge clk) begin
        if (rst) begin
            x1_r          <= 32'b0;
            x3_r          <= 32'b0;
            x4_r          <= 32'b0;
            transformed_r <= 32'b0;
            rotated_r     <= 32'b0;
            data_r        <= 32'b0;
            key_r         <= 32'b0;
            op_r          <= 3'b0;
        end else begin
            x1_r          <= x1_s1;
            x3_r          <= x3_s1;
            x4_r          <= x4_s1;
            transformed_r <= transformed_s1;
            rotated_r     <= rotated_s1;
            data_r        <= data;
            key_r         <= key;
            op_r          <= op;
        end
    end

    // Stage 2 combinational logic
    always_comb begin
        checksum_s2 = x4_r + (x3_r ^ x1_r);

        case (op_r)
            3'b000: result_s2 = checksum_s2;
            3'b001: result_s2 = transformed_r;
            3'b010: result_s2 = checksum_s2 ^ data_r;
            3'b011: result_s2 = data_r & key_r;
            3'b100: result_s2 = data_r | key_r;
            3'b101: result_s2 = rotated_r;
            3'b110: result_s2 = (checksum_s2 > key_r) ? 32'h1 : 32'h0;
            3'b111: result_s2 = checksum_s2 ^ transformed_r ^ rotated_r;
            default: result_s2 = 32'b0;
        endcase
    end

    // Output register
    always_ff @(posedge clk) begin
        if (rst)
            y <= 32'b0;
        else
            y <= result_s2;
    end

endmodule