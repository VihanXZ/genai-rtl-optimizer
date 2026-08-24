// 32-tap FIR Filter with 16-bit data and 16-bit coefficients
// Uses non-power-of-2 coefficients to force real multiplier inference
module fir_filter #(
    parameter DATA_WIDTH  = 16,
    parameter COEFF_WIDTH = 16,
    parameter NUM_TAPS    = 32,
    parameter OUT_WIDTH   = 40
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    valid_in,
    input  wire [DATA_WIDTH-1:0]   data_in,
    output reg                     valid_out,
    output reg  [OUT_WIDTH-1:0]    data_out
);

    // Delay line (shift register)
    reg [DATA_WIDTH-1:0] delay_line [0:NUM_TAPS-1];

    // Non-trivial coefficients that force real multipliers
    wire [COEFF_WIDTH-1:0] coeffs [0:NUM_TAPS-1];
    assign coeffs[0]  = 16'd137;   assign coeffs[1]  = 16'd251;
    assign coeffs[2]  = 16'd479;   assign coeffs[3]  = 16'd893;
    assign coeffs[4]  = 16'd1571;  assign coeffs[5]  = 16'd2633;
    assign coeffs[6]  = 16'd4219;  assign coeffs[7]  = 16'd6473;
    assign coeffs[8]  = 16'd9511;  assign coeffs[9]  = 16'd13399;
    assign coeffs[10] = 16'd18127; assign coeffs[11] = 16'd23501;
    assign coeffs[12] = 16'd29123; assign coeffs[13] = 16'd34421;
    assign coeffs[14] = 16'd38891; assign coeffs[15] = 16'd42013;
    assign coeffs[16] = 16'd42013; assign coeffs[17] = 16'd38891;
    assign coeffs[18] = 16'd34421; assign coeffs[19] = 16'd29123;
    assign coeffs[20] = 16'd23501; assign coeffs[21] = 16'd18127;
    assign coeffs[22] = 16'd13399; assign coeffs[23] = 16'd9511;
    assign coeffs[24] = 16'd6473;  assign coeffs[25] = 16'd4219;
    assign coeffs[26] = 16'd2633;  assign coeffs[27] = 16'd1571;
    assign coeffs[28] = 16'd893;   assign coeffs[29] = 16'd479;
    assign coeffs[30] = 16'd251;   assign coeffs[31] = 16'd137;

    // Products (multiply stage)
    wire signed [DATA_WIDTH+COEFF_WIDTH-1:0] products [0:NUM_TAPS-1];

    // Pipeline registers for products
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] prod_reg [0:NUM_TAPS-1];

    // Valid pipeline
    reg valid_d1, valid_d2, valid_d3;

    integer i;

    // Shift register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_TAPS; i = i + 1)
                delay_line[i] <= 0;
        end else if (valid_in) begin
            delay_line[0] <= data_in;
            for (i = 1; i < NUM_TAPS; i = i + 1)
                delay_line[i] <= delay_line[i-1];
        end
    end

    // Multiply stage
    genvar g;
    generate
        for (g = 0; g < NUM_TAPS; g = g + 1) begin : mult_stage
            assign products[g] = $signed(delay_line[g]) * $signed(coeffs[g]);
        end
    endgenerate

    // Pipeline the products
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_TAPS; i = i + 1)
                prod_reg[i] <= 0;
        end else begin
            for (i = 0; i < NUM_TAPS; i = i + 1)
                prod_reg[i] <= products[i];
        end
    end

    // Adder tree - Level 1 (32 -> 16)
    wire signed [OUT_WIDTH-1:0] sum_l1 [0:15];
    generate
        for (g = 0; g < 16; g = g + 1) begin : add_l1
            assign sum_l1[g] = prod_reg[2*g] + prod_reg[2*g+1];
        end
    endgenerate

    // Pipeline after level 1
    reg signed [OUT_WIDTH-1:0] sum_l1_reg [0:15];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            for (i = 0; i < 16; i = i + 1) sum_l1_reg[i] <= 0;
        else
            for (i = 0; i < 16; i = i + 1) sum_l1_reg[i] <= sum_l1[i];
    end

    // Adder tree - Level 2 (16 -> 8)
    wire signed [OUT_WIDTH-1:0] sum_l2 [0:7];
    generate
        for (g = 0; g < 8; g = g + 1) begin : add_l2
            assign sum_l2[g] = sum_l1_reg[2*g] + sum_l1_reg[2*g+1];
        end
    endgenerate

    // Adder tree - Level 3 (8 -> 4)
    wire signed [OUT_WIDTH-1:0] sum_l3 [0:3];
    generate
        for (g = 0; g < 4; g = g + 1) begin : add_l3
            assign sum_l3[g] = sum_l2[2*g] + sum_l2[2*g+1];
        end
    endgenerate

    // Adder tree - Level 4 (4 -> 2)
    wire signed [OUT_WIDTH-1:0] sum_l4 [0:1];
    generate
        for (g = 0; g < 2; g = g + 1) begin : add_l4
            assign sum_l4[g] = sum_l3[2*g] + sum_l3[2*g+1];
        end
    endgenerate

    // Final sum
    wire signed [OUT_WIDTH-1:0] sum_final = sum_l4[0] + sum_l4[1];

    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 0;
            valid_out <= 1'b0;
            valid_d1  <= 1'b0;
            valid_d2  <= 1'b0;
            valid_d3  <= 1'b0;
        end else begin
            valid_d1  <= valid_in;
            valid_d2  <= valid_d1;
            valid_d3  <= valid_d2;
            valid_out <= valid_d3;
            data_out  <= sum_final;
        end
    end

endmodule
