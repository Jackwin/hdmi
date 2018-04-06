`timescale 1ns/1ps
module wps_top_tb ();
logic   clk_125m;
logic   clk_250m;
logic   clk_148_5m;

logic   rst_n;
initial begin
    clk_125m = 0;
    forever begin
        #4 clk_125m = ~clk_125m;
    end
end

initial begin
    clk_250m = 0;
    forever begin
        #2 clk_250m = ~clk_250m;
    end
end

initial begin
    clk_148_5m = 0;
    forever begin
        #3.267 clk_148_5m = ~clk_148_5m;
    end
end

initial begin
    rst_n = 1;
    #50 rst_n = 0;
    #15 rst_n = 1;
end

logic [0:1023][255:0]   onchip_mem;

logic           onchip_mem_select;
logic           onchip_mem_read;
logic [10:0]    onchip_mem_addr;
logic [31:0]    onchip_mem_byte_enable;
logic [255:0]   onchip_mem_write_data;
logic           onchip_mem_write;
logic [255:0]   onchip_mem_read_data;
logic [23:0]    pix_data_out;

// DDR3 signals
logic           ddr3_emif_clk;
logic           ddr3_emif_rst_n;
logic           ddr3_emif_ready = 1;
logic [255:0]   ddr3_emif_read_data;
logic           ddr3_emif_read_data_valid;
logic           ddr3_emif_read;
logic [21:0]    ddr3_emif_addr;


logic [8:0][255:0] ddr_mem;
/*
reg [31:0]  pat_h_pix = image_width/(H_FILLING_SIZE + 1), pat_v_pix = image_height/(V_FILLING_SIZE + 1), pat_total_pix = pat_h_pix * pat_v_pix;
reg [31:0]  pat_num = 4, h_fill_size = image_width/pat_h_pix - 1;
reg [31:0]  v_fill_size = image_height/pat_v_pix - 1;
reg [31:0]  pat_start_addr = 'd1, pat_end_addr = 'ha;
reg [31:0]  pat_rsv = 0;
*/
logic [11:0] ddr3_emif_read_r;

always_comb begin
    ddr3_emif_clk = clk_125m;
    ddr3_emif_rst_n = rst_n;

end



initial begin
    //ddr_mem[0] = {pat_h_pix, pat_v_pix, pat_total_pix, pat_num, h_fill_size, v_fill_size, pat_start_addr, pat_end_addr};
    ddr_mem[0] = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    ddr_mem[1] = 256'hfafafafafafafafafafafafafafafafafafafafa0438078000001fa400000001;
    ddr_mem[2] = 256'habababababababababababababababababababababababababababababababab;
    ddr_mem[3] = 256'h7777777777777777777777777777777777777777777777777777777777777777;
    ddr_mem[4] = 256'hf0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0;
    ddr_mem[5] = 256'hfafafafafafafafafafafafafafafafafafafafafafafafafafafafafafafafa;
    ddr_mem[6] = 256'habababababababababababababababababababababababababababababababab;
    ddr_mem[7] = 256'h7777777777777777777777777777777777777777777777777777777777777777;
    ddr_mem[8] = 256'hbabababababababababababababababababababababababababababababababa;
end


always_ff @(posedge ddr3_emif_clk or negedge ddr3_emif_rst_n) begin : proc_ddr_read
    if(~ddr3_emif_rst_n) begin
        ddr3_emif_read_data <= 0;
        ddr3_emif_read_data_valid <= 0;
    end else begin
        ddr3_emif_read_data_valid <= 0;
        if (ddr3_emif_read_r[11]) begin
            ddr3_emif_read_data <= ddr_mem[ddr3_emif_addr[2:0]];
            ddr3_emif_read_data_valid <= 1;
        end
    end
end

// ddr3 read delay
always @(posedge ddr3_emif_clk) begin
    ddr3_emif_read_r[11:0] <= {ddr3_emif_read_r[10:0], ddr3_emif_read};
end

// ddr3_usr_logic signals ----------------------------------
logic             ddr3_usr_logic_read_req = 1'b1;
logic            ddr3_usr_logic_data_ready;
logic [255+32:0] ddr3_usr_logic_read_data;
logic            ddr3_usr_logic_read_data_valid;

logic           drr3_read_start, ddr3_read_done;
logic [31:0]     usr_start_addr;
logic [31:0]     to_read_byte;
logic [31:0]     to_read_frame_num;
logic [31:0]     one_frame_byte;

initial begin
     drr3_read_start = 'h0;
     usr_start_addr = 'h0;
     to_read_byte = 'h0;
     to_read_frame_num = 'h0;
    #400;
    @(posedge ddr3_emif_clk) begin
        drr3_read_start <= 1'b1;
        usr_start_addr <= 'h8;
        to_read_byte <= 32'd259200;
        to_read_frame_num <= 'h0;
    end
    @(posedge ddr3_emif_clk) begin
        drr3_read_start <= 1'b0;
    end
end



ddr3_usr_logic ddr3_usr_logic_inst (
    .ddr3_emif_clk         (ddr3_emif_clk),
    .ddr3_emif_rst_n       (ddr3_emif_rst_n),
    .ddr3_emif_ready       (ddr3_emif_ready),
    .ddr3_emif_read_data   (ddr3_emif_read_data),
    .ddr3_emif_rddata_valid(ddr3_emif_read_data_valid),
    .ddr3_emif_read        (ddr3_emif_read),
    .ddr3_emif_write       (ddr3_emif_write),
    .ddr3_emif_addr        (ddr3_emif_addr),
    .ddr3_emif_write_data  (ddr3_emif_write_data),
    .ddr3_emif_byte_enable (ddr3_emif_byte_enable),
    .ddr3_emif_burst_count (ddr3_emif_burst_count),

    // To wps_controller.v
    .ddr3_usr_start_addr_in(usr_start_addr[26:0]),
    .to_read_frame_num_in  (to_read_frame_num),
    .to_read_byte_in       (to_read_byte),
    .one_frame_byte_in     (one_frame_byte),
    .ddr3_read_start       (drr3_read_start),
    .ddr3_read_done_out    (ddr3_read_done),

    //interface_256in_24out.v
    .read_req_in           (ddr3_usr_logic_read_req),
    .data_ready_out        (ddr3_usr_logic_data_ready),
    .read_data_out         (ddr3_usr_logic_read_data),
    .read_data_valid_out   (ddr3_usr_logic_read_data_valid)
);

endmodule