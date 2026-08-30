module tester1 (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] data,
    input  logic [31:0] key,
    input  logic [2:0]  op,
    output logic [31:0] y
);

    logic [31:0] x1, x2, x3, x4;
    logic [31:0] checksum;
    logic [31:0] rotated;
    logic [31:0] transformed;
    logic [31:0] result;

    always_comb begin

        // Checksum calculation
        x1 = data + key;
        x2 = x1 ^ 32'hA5A5A5A5;
        x3 = x2 + {data[15:0], data[31:16]};
        x4 = x3 ^ {key[7:0], key[31:8]};

        checksum = x4 + (x3 ^ x1);

        // Data transformation
        transformed = (data ^ key) + x2;

        // Variable rotation
        rotated =
            (data << key[4:0]) |
            (data >> (32 - key[4:0]));

        case (op)
            3'b000: result = checksum;
            3'b001: result = transformed;
            3'b010: result = checksum ^ data;
            3'b011: result = data & key;
            3'b100: result = data | key;
            3'b101: result = rotated;
            3'b110: result = (checksum > key) ? 32'h1 : 32'h0;
            3'b111: result = checksum ^ transformed ^ rotated;
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