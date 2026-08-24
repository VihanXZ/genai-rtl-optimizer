// FULLY PIPELINED Multiply-Accumulate (MAC) Unit
// AI Agent Fix: Replacing combinational '*' with a 32-stage shift-and-add multiplier
// and adding pipeline registers to the adder tree.

module pipelined_mult_32 (
    input clk,
    input rst_n,
    input [31:0] a,
    input [31:0] b,
    output reg [63:0] p
);
    reg [63:0] a_pipe [0:31];
    reg [31:0] b_pipe [0:31];
    reg [63:0] acc [0:31];
    
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<32; i=i+1) begin
                a_pipe[i] <= 0;
                b_pipe[i] <= 0;
                acc[i] <= 0;
            end
            p <= 0;
        end else begin
            // Stage 0
            a_pipe[0] <= {32'd0, a} << 1;
            b_pipe[0] <= b >> 1;
            acc[0]    <= b[0] ? {32'd0, a} : 64'd0;
            
            // Stages 1 to 31
            for (i=1; i<32; i=i+1) begin
                a_pipe[i] <= a_pipe[i-1] << 1;
                b_pipe[i] <= b_pipe[i-1] >> 1;
                acc[i]    <= acc[i-1] + (b_pipe[i-1][0] ? a_pipe[i-1] : 64'd0);
            end
            
            p <= acc[31];
        end
    end
endmodule

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
            a0_r<=0; b0_r<=0; a1_r<=0; b1_r<=0; a2_r<=0; b2_r<=0; a3_r<=0; b3_r<=0;
        end else begin
            a0_r<=a0; b0_r<=b0; a1_r<=a1; b1_r<=b1; a2_r<=a2; b2_r<=b2; a3_r<=a3; b3_r<=b3;
        end
    end

    // Stage 1: Pipelined Multipliers (32 cycles latency)
    wire [63:0] m0, m1, m2, m3;
    pipelined_mult_32 mult0 (.clk(clk), .rst_n(rst_n), .a(a0_r), .b(b0_r), .p(m0));
    pipelined_mult_32 mult1 (.clk(clk), .rst_n(rst_n), .a(a1_r), .b(b1_r), .p(m1));
    pipelined_mult_32 mult2 (.clk(clk), .rst_n(rst_n), .a(a2_r), .b(b2_r), .p(m2));
    pipelined_mult_32 mult3 (.clk(clk), .rst_n(rst_n), .a(a3_r), .b(b3_r), .p(m3));

    // Stage 2: Pipelined Adder Tree - Level 1
    reg [63:0] sum01, sum23;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum01 <= 0;
            sum23 <= 0;
        end else begin
            sum01 <= m0 + m1;
            sum23 <= m2 + m3;
        end
    end

    // Stage 3: Pipelined Adder Tree - Level 2 (Final)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 64'd0;
        end else begin
            out <= sum01 + sum23; 
        end
    end
endmodule
