tw_pipe_reg      <= 32'h0;
        end
      else
        begin
          if (ready_we)
            ready_reg <= ready_new;

          if (rcon_we)
            rcon_reg <= rcon_new;

          if (round_ctr_we)
            round_ctr_reg <= round_ctr_new;

          if (key_mem_we)
            key_mem[round_ctr_reg] <= key_mem_new;

          if (prev_key0_we)
            prev_key0_reg <= prev_key0_new;

          if (prev_key1_we)
            prev_key1_reg <= prev_key1_new;

          if (key_mem_ctrl_we)
            key_mem_ctrl_reg <= key_mem_ctrl_new;

          if (pipe_we)
            begin
              w0_pipe_reg  <= w0_pipe_new;
              w1_pipe_reg  <= w1_pipe_new;
              w2_pipe_reg  <= w2_pipe_new;
              w3_pipe_reg  <= w3_pipe_new;
              w4_pipe_reg  <= w4_pipe_new;
              w5_pipe_reg  <= w5_pipe_new;
              w6_pipe_reg  <= w6_pipe_