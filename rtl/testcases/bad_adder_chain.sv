module bad_adder_chain (
    input clk,
    input rst_n,
    input [31:0] a, b, c, d, e, f, g, h,
    output reg [31:0] out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out <= 32'd0;
        else
            out <= ((((((a + b) + c) + d) + e) + f) + g) + h;
    end
endmodule
