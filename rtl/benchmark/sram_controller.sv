// Simple SRAM Controller with read/write FSM
module sram_controller #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    req,
    input  wire                    wr_en,
    input  wire [ADDR_WIDTH-1:0]   addr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output reg  [DATA_WIDTH-1:0]   rdata,
    output reg                     ready,
    output reg                     sram_ce_n,
    output reg                     sram_we_n,
    output reg                     sram_oe_n,
    output reg  [ADDR_WIDTH-1:0]   sram_addr,
    output reg  [DATA_WIDTH-1:0]   sram_wdata,
    input  wire [DATA_WIDTH-1:0]   sram_rdata
);

    localparam IDLE    = 3'd0;
    localparam SETUP   = 3'd1;
    localparam WRITE   = 3'd2;
    localparam READ    = 3'd3;
    localparam HOLD    = 3'd4;
    localparam DONE    = 3'd5;

    reg [2:0] state, next_state;
    reg [1:0] wait_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:    if (req) next_state = SETUP;
            SETUP:   next_state = wr_en ? WRITE : READ;
            WRITE:   next_state = HOLD;
            READ:    next_state = HOLD;
            HOLD:    if (wait_cnt == 2'd2) next_state = DONE;
            DONE:    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready     <= 1'b1;
            sram_ce_n <= 1'b1;
            sram_we_n <= 1'b1;
            sram_oe_n <= 1'b1;
            sram_addr <= 0;
            sram_wdata <= 0;
            rdata     <= 0;
            wait_cnt  <= 0;
        end else begin
            case (state)
                IDLE: begin
                    ready     <= 1'b1;
                    sram_ce_n <= 1'b1;
                    sram_we_n <= 1'b1;
                    sram_oe_n <= 1'b1;
                    wait_cnt  <= 0;
                end
                SETUP: begin
                    ready     <= 1'b0;
                    sram_addr <= addr;
                    sram_ce_n <= 1'b0;
                end
                WRITE: begin
                    sram_we_n  <= 1'b0;
                    sram_wdata <= wdata;
                end
                READ: begin
                    sram_oe_n <= 1'b0;
                end
                HOLD: begin
                    wait_cnt <= wait_cnt + 1;
                    if (!sram_oe_n)
                        rdata <= sram_rdata;
                end
                DONE: begin
                    sram_ce_n <= 1'b1;
                    sram_we_n <= 1'b1;
                    sram_oe_n <= 1'b1;
                    ready     <= 1'b1;
                end
            endcase
        end
    end

endmodule
