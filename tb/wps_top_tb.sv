`timescale 1ns/1ps
module wps_top_tb ();
logic   clk_125m;
logic   clk_250m;
logic   clk_148_5m;

logic   rst_n;
initial begin
    clk_125m = 0;
    forever begin
        #2 clk_125m = ~clk_125m;
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

reg         pattern_source_reg = 1'b1;
reg         start_play_reg = 1'b1;
reg [5:0]   rsv2_reg = 'h0;
reg         play_done_reg = 1'b0;
reg [22:0]  rsv0_reg = 'h0;
reg [31:0]  to_send_frame_reg = 'd1;
reg [31:0]  one_frame_byte_reg = 'd259200;
reg [15:0]  pattern_h_pix_reg = 'd1920;
reg [15:0]  pattern_v_line_reg = 'd1080;
reg [31:0]  to_send_total_byte_reg = one_frame_byte_reg * to_send_frame_reg;
reg [31:0]  start_addr_reg = 'h8;
reg [31:0]  capture_pulse_cycle_reg = 'd200;
reg [31:0]  rsv3_reg = 'h0;

logic [0:8][255:0]   onchip_mem;
logic           onchip_mem_clk;
logic           onchip_mem_read_data_valid, onchip_mem_read_r;
logic[12:0]     onchip_mem_addr_r1, onchip_mem_addr_r2;
logic           onchip_mem_chip_select;
logic           onchip_mem_clk_ena;
logic           onchip_mem_read;
logic [12:0]    onchip_mem_addr;
logic [31:0]    onchip_mem_byte_enable;
logic [255:0]   onchip_mem_write_data;
logic           onchip_mem_write;
logic [255:0]   onchip_mem_read_data;


assign onchip_mem_clk = clk_125m;
initial begin
    //ddr_mem[0] = {pat_h_pix, pat_v_pix, pat_total_pix, pat_num, h_fill_size, v_fill_size, pat_start_addr, pat_end_addr};
    onchip_mem[0] = {start_play_reg, pattern_source_reg,rsv2_reg,play_done_reg,rsv0_reg,to_send_frame_reg,one_frame_byte_reg,pattern_h_pix_reg,
    pattern_v_line_reg, to_send_total_byte_reg, start_addr_reg, capture_pulse_cycle_reg, rsv3_reg};
    onchip_mem[1] = 256'h202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f;
    onchip_mem[2] = 256'h404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f;
    onchip_mem[3] = 256'h606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f;
    onchip_mem[4] = 256'h808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f;
    onchip_mem[5] = 256'ha0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebf;
    onchip_mem[6] = 256'hc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedf;
    onchip_mem[7] = 256'he0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;
end
always @(posedge onchip_mem_clk) begin
    onchip_mem_addr_r1 <= onchip_mem_addr;
    onchip_mem_addr_r2 <= onchip_mem_addr_r1;
end

always_comb begin
    onchip_mem_read_data = onchip_mem[onchip_mem_addr_r2[2:0]];
end

//--------------------------------------------------------------

// DDR3 signals
logic           ddr3_emif_clk;
logic           ddr3_emif_rst_n;
logic           ddr3_emif_ready = 1;
logic [255:0]   ddr3_emif_read_data;
logic           ddr3_emif_read_data_valid;
logic           ddr3_emif_read;
logic [21:0]    ddr3_emif_addr;
logic [255:0]   ddr3_emif_write_data;
logic           ddr3_emif_write;
logic [31:0]    ddr3_emif_byte_enable;
logic [4:0]     ddr3_emif_burst_count;


/*
reg [31:0]  pat_h_pix = image_width/(H_FILLING_SIZE + 1), pat_v_pix = image_height/(V_FILLING_SIZE + 1), pat_total_pix = pat_h_pix * pat_v_pix;
reg [31:0]  pat_num = 4, h_fill_size = image_width/pat_h_pix - 1;
reg [31:0]  v_fill_size = image_height/pat_v_pix - 1;
reg [31:0]  pat_start_addr = 'd1, pat_end_addr = 'ha;
reg [31:0]  pat_rsv = 0;
*/
logic [11:0] ddr3_emif_read_r;
logic [8:0][255:0] ddr_mem;
always_comb begin
    ddr3_emif_clk = clk_125m;
    ddr3_emif_rst_n = rst_n;
end

initial begin
    //ddr_mem[0] = {pat_h_pix, pat_v_pix, pat_total_pix, pat_num, h_fill_size, v_fill_size, pat_start_addr, pat_end_addr};
    ddr_mem[0] = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    ddr_mem[1] = 256'h202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f;
    ddr_mem[2] = 256'h404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f;
    ddr_mem[3] = 256'h606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f;
    ddr_mem[4] = 256'h808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f;
    ddr_mem[5] = 256'ha0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebf;
    ddr_mem[6] = 256'hc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedf;
    ddr_mem[7] = 256'he0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;
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



logic [23:0]    pix_data_out;
logic           h_sync_out, v_sync_out, de_out;
wps_top wps_top_inst (
    .mem_clk               (ddr3_emif_clk),
    .mem_rst_n             (ddr3_emif_rst_n),
    .ddr3_emif_ready       (ddr3_emif_ready),
    .ddr3_emif_read_data   (ddr3_emif_read_data),
    .ddr3_emif_rddata_valid(ddr3_emif_rddata_valid),
    .ddr3_emif_read        (ddr3_emif_read),
    .ddr3_emif_write       (ddr3_emif_write),
    .ddr3_emif_addr        (ddr3_emif_addr),
    .ddr3_emif_write_data  (ddr3_emif_write_data),
    .ddr3_emif_byte_enable (ddr3_emif_byte_enable),
    .ddr3_emif_burst_count (ddr3_emif_burst_count),

    .onchip_mem_chip_select(onchip_mem_chip_select),
    .onchip_mem_clk_ena    (onchip_mem_clk_ena),
    .onchip_mem_addr       (onchip_mem_addr),
    .onchip_mem_byte_enable(onchip_mem_byte_enable),
    .onchip_mem_write_data (onchip_mem_write_data),
    .onchip_mem_write      (onchip_mem_write),
    .onchip_mem_read_data  (onchip_mem_read_data),

    .clk250m               (clk_250m),
    .clk250m_rst_n         (rst_n),
    .clk148_5m             (clk_148_5m),
    .clk148_5m_rst_n       (rst_n),
    .h_sync_out            (h_sync_out),
    .v_sync_out            (v_sync_out),
    .de_out                (de_out),
    .pix_data_out          (pix_data_out)

    );
/*
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
*/
integer w_file;

initial w_file = $fopen("output_data.txt");

always @(posedge clk_148_5m) begin
    if (de_out)
        $fdisplay(w_file, "%h", pix_data_out);
end
endmodule