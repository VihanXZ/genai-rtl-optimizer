`.
  - `key_mem_ctrl_reg` transitions to `CTRL_GENERATE_S2`.

In state `CTRL_GENERATE_S2`:
- `round_key_update` is 1.
- `rotstw` and `tw` are computed from `new_sboxw_reg` (which is now driven by a register!).
- `round_key_gen` computes `key_mem_new`, `prev_key0_new`, `prev_key1_new`, `rcon_next`.
- At clock edge `posedge clk`:
  - `key_mem[round_ctr_reg]` <= `key_mem_new`.
  - `prev_key0_reg` <= `prev_key0_new`.
  - `prev_key1_reg` <= `prev_key1_new`.
  - `rcon_reg` <= `rcon_new`.
  - `round_ctr_reg` <= `round_ctr_reg + 1`.
  - `key_mem_ctrl_reg` <= `CTRL_GENERATE_S1` (or `CTRL_DONE`).

Let's check the path delays now!
Path 1 (in S1):
`prev_key1_reg` -> `w7` -> `tmp_sboxw` -> port `sboxw` -> external S-Box -> port `new_sboxw` -> `new_sbox