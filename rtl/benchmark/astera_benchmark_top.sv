// Astera-V Benchmark SoC Top Level
// 5 master async clock domains, 5 generated clocks, CDC, clock dividers
module astera_benchmark_top (
    // 5 Master Clocks
    input  wire        clk_cpu,
    input  wire        clk_aes,
    input  wire        clk_fpu,
    input  wire        clk_mem,
    input  wire        clk_periph,

    // Global async reset (active low)
    input  wire        rst_n,

    // PicoRV32 memory interface (directly exposed for STA)
    output wire        mem_valid,
    input  wire        mem_ready,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    output wire [ 3:0] mem_wstrb,
    input  wire [31:0] mem_rdata,

    // AES interface
    input  wire        aes_start,
    input  wire [127:0] aes_key,
    input  wire [127:0] aes_plaintext,
    output wire [127:0] aes_ciphertext,
    output wire        aes_done,

    // FIR filter interface
    input  wire        fir_valid_in,
    input  wire [15:0] fir_data_in,
    output wire        fir_valid_out,
    output wire [35:0] fir_data_out,

    // SRAM interface
    input  wire        sram_req,
    input  wire        sram_wr_en,
    input  wire [11:0] sram_addr,
    input  wire [31:0] sram_wdata,
    output wire [31:0] sram_rdata_out,
    output wire        sram_ready,

    // UART interface
    input  wire [7:0]  uart_tx_data,
    input  wire        uart_tx_valid,
    output wire        uart_tx_out,
    output wire        uart_tx_busy
);

    // ================================================================
    // CLOCK DIVIDERS (one per master, multiple ratios)
    // ================================================================
    wire clk_cpu_div2;
    wire clk_aes_div4;
    wire clk_fpu_div2;
    wire clk_mem_div8;
    wire clk_periph_div4;

    clock_divider #(.DIV_RATIO(2)) cpu_divider (
        .clk_in  (clk_cpu),
        .rst_n   (rst_n),
        .clk_out (clk_cpu_div2)
    );

    clock_divider #(.DIV_RATIO(4)) aes_divider (
        .clk_in  (clk_aes),
        .rst_n   (rst_n),
        .clk_out (clk_aes_div4)
    );

    clock_divider #(.DIV_RATIO(2)) fpu_divider (
        .clk_in  (clk_fpu),
        .rst_n   (rst_n),
        .clk_out (clk_fpu_div2)
    );

    clock_divider #(.DIV_RATIO(8)) mem_divider (
        .clk_in  (clk_mem),
        .rst_n   (rst_n),
        .clk_out (clk_mem_div8)
    );

    clock_divider #(.DIV_RATIO(4)) periph_divider (
        .clk_in  (clk_periph),
        .rst_n   (rst_n),
        .clk_out (clk_periph_div4)
    );

    // ================================================================
    // DOMAIN 1: PicoRV32 RISC-V CPU (clk_cpu)
    // ================================================================
    wire        cpu_trap;
    wire        cpu_mem_valid;
    wire        cpu_mem_instr;
    wire        cpu_mem_ready;
    wire [31:0] cpu_mem_addr;
    wire [31:0] cpu_mem_wdata;
    wire [ 3:0] cpu_mem_wstrb;
    wire [31:0] cpu_mem_rdata;

    // IRQ interface (active-high, directly exposed)
    wire [31:0] irq = 32'b0;
    wire [31:0] eoi;

    picorv32 #(
        .ENABLE_MUL      (1),
        .ENABLE_DIV      (1),
        .ENABLE_IRQ      (1),
        .BARREL_SHIFTER  (1),
        .COMPRESSED_ISA  (1)
    ) cpu_core (
        .clk       (clk_cpu),
        .resetn    (rst_n),
        .trap      (cpu_trap),
        .mem_valid (cpu_mem_valid),
        .mem_instr (cpu_mem_instr),
        .mem_ready (cpu_mem_ready),
        .mem_addr  (cpu_mem_addr),
        .mem_wdata (cpu_mem_wdata),
        .mem_wstrb (cpu_mem_wstrb),
        .mem_rdata (cpu_mem_rdata),
        .irq       (irq),
        .eoi       (eoi),
        // Unused look-ahead interface
        .mem_la_read  (),
        .mem_la_write (),
        .mem_la_addr  (),
        .mem_la_wdata (),
        .mem_la_wstrb (),
        // Unused trace/PCPI
        .pcpi_valid (),
        .pcpi_insn  (),
        .pcpi_rs1   (),
        .pcpi_rs2   (),
        .pcpi_wr    (1'b0),
        .pcpi_rd    (32'b0),
        .pcpi_wait  (1'b0),
        .pcpi_ready (1'b0),
        .trace_valid(),
        .trace_data ()
    );

    assign mem_valid    = cpu_mem_valid;
    assign cpu_mem_ready = mem_ready;
    assign mem_addr     = cpu_mem_addr;
    assign mem_wdata    = cpu_mem_wdata;
    assign mem_wstrb    = cpu_mem_wstrb;
    assign cpu_mem_rdata = mem_rdata;

    // ================================================================
    // CDC: CPU domain (clk_cpu) -> AES domain (clk_aes)
    // Using Async FIFO for safe clock domain crossing
    // ================================================================
    wire [31:0] cpu_to_aes_data;
    wire        cpu_to_aes_empty;
    wire        cpu_to_aes_full;

    async_fifo #(.DATA_WIDTH(32), .ADDR_WIDTH(4)) cdc_cpu_to_aes (
        .wr_clk   (clk_cpu),
        .wr_rst_n (rst_n),
        .wr_en    (cpu_mem_valid & ~cpu_to_aes_full),
        .wr_data  (cpu_mem_wdata),
        .wr_full  (cpu_to_aes_full),
        .rd_clk   (clk_aes),
        .rd_rst_n (rst_n),
        .rd_en    (~cpu_to_aes_empty),
        .rd_data  (cpu_to_aes_data),
        .rd_empty (cpu_to_aes_empty)
    );

    // ================================================================
    // CDC: CPU domain (clk_cpu) -> FPU domain (clk_fpu)
    // ================================================================
    wire [31:0] cpu_to_fpu_data;
    wire        cpu_to_fpu_empty;
    wire        cpu_to_fpu_full;

    async_fifo #(.DATA_WIDTH(32), .ADDR_WIDTH(4)) cdc_cpu_to_fpu (
        .wr_clk   (clk_cpu),
        .wr_rst_n (rst_n),
        .wr_en    (cpu_mem_valid & cpu_mem_wstrb[0] & ~cpu_to_fpu_full),
        .wr_data  (cpu_mem_wdata),
        .wr_full  (cpu_to_fpu_full),
        .rd_clk   (clk_fpu),
        .rd_rst_n (rst_n),
        .rd_en    (~cpu_to_fpu_empty),
        .rd_data  (cpu_to_fpu_data),
        .rd_empty (cpu_to_fpu_empty)
    );

    // ================================================================
    // DOMAIN 2: AES-128 Crypto Accelerator (clk_aes)
    // ================================================================
    wire        aes_result_valid;
    wire [127:0] aes_result;
    wire        aes_ready;

    aes_core aes_engine (
        .clk       (clk_aes),
        .reset_n   (rst_n),
        .encdec    (1'b1),       // Encrypt mode
        .init      (aes_start),
        .next      (1'b0),
        .ready     (aes_ready),
        .key       (aes_key),
        .keylen    (1'b0),       // AES-128
        .block     (aes_plaintext),
        .result    (aes_result),
        .result_valid(aes_result_valid)
    );

    assign aes_ciphertext = aes_result;
    assign aes_done = aes_result_valid;

    // ================================================================
    // DOMAIN 3: FIR Filter / DSP (clk_fpu)
    // ================================================================
    fir_filter #(
        .DATA_WIDTH (16),
        .COEFF_WIDTH(16),
        .NUM_TAPS   (16),
        .OUT_WIDTH  (36)
    ) dsp_filter (
        .clk       (clk_fpu),
        .rst_n     (rst_n),
        .valid_in  (fir_valid_in),
        .data_in   (fir_data_in),
        .valid_out (fir_valid_out),
        .data_out  (fir_data_out)
    );

    // ================================================================
    // DOMAIN 4: SRAM Controller (clk_mem)
    // ================================================================
    wire [31:0] sram_rdata_internal;

    sram_controller #(
        .ADDR_WIDTH(12),
        .DATA_WIDTH(32)
    ) mem_ctrl (
        .clk        (clk_mem),
        .rst_n      (rst_n),
        .req        (sram_req),
        .wr_en      (sram_wr_en),
        .addr       (sram_addr),
        .wdata      (sram_wdata),
        .rdata      (sram_rdata_out),
        .ready      (sram_ready),
        .sram_ce_n  (),
        .sram_we_n  (),
        .sram_oe_n  (),
        .sram_addr  (),
        .sram_wdata (),
        .sram_rdata (32'b0)
    );

    // ================================================================
    // DOMAIN 5: UART (clk_periph)
    // ================================================================
    uart_tx #(
        .CLK_FREQ  (100000000),
        .BAUD_RATE (115200)
    ) uart_transmitter (
        .clk      (clk_periph),
        .rst_n    (rst_n),
        .tx_data  (uart_tx_data),
        .tx_valid (uart_tx_valid),
        .tx_out   (uart_tx_out),
        .tx_busy  (uart_tx_busy)
    );

endmodule
