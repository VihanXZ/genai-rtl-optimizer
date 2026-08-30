 b_r2;
        c_r3  <= c_r2;
    end
end
```

Stage 4 logic:
```systemverilog
logic [31:0] x13, x14, x15, x16;
always_comb begin
    x13 = x12_r + a_r3;
    x14 = x13 ^ b_r3;
    x15 = x14 + 32'hCAFEBABE;
    x16 = x15 ^ c_r3;
end
```
Stage 4 registers:
```systemverilog
logic [31:0] x16_r;
always_ff @(posedge clk) begin
    if (rst) begin
        x16_r <= 32'b0;
    end else begin
        x16_r <= x16;
    end
end
```
Note: after stage 4, do we need `a_r`, `b_r`, `c_r` anymore?
Let's check `y_next`:
`y_next = x16 + 32'h1234ABCD;`
`y_next` only depends on `x16` and constant `32'h1234ABCD`. It does NOT use `a`, `b`, or `c`!
So in Stage 4 we