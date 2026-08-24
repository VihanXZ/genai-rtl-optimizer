// Parameterized Clock Divider
// Divides input clock by DIV_RATIO (must be even, >= 2)
module clock_divider #(
    parameter DIV_RATIO = 2
)(
    input  wire clk_in,
    input  wire rst_n,
    output reg  clk_out
);

    localparam HALF = DIV_RATIO / 2;

    reg [7:0] counter;

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;
            clk_out <= 1'b0;
        end else begin
            if (counter == HALF - 1) begin
                counter <= 8'd0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 8'd1;
            end
        end
    end

endmodule
