module bad_mac_array_core (
    input clk,
    input rst_n,
    input [15:0] a0, a1, a2, a3,
    input [15:0] b0, b1, b2, b3,
    output reg [31:0] out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out <= 32'd0;
        else
            out <= (a0*b0) + (a1*b1) + (a2*b2) + (a3*b3);
    end
endmodule
