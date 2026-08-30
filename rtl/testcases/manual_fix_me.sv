module manual_fix_me (
    input  logic       clk,
    input  logic       rst,
    input  logic [2:0] a, b,
    output logic [2:0] y
);

    logic [2:0] a_r, b_r;
    logic [2:0] x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12;

    // Register inputs
    always_ff @(posedge clk) begin
        if (rst) begin
            a_r <= 0; b_r <= 0;
        end else begin
            a_r <= a; b_r <= b;
        end
    end

    // THIS IS THE PROBLEM: 12 levels of logic in a single clock cycle!
    // (I increased it to 12 levels because 3-bit math is so fast, 
    // it wouldn't fail timing if it was only 8 levels!)
    always_comb begin
        x1  = a_r + b_r;
        x2  = x1 ^ 3'h1;
        x3  = x2 + 3'h2;
        x4  = x3 ^ 3'h3;
        
        x5  = x4 + 3'h4;
        x6  = x5 ^ 3'h5;
        x7  = x6 + 3'h6;
        x8  = x7 ^ 3'h7;
        
        x9  = x8 + 3'h1;
        x10 = x9 ^ 3'h2;
        x11 = x10 + 3'h3;
        x12 = x11 ^ 3'h4;
    end

    // Register output
    always_ff @(posedge clk) begin
        if (rst) y <= 0;
        else     y <= x12;
    end

endmodule

