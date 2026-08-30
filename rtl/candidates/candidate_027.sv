r6_ab_and`, `r6_ab_or`, `r6_ab_xor`

Stage 7:
Computes:
- `x25 = r6_x24 + r6_x20;`
- `x26 = x25 ^ r6_x21;`
- `x27 = x26 + r6_x22;`
- `x28 = x27 ^ r6_x23;`

Registers at end of Stage 7 (r7_...):
- `r7_op`
- `r7_x16`, `r7_x17`, `r7_x18`, `r7_x20`, `r7_x21`, `r7_x22`, `r7_x24`, `r7_x25`, `r7_x26`, `r7_x27`, `r7_x28`
- `r7_ab_add`, `r7_ab_sub`, `r7_ab_shl`, `r7_ab_mul`, `r7_ab_and`, `r7_ab_or`, `r7_ab_xor`

Stage 8:
Computes:
- `x29 = r7_x28 + r7_x24;`
- `x30 = x29 ^ r7_x