_shift_result <= r6_shift_result;`

--- STAGE 8 ---
Inputs from Stage 7: `r7_a`, `r7_b`, `r7_op`, `r7_x24`..`r7_x28`, `r7_mul_result`, `r7_shift_result`
Computes:
`x29 = r7_x28 + r7_x24;`
`x30 = x29 ^ r7_x25;`
`x31 = x30 + r7_x26;`
`x32 = x31 ^ r7_x27;`

Also `add_result` and `sub_result`:
`add_res = (((((r7_a + r7_b) + x32) ^ x31) + x30) ^ x29);`
`sub_res = (((((r7_a - r7_b) - x29) ^ r7_x28) - r7_x27) ^ r7_x26);`

Registers at end of Stage 8 (p8):
`r8_op <= r7_op;`
`r8_a <= r7_a;`
`r8_b <= r7_b;`
`r8_x30 <= x30;`
`