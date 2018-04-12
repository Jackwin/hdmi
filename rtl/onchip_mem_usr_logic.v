`timescale 1ns/1ps

module onchip_mem_usr_logic (
   input                clk,
   input                rst_n,

    output reg          onchip_mem_chip_select,
    output              onchip_mem_clk_ena,
    output reg          onchip_mem_read,
    output reg [12:0]   onchip_mem_addr,
    input               onchip_mem_read_valid,
    input [255:0]       onchip_mem_read_data,

    input [17:0]        onchip_mem_start_addr_in,
    input [31:0]        to_read_byte_in,
    input               onchip_mem_read_start_in,
    output reg          onchip_mem_read_done_out,

    input               read_req_in,
    output              data_ready_out,
    output [255+32:0]   read_data_out,
    output              read_data_valid_out

);

localparam  IDLE = 3'd0,
            FIRST_READ = 3'd1,
            READ = 3'd2,
            WAIT = 3'd3,
            LAST_READ = 3'd4;

reg [2:0]   state;
// Register
reg [31:0]  to_read_byte_reg;
reg [31:0]  to_read_left_byte_reg;
reg [12:0]  onchip_mem_start_addr_reg;
reg [31:0]  onchip_mem_data_byte_valid;

// FIFO
reg [255+32:0]    fifo_din;
reg                 fifo_wr_ena;
wire                fifo_full;
wire                fifo_clk;
wire                fifo_rd_ena;
wire                fifo_empty;
wire [255+32:0]   fifo_dout;
reg                 fifo_dout_valid;

assign onchip_mem_clk_ena = 1'b1;
assign data_ready_out = ~fifo_empty;
assign read_data_out = fifo_dout;
assign read_data_valid_out = fifo_dout_valid;

// FIFO
assign fifo_clk = clk;
assign fifo_rd_ena = read_req_in;

always @(posedge clk) begin
    if (~rst_n) begin
        fifo_dout_valid <= 1'b0;
    end
    else begin
        fifo_dout_valid <= fifo_rd_ena & ~fifo_empty;
    end
end

// The read latency is 2 for the onchip memory
/*
always @(posedge clk) begin
    mem_rd_r <= onchip_mem_read;
    mem_rd_valid <= mem_rd_r;
end
*/
always @(posedge clk) begin
    if(~rst_n) begin
        state <= IDLE;
        to_read_byte_reg <= 'h0;
        onchip_mem_start_addr_reg <= 'h0;
        fifo_wr_ena <= 1'b0;
        onchip_mem_read_done_out <= 1'b0;
        onchip_mem_read <= 1'b0;
    end else begin
        fifo_wr_ena <= 1'b0;
        onchip_mem_read <= 1'b0;
         case(state)
            IDLE: begin
                if (onchip_mem_read_start_in) begin
                    to_read_byte_reg <= to_read_byte_in;
                    to_read_left_byte_reg <= to_read_byte_in;
                    onchip_mem_start_addr_reg <= onchip_mem_start_addr_in[17:5];
                    case(onchip_mem_start_addr_in[4:0])
                        5'd0:onchip_mem_data_byte_valid <= 32'hffffffff;
                        5'd1:onchip_mem_data_byte_valid <= 32'h7fffffff;
                        5'd2:onchip_mem_data_byte_valid <= 32'h3fffffff;
                        5'd3:onchip_mem_data_byte_valid <= 32'h1fffffff;
                        5'd4:onchip_mem_data_byte_valid <= 32'h0fffffff;
                        5'd5:onchip_mem_data_byte_valid <= 32'h07ffffff;
                        5'd6:onchip_mem_data_byte_valid <= 32'h03ffffff;
                        5'd7:onchip_mem_data_byte_valid <= 32'h01ffffff;
                        5'd8:onchip_mem_data_byte_valid <= 32'h00ffffff;
                        5'd9:onchip_mem_data_byte_valid <= 32'h007fffff;
                        5'd10:onchip_mem_data_byte_valid <= 32'h003fffff;
                        5'd11:onchip_mem_data_byte_valid <= 32'h001fffff;
                        5'd12:onchip_mem_data_byte_valid <= 32'h000fffff;
                        5'd13:onchip_mem_data_byte_valid <= 32'h0007ffff;
                        5'd14:onchip_mem_data_byte_valid <= 32'h0003ffff;
                        5'd15:onchip_mem_data_byte_valid <= 32'h0001ffff;
                        5'd16:onchip_mem_data_byte_valid <= 32'h0000ffff;
                        5'd17:onchip_mem_data_byte_valid <= 32'h00007fff;
                        5'd18:onchip_mem_data_byte_valid <= 32'h00003fff;
                        5'd19:onchip_mem_data_byte_valid <= 32'h00001fff;
                        5'd20:onchip_mem_data_byte_valid <= 32'h00000fff;
                        5'd21:onchip_mem_data_byte_valid <= 32'h000007ff;
                        5'd22:onchip_mem_data_byte_valid <= 32'h000003ff;
                        5'd23:onchip_mem_data_byte_valid <= 32'h000001ff;
                        5'd24:onchip_mem_data_byte_valid <= 32'h000000ff;
                        5'd25:onchip_mem_data_byte_valid <= 32'h0000007f;
                        5'd26:onchip_mem_data_byte_valid <= 32'h0000003f;
                        5'd27:onchip_mem_data_byte_valid <= 32'h0000001f;
                        5'd28:onchip_mem_data_byte_valid <= 32'h0000000f;
                        5'd29:onchip_mem_data_byte_valid <= 32'h7;
                        5'd30:onchip_mem_data_byte_valid <= 32'h3;
                        5'd31:onchip_mem_data_byte_valid <= 32'h1;
                    endcase // onchip_mem_start_addr_in[4:0]
                    state <= FIRST_READ;
                end
            end
            FIRST_READ: begin
                if (~fifo_full) begin
                    onchip_mem_chip_select <= 1'b1;
                    onchip_mem_read <= 1'b1;
                    onchip_mem_addr <= onchip_mem_start_addr_reg;
                    to_read_left_byte_reg <= to_read_left_byte_reg - (6'd32 - onchip_mem_addr[4:0]);
                    state <= WAIT;
                end
            end
            WAIT: begin
                if (onchip_mem_read_valid) begin
                    fifo_wr_ena <= 1'b1;
                    fifo_din <= {onchip_mem_read_data, onchip_mem_data_byte_valid};
                    onchip_mem_addr <= onchip_mem_addr + 1'd1;
                    if (to_read_left_byte_reg == 'h0) begin
                        onchip_mem_read_done_out <= 1'b1;
                        state <= IDLE;
                    end
                    else if (to_read_left_byte_reg < 6'd32) begin
                        state <= LAST_READ;
                    end
                    else begin
                        state <= READ;
                    end
                end
            end
            READ: begin
                if (~fifo_full) begin
                    onchip_mem_chip_select <= 1'b1;
                    onchip_mem_read <= 1'b1;
                    onchip_mem_data_byte_valid <= 32'hffffffff;
                    to_read_left_byte_reg <= to_read_left_byte_reg - 6'd32;
                    state <= WAIT;
                end
            end
            LAST_READ: begin
                if (~fifo_full) begin
                    onchip_mem_chip_select <= 1'b1;
                    onchip_mem_read <= 1'b1;
                    to_read_left_byte_reg <= 'h0;
                     case(to_read_byte_reg[4:0])
                        5'd0: onchip_mem_data_byte_valid <= 32'h0;
                        5'd1: onchip_mem_data_byte_valid <= 32'h80000000;
                        5'd2: onchip_mem_data_byte_valid <= 32'hc0000000;
                        5'd3: onchip_mem_data_byte_valid <= 32'he0000000;
                        5'd4: onchip_mem_data_byte_valid <= 32'hf0000000;
                        5'd5: onchip_mem_data_byte_valid <= 32'hf8000000;
                        5'd6: onchip_mem_data_byte_valid <= 32'hfc000000;
                        5'd7: onchip_mem_data_byte_valid <= 32'hfe000000;
                        5'd8: onchip_mem_data_byte_valid <= 32'hff000000;
                        5'd9: onchip_mem_data_byte_valid <= 32'hff800000;
                        5'd10:onchip_mem_data_byte_valid <= 32'hffc00000;
                        5'd11:onchip_mem_data_byte_valid <= 32'hffe00000;
                        5'd12:onchip_mem_data_byte_valid <= 32'hfff00000;
                        5'd13:onchip_mem_data_byte_valid <= 32'hfff80000;
                        5'd14:onchip_mem_data_byte_valid <= 32'hfffc0000;
                        5'd15:onchip_mem_data_byte_valid <= 32'hfffe0000;
                        5'd16:onchip_mem_data_byte_valid <= 32'hffff0000;
                        5'd17:onchip_mem_data_byte_valid <= 32'hffff8000;
                        5'd18:onchip_mem_data_byte_valid <= 32'hffffc000;
                        5'd19:onchip_mem_data_byte_valid <= 32'hffffe000;
                        5'd20:onchip_mem_data_byte_valid <= 32'hfffff000;
                        5'd21:onchip_mem_data_byte_valid <= 32'hfffff800;
                        5'd22:onchip_mem_data_byte_valid <= 32'hfffffc00;
                        5'd23:onchip_mem_data_byte_valid <= 32'hfffffe00;
                        5'd24:onchip_mem_data_byte_valid <= 32'hffffff00;
                        5'd25:onchip_mem_data_byte_valid <= 32'hffffff80;
                        5'd26:onchip_mem_data_byte_valid <= 32'hffffffc0;
                        5'd27:onchip_mem_data_byte_valid <= 32'hffffffe0;
                        5'd28:onchip_mem_data_byte_valid <= 32'hfffffff0;
                        5'd29:onchip_mem_data_byte_valid <= 32'hfffffff8;
                        5'd30:onchip_mem_data_byte_valid <= 32'hfffffffc;
                        5'd31:onchip_mem_data_byte_valid <= 32'hfffffffe;
                    endcase
                    state <= WAIT;
                end
            end
            default: state <= IDLE;

        endcase // to_read_byte_reg[4:0]
    end
end

scfifo_288inx128 onchip_mem_fifo (
    .data  (fifo_din),  //  fifo_input.datain
    .wrreq (fifo_wr_ena), //            .wrreq
    .rdreq (fifo_rd_ena), //            .rdreq
    .clock (fifo_clk), //            .clk
    .q     (fifo_dout),     // fifo_output.dataout
    .usedw (), //            .usedw
    .full  (fifo_full),  //            .full
    .empty (fifo_empty)  //            .empty
);


endmodule