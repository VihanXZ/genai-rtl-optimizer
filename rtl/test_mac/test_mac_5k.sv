// Unpipelined Multiply-Accumulate (MAC) Unit
// Flop-in, Flop-out design for accurate STA

module test_mac_5k (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] a0, b0,
    input  wire [31:0] a1, b1,
    input  wire [31:0] a2, b2,
    input  wire [31:0] a3, b3,
    output reg  [63:0] out
);

    // Input registers
    reg [31:0] a0_r, b0_r, a1_r, b1_r, a2_r, b2_r, a3_r, b3_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a0_r <= 0; b0_r <= 0;
            a1_r <= 0; b1_r <= 0;
            a2_r <= 0; b2_r <= 0;
            a3_r <= 0; b3_r <= 0;
        end else begin
            a0_r <= a0; b0_r <= b0;
            a1_r <= a1; b1_r <= b1;
            a2_r <= a2; b2_r <= b2;
            a3_r <= a3; b3_r <= b3;
        end
    end

        // Stage 1: Four parallel 32x32 multipliers (Combinational)
    wire [63:0] m0_comb = a0_r * b0_r;
    wire [63:0] m1_comb = a1_r * b1_r;
    wire [63:0] m2_comb = a2_r * b2_r;
    wire [63:0] m3_comb = a3_r * b3_r;
    
    // Stage 1.5: PIPELINE REGISTERS
    reg [63:0] m0, m1, m2, m3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m0 <= 0; m1 <= 0; m2 <= 0; m3 <= 0;
        end else begin
            m0 <= m0_comb; 
            m1 <= m1_comb; 
            m2 <= m2_comb; 
            m3 <= m3_comb;
        end
    end
    
    // Stage 2: Adder tree (Combinational)
    wire [63:0] sum01 = m0 + m1;
    wire [63:0] sum23 = m2 + m3;

    
    // Stage 3: Final accumulation
    wire [63:0] final_sum = sum01 + sum23;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 64'd0;
        end else begin
            // NO PIPELINE REGISTERS! We force all the math to happen in one cycle.
            out <= final_sum; 
        end
    end

endmodule
