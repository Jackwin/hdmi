`timescale 1ns/1ps
`define RX_CLK_PERIOD 6.4
`define TX_CLK_PERIOD 5.0
`define TX_CLK_32bit  2.8
module recv_data_buffer_tb ();


logic            avl_st_rx_clk;
logic            avl_st_rx_rst_n;

logic [63:0]     avl_st_rx_data;
logic [2:0]      avl_st_rx_empty;
logic            avl_st_rx_eop;
logic [5:0]      avl_st_rx_error;
logic            avl_st_rx_ready;
logic            avl_st_rx_sop;
logic            avl_st_rx_val;

logic            crcbad_in;
logic            crcvalid_in;

logic            avl_st_tx_clk;
logic            avl_st_tx_rst_n;

logic [63:0]     avl_st_tx_data;
logic [2:0]      avl_st_tx_empty;
logic            avl_st_tx_eop;
logic            avl_st_tx_error;
logic            avl_st_tx_ready;
logic            avl_st_tx_sop;
logic            avl_st_tx_val;

logic           clk, reset;
logic           data_gen_ena;
logic [15:0]    data_gen_length;
logic [7:0]     total_pkt_gen;
logic [63:0]    data_output;
logic           data_valid;
logic [2:0]     data_emp;
logic           data_sop;
logic           data_eop;
logic [5:0]     data_error;
logic           data_ready;

logic [47:0]    DES_MAC = 48'hF0F1F2F3F4F5;
logic [47:0]    SRC_MAC = 48'h505152535455;


logic [7:0]     address;
logic           write;
logic           read;
logic           waitrequest;
logic [31:0]    writedata;
logic [31:0]    readdata;

logic [63:0]    avl_data_o;
logic           avl_valid_o;
logic [2:0]     avl_emp_o;
logic           avl_sop_o;
logic           avl_eop_o;

logic [63:0]    avl_tx_data_o;
logic           avl_tx_valid_o;
logic [2:0]     avl_tx_emp_o;
logic           avl_tx_sop_o;
logic           avl_tx_eop_o;
//----------- 32-bit data generation ------------
logic           tx_clk, tx_reset;
logic           tx_data_gen_ena;
logic [15:0]    tx_data_gen_length;
logic [7:0]     total_pkt;
logic [31:0]    tx_data_o;
logic [1:0]     tx_emp_o;
logic           tx_val_o;
logic           tx_sop_o;
logic           tx_eop_o;
logic           tx_ready;

logic           gen;

 //  logicister Address
parameter           ADDR_NUMPKTS     = 8'h0;
parameter           ADDR_RANDOMLENGTH    = 8'h1;
parameter           ADDR_RANDOMPAYLOAD   = 8'h2;
parameter           ADDR_START       = 8'h3;
parameter           ADDR_STOP        = 8'h4;
parameter           ADDR_MACSA0      = 8'h5;
parameter           ADDR_MACSA1      = 8'h6;
parameter           ADDR_MACDA0      = 8'h7;
parameter           ADDR_MACDA1      = 8'h8;
parameter           ADDR_TXPKTCNT    = 8'h9;
parameter           ADDR_RNDSEED0    = 8'ha;
parameter           ADDR_RNDSEED1    = 8'hb;
parameter           ADDR_RNDSEED2    = 8'hc;
parameter           ADDR_PKTLENGTH   = 8'hd;

parameter           ADDR_CNTDASA     = 8'hf0;
parameter           ADDR_CNTSATLEN   = 8'hf1;
parameter           ADDR_CNTDATA     = 8'hf2;
parameter           ADDR_CNTTRNSTN   = 8'hf3;

initial begin
    avl_st_rx_clk = 0;
    avl_st_tx_clk = 0;
    tx_clk = 0;
    forever begin
        #(`RX_CLK_PERIOD/2) avl_st_rx_clk = ~avl_st_rx_clk;
        #(`RX_CLK_PERIOD/2) avl_st_tx_clk = ~avl_st_tx_clk;
        #(`TX_CLK_32bit/2) tx_clk = ~tx_clk;
    end
end

initial begin
    avl_st_rx_rst_n = 1;
    #50 avl_st_rx_rst_n = 0;
    #20 avl_st_rx_rst_n = 1;
end

initial begin
    avl_st_tx_rst_n = 1;
    #60 avl_st_tx_rst_n = 0;
    #20 avl_st_tx_rst_n = 1;
end

initial begin
    tx_reset = 0;
    #50 tx_reset = 1;
    #20 tx_reset = 0;
end

always_comb begin
    clk = avl_st_rx_clk;
    reset = ~avl_st_rx_rst_n;
end


initial begin
    data_gen_ena <= 1'b0;
    data_gen_length <= 'h0;
    total_pkt_gen <= 'h0;
    #120;
    @(posedge clk) begin
        data_gen_ena <= 1'b1;
        data_gen_length <= 127;
        total_pkt_gen <= 1;
    end

    @(posedge clk) begin
        data_gen_ena <= 1'b0;
        data_gen_length <= 123;
        total_pkt_gen <=1;
    end

    #1000;

    @(posedge clk) begin
    data_gen_ena <= 1'b1;
    data_gen_length <= 126;
    total_pkt_gen <= 3;
    end

    @(posedge clk) begin
        data_gen_ena <= 1'b0;
        data_gen_length <= 123;
        total_pkt_gen <=3;
    end
    //#90000;
    //$stop;
end

initial begin
    address <= 0;
    writedata <= 0;
    write <= 0;
    gen <= 0;

    #300;
  /*  @(posedge clk) begin
        address <= ADDR_START;
        write <= 1;
        writedata <= 1;
        gen = 1;
    end
*/
   // @(posedge clk) gen = 0;
    #1000;

    @(posedge clk) begin
        address <= ADDR_NUMPKTS;
        write <= 1;
        writedata <= 1;
    end

    @(posedge clk) begin
        address <= ADDR_PKTLENGTH;
        write <= 1;
        writedata <= 52;
    end

    @(posedge clk) begin
        address <= ADDR_MACSA1;
        write <= 1;
        writedata <= 32'hf1f2;
    end

    @(posedge clk) begin
        address <= ADDR_MACSA0;
        write <= 1;
        writedata <= 32'hf3f4f5f6;
    end

    @(posedge clk) begin
        address <= ADDR_MACDA1;
        write <= 1;
        writedata <= 32'h90e2;
    end

    @(posedge clk) begin
        address <= ADDR_MACDA0;
        write <= 1;
        writedata <= 32'hbac62d21;
    end


     @(posedge clk) begin
        address <= ADDR_START;
        write <= 1;
        writedata <= 1;
    end

end

initial begin
    tx_data_gen_ena <= 0;
    tx_data_gen_length <= 0;

    #200;
    @(posedge tx_clk) begin
        tx_data_gen_ena <= 1;
        tx_data_gen_length <= 127;
    end

    #80;
    @(posedge tx_clk) begin
        tx_data_gen_ena <= 0;
    end


    @(posedge tx_eop_o) begin
        tx_data_gen_ena <= 1;
        tx_data_gen_length <= 132;
    end

    #80;
    @(posedge tx_clk) begin
        tx_data_gen_ena <= 0;
    end


    #500;
        @(posedge tx_clk) begin
        tx_data_gen_ena <= 1;
        tx_data_gen_length <= 134;
    end

    #80;
    @(posedge tx_clk) begin
        tx_data_gen_ena <= 0;
    end
end


rx_data_gen rx_data_gen_i
(
    .clk            (clk),
    .reset          (reset),
    .data_gen_ena   (data_gen_ena),
    .data_gen_length(data_gen_length),
    .total_pkt_in   (total_pkt_gen),
    .data_output    (data_output),
    .data_valid     (data_valid),
    .data_emp       (data_emp),
    .data_sop       (data_sop),
    .data_eop       (data_eop),
    .data_error     (data_error),
    .data_ready     (avl_st_rx_ready)
);

always_comb begin : proc_recv_interface
    avl_st_rx_data = data_output;
    avl_st_rx_empty = data_emp;
    avl_st_rx_eop = data_eop;
    avl_st_rx_sop = data_sop;
    avl_st_rx_val = data_valid;
end

recv_data_buffer recv_data_buffer_i
(
    .avl_st_rx_clk  (avl_st_rx_clk),
    .avl_st_rx_rst_n(avl_st_rx_rst_n),
    .avl_st_rx_data (avl_st_rx_data),
    .avl_st_rx_empty(avl_st_rx_empty),
    .avl_st_rx_eop  (avl_st_rx_eop),
    .avl_st_rx_error(avl_st_rx_error),
    .avl_st_rx_ready(avl_st_rx_ready),
    .avl_st_rx_sop  (avl_st_rx_sop),
    .avl_st_rx_val  (avl_st_rx_val),

    .crcbad_in      (crcbad_in),
    .crcvalid_in    (crcvalid_in),

    .avl_st_tx_clk  (avl_st_tx_clk),
    .avl_st_tx_rst_n(avl_st_tx_rst_n),
    .avl_st_tx_data (avl_st_tx_data),
    .avl_st_tx_empty(avl_st_tx_empty),
    .avl_st_tx_eop  (avl_st_tx_eop),
    .avl_st_tx_ready(1'b1),
    .avl_st_tx_sop  (avl_st_tx_sop),
    .avl_st_tx_val  (avl_st_tx_val)
);

data_source_gen data_source_gen_i
(
    .clk(clk),
    .reset(reset),

    .address(address),
    .write(write),
    .read(read),
    .waitrequest(waitrequest),
    .writedata(writedata),
    .readdata(readdata),
    .gen         (gen),
    .avl_data_o(avl_data_o),
    .avl_valid_o(avl_valid_o),
    .avl_empty_o(avl_emp_o),
    .avl_sop_o(avl_sop_o),
    .avl_eop_o(avl_eop_o),
    .avl_error_o (),
    .avl_ready_in(1'b1)
    );

logic [63:0]     avl_st_tx_data_buf;
logic [2:0]      avl_st_tx_empty_buf;
logic            avl_st_tx_eop_buf;
logic            avl_st_tx_error_buf;
logic            avl_st_tx_ready_buf;
logic            avl_st_tx_sop_buf;
logic            avl_st_tx_val_buf;

//-----------------------------------


tx_data_gen tx_data_gen_i(
    .clk          (tx_clk),
    .reset        (tx_reset),
    .gen_ena      (tx_data_gen_ena),
    .gen_length_in(tx_data_gen_length),
    .total_pkt_in (total_pkt),
    .tx_data_o    (tx_data_o),
    .tx_val_o     (tx_val_o),
    .tx_emp_o     (tx_emp_o),
    .tx_sop_o     (tx_sop_o),
    .tx_eop_o     (tx_eop_o),
    .tx_ready_in  (tx_ready)
    );

send_data_buffer send_data_buffer_i
(
    .avl_st_rx_clk  (tx_clk),
    .avl_st_rx_rst_n(~tx_reset),
    .avl_st_rx_data (tx_data_o),
    .avl_st_rx_val  (tx_val_o),
    .avl_st_rx_sop  (tx_sop_o),
    .avl_st_rx_empty(tx_emp_o),
    .avl_st_rx_eop  (tx_eop_o),
    .avl_st_rx_ready(tx_ready),

    .avl_st_tx_clk  (avl_st_tx_clk),
    .avl_st_tx_rst_n(avl_st_tx_rst_n),
    .avl_st_tx_data (avl_st_tx_data_buf),
    .avl_st_tx_empty(avl_st_tx_empty_buf),
    .avl_st_tx_eop  (avl_st_tx_eop_buf),
    .avl_st_tx_ready(1'b1),
    .avl_st_tx_sop  (avl_st_tx_sop_buf),
    .avl_st_tx_val  (avl_st_tx_val_buf)
    );
//---------------------------------------
logic [63:0]    avl_data_o_ref;
logic           avl_valid_o_ref;
logic [2:0]     avl_emp_o_ref;
logic           avl_sop_o_ref;
logic           avl_eop_o_ref;
avalon_st_gen avalon_st_gen_i
(
    .clk(clk),
    .reset(reset),
    .address(address),
    .write(write),
    .read(read),
    .waitrequest(waitrequest),
    .writedata(writedata),
    .readdata(readdata),

    .tx_data(tx_data_o_ref),
    .tx_valid(tx_valid_o_ref),
    .tx_empty(tx_emp_o_ref),
    .tx_sop(tx_sop_o_ref),
    .tx_eop(tx_eop_o_ref),
    .tx_error (),
    .tx_ready(1'b1)
);


avl_data_gen avl_data_gen_i
(

    .clk(clk),
    .reset(reset),
    /*
    .address(address),
    .write(write),
    .read(read),
    .waitrequest(waitrequest),
    .writedata(writedata),
    .readdata(readdata),
*/
    .user_data_in  (avl_data_o),
    .user_valid_in (avl_valid_o),
    .user_empty_in (avl_emp_o),
    .user_sop_in   (avl_sop_o),
    .user_eop_in   (avl_eop_o),
    .user_ready_out(),

    .tx_data(avl_tx_data_o),
    .tx_valid(avl_tx_valid_o),
    .tx_empty(avl_tx_emp_o),
    .tx_sop(avl_tx_sop_o),
    .tx_eop(avl_tx_eop_o),
    .tx_error (),
    .tx_ready(1'b1)
    );

// ------------------------ sim mac_frame_construct ---------------------------

logic mac_clk, mac_rst_n;

logic [31:0] avl_st_rx_data_mac;
logic [1:0]    avl_st_rx_empty_mac;
logic           avl_st_rx_val_mac;
logic           avl_st_rx_sop_mac;
logic           avl_st_rx_eop_mac;
logic           avl_st_rx_error_mac;
logic           avl_st_rx_ready_mac;

logic [31:0] avl_st_tx_data_mac;
logic [1:0]    avl_st_tx_empty_mac;
logic           avl_st_tx_val_mac;
logic           avl_st_tx_sop_mac;
logic           avl_st_tx_eop_mac;
logic           avl_st_tx_error_mac;
logic           avl_st_tx_ready_mac;

initial begin
    mac_clk = 0;
    forever
        #1.65 mac_clk = ~mac_clk;
end

initial begin
    mac_rst_n = 1;
    #30 mac_rst_n = 0;
    #20 mac_rst_n = 1;
end

initial begin
    avl_st_rx_data_mac <= 0;
    avl_st_rx_val_mac <= 0;
    avl_st_rx_sop_mac <= 0;
    avl_st_rx_empty_mac <= 0;
    avl_st_rx_eop_mac <= 0;

    #80;

    @(posedge mac_clk) begin
        avl_st_rx_data_mac <= 32'h00010203;
        avl_st_rx_val_mac <= 1;
        avl_st_rx_sop_mac <= 1;
        avl_st_rx_empty_mac <= 0;
        avl_st_rx_eop_mac <= 0;
    end

    for (int i = 0; i < 24; i++) begin
        @(posedge mac_clk) begin
            avl_st_rx_data_mac <= avl_st_rx_data_mac + 32'h04040404;
            avl_st_rx_val_mac <= 1;
            avl_st_rx_sop_mac <= 0;
            avl_st_rx_empty_mac <= 0;
            avl_st_rx_eop_mac <= 0;
        end
    end

    @(posedge mac_clk) begin
        avl_st_rx_data_mac <= 32'hedededed;
        avl_st_rx_val_mac <= 1;
        avl_st_rx_sop_mac <= 0;
        avl_st_rx_empty_mac <= 0;
        avl_st_rx_eop_mac <= 1;
    end

    @(posedge mac_clk) begin
        avl_st_rx_data_mac <= 0;
        avl_st_rx_val_mac <= 0;
        avl_st_rx_sop_mac <= 0;
        avl_st_rx_empty_mac <= 0;
        avl_st_rx_eop_mac <= 0;
    end
end

mac_frame_construct mac_frame_construct_inst (
    .clk            (mac_clk),
    .rst_n          (mac_rst_n),
    .avl_st_rx_data (avl_st_rx_data_mac),
    .avl_st_rx_val  (avl_st_rx_val_mac),
    .avl_st_rx_sop  (avl_st_rx_sop_mac),
    .avl_st_rx_empty(avl_st_rx_empty_mac),
    .avl_st_rx_eop  (avl_st_rx_eop_mac),
    .avl_st_rx_ready(avl_st_rx_ready_mac),

    .avl_st_tx_data (avl_st_tx_data_mac),
    .avl_st_tx_empty(avl_st_tx_empty_mac),
    .avl_st_tx_eop  (avl_st_tx_eop_mac),
    .avl_st_tx_ready(avl_st_tx_ready_mac),
    .avl_st_tx_sop  (avl_st_tx_sop_mac),
    .avl_st_tx_val  (avl_st_tx_val_mac)
    );



//--------------------------- Sim recv_data_buffer_128in_32out and avalon_bridge_32bit_to_128bit----

logic       avl_st_rx_clk_128, avl_st_rx_rst_n_128;
logic [127:0] avl_st_rx_data_128;
logic [3:0]    avl_st_rx_empty_128;
logic           avl_st_rx_val_128;
logic           avl_st_rx_sop_128;
logic           avl_st_rx_eop_128;
logic           avl_st_rx_error_128 = 0;
logic           avl_st_rx_ready_128;

logic           avl_st_tx_clk_32;
logic           avl_st_tx_rst_n_32;
logic [31:0]    avl_st_tx_data_32;
logic [1:0]     avl_st_tx_empty_32;
logic           avl_st_tx_ready_32;
logic           avl_st_tx_eop_32;
logic           avl_st_tx_sop_32;
logic           avl_st_tx_val_32;

initial begin
    avl_st_rx_clk_128 = 0;
    forever
        #1.6 avl_st_rx_clk_128 = ~avl_st_rx_clk_128;
end

initial begin
    avl_st_rx_rst_n_128 = 1'b1;
    #50 avl_st_rx_rst_n_128 = 1'b0;
    #20 avl_st_rx_rst_n_128 = 1'b1;
end

initial begin
    avl_st_tx_clk_32 = 0;
    forever
        #1.65 avl_st_tx_clk_32 = ~avl_st_tx_clk_32;
end

initial begin
    avl_st_tx_rst_n_32 = 1'b1;
    #50 avl_st_tx_rst_n_32 = 1'b0;
    #20 avl_st_tx_rst_n_32 = 1'b1;
end

initial begin
    avl_st_rx_data_128 <= 0;
    avl_st_rx_empty_128 <= 0;
    avl_st_rx_eop_128 <= 0;
    avl_st_rx_sop_128 <= 0;
    avl_st_rx_val_128 <= 0;

    #400;

    for (int i = 0; i < 16; i++) begin
        @(posedge avl_st_rx_clk_128) begin
            avl_st_rx_data_128 <= {48'hF1F2F3F4F5F6, 48'h0001020304050607, 16'h8100, 16'h0};
            avl_st_rx_val_128 <= 1;
            avl_st_rx_empty_128 <= 0;
            avl_st_rx_sop_128 <= 1'b1;
            avl_st_rx_eop_128 <= 1'b0;
        end
        @(posedge avl_st_rx_clk_128) begin
            avl_st_rx_data_128 <= {16'd44, 8'd1, 8'd0, 96'h101112131415161718191a1b};
            avl_st_rx_val_128 <= 1;
            avl_st_rx_empty_128 <= 0;
            avl_st_rx_sop_128 <= 1'b0;
            avl_st_rx_eop_128 <= 1'b0;
        end

        @(posedge avl_st_rx_clk_128) begin
            avl_st_rx_data_128 <= 128'h1c1d1e1f202122232425262728292a2b;
            avl_st_rx_val_128 <= 1;
            avl_st_rx_empty_128 <= 0;
            avl_st_rx_sop_128 <= 1'b0;
            avl_st_rx_eop_128 <= 1'b0;
        end

        @(posedge avl_st_rx_clk_128) begin
            avl_st_rx_data_128 <= 128'h2c2d2e2f303132333435363738393a3b3c3d3e3f;
            avl_st_rx_val_128 <= 1;
            avl_st_rx_empty_128 <= 0;
            avl_st_rx_sop_128 <= 1'b0;
            avl_st_rx_eop_128 <= 1'b0;
        end
        @(posedge avl_st_rx_clk_128) begin
            avl_st_rx_data_128 <= 128'hffffeeeeddddcccc1234567812345678;
            avl_st_rx_val_128 <= 1;
            avl_st_rx_empty_128 <= 8;
            avl_st_rx_sop_128 <= 1'b0;
            avl_st_rx_eop_128 <= 1'b1;
        end

        @(posedge avl_st_rx_clk_128) begin
            avl_st_rx_data_128 <= 0;
            avl_st_rx_empty_128 <= 0;
            avl_st_rx_eop_128 <= 0;
            avl_st_rx_sop_128 <= 0;
            avl_st_rx_val_128 <= 0;
        end

        for (int j = 0; j < 4; j++) begin
            @(posedge avl_st_rx_clk_128);
        end
    end
end

enum logic {IDLE, GEN} state;
logic [147:0]   test_data_gen;
logic           test_fifo_wr;
logic [3:0]     test_cnt;
logic           test_data_gen_ena;
logic [147:0]   test_fifo_data_rd;
logic           test_fifo_rd;

initial begin
    test_data_gen_ena <= 0;
    #400;
    @(posedge avl_st_rx_clk_128) test_data_gen_ena <= 1;
    @(posedge avl_st_rx_clk_128) test_data_gen_ena <= 0;
end

always_ff @(posedge avl_st_rx_clk_128 or negedge avl_st_rx_rst_n_128) begin : proc_test_fifo
    if(~avl_st_rx_rst_n_128) begin
        test_data_gen <= 0;
         test_fifo_wr <= 0;
         test_cnt <= 0;
         state <= IDLE;
    end else begin
        test_fifo_wr <= 0;
         test_cnt <= 0;
        case(state)
            IDLE: begin
                if (test_data_gen_ena) begin
                    state <= GEN;
                    test_data_gen <= {128'h000102030405060708090a0b0c0d0e0f, 20'h1a1b1c1d1e};
                end
            end
            GEN: begin
                test_data_gen <= test_data_gen + {128'h10101010101010101010101010101010, 20'h1010101010};
                test_cnt <= test_cnt + 1'd1;
                test_fifo_wr <= 1;
                if (test_cnt == 4'hf) begin
                    state <= IDLE;
                end
            end
        endcase // state
    end
end


recv_data_buffer_128in_32out recv_data_buffer_128in_32out_inst
(

    .avl_st_rx_clk  (avl_st_rx_clk_128),
    .avl_st_rx_rst_n(avl_st_rx_rst_n_128),
    .avl_st_rx_data (avl_st_rx_data_128),
    .avl_st_rx_emp(avl_st_rx_empty_128),
    .avl_st_rx_eop  (avl_st_rx_eop_128),
    .avl_st_rx_error(avl_st_rx_error_128),
    .avl_st_rx_ready(avl_st_rx_ready_128),
    .avl_st_rx_sop  (avl_st_rx_sop_128),
    .avl_st_rx_val  (avl_st_rx_val_128),

    .crcbad_in      (),
    .crcvalid_in    (),

    .avl_st_tx_clk  (avl_st_tx_clk_32),
    .avl_st_tx_rst_n(avl_st_tx_rst_n_32),
    .avl_st_tx_data (avl_st_tx_data_32),
    .avl_st_tx_emp(avl_st_tx_empty_32),
    .avl_st_tx_eop  (avl_st_tx_eop_32),
    .avl_st_tx_ready(avl_st_tx_ready_32),
    .avl_st_tx_sop  (avl_st_tx_sop_32),
    .avl_st_tx_val  (avl_st_tx_val_32)
);


logic [127:0]     avl_st_tx_data_bridge;
logic [3:0]      avl_st_tx_empty_bridge;
logic            avl_st_tx_eop_bridge;
logic            avl_st_tx_ready_bridge = 1;
logic            avl_st_tx_sop_bridge;
logic            avl_st_tx_val_bridge;
avalon_bridge_32bit_to_128bit avalon_bridge_32bit_to_128bit_inst
(
    .avl_st_rx_clk  (mac_clk),
    .avl_st_rx_rst_n(mac_rst_n),
    .avl_st_rx_data (avl_st_tx_data_mac),
    .avl_st_rx_empty(avl_st_tx_empty_mac),
    .avl_st_rx_eop  (avl_st_tx_eop_mac),
    .avl_st_rx_ready(avl_st_tx_ready_mac),
    .avl_st_rx_sop  (avl_st_tx_sop_mac),
    .avl_st_rx_val  (avl_st_tx_val_mac),

    .avl_st_tx_clk  (avl_st_rx_clk_128),
    .avl_st_tx_rst_n(avl_st_rx_rst_n_128),
    .avl_st_tx_data (avl_st_tx_data_bridge),
    .avl_st_tx_empty(avl_st_tx_empty_bridge),
    .avl_st_tx_eop  (avl_st_tx_eop_bridge),
    .avl_st_tx_ready(avl_st_tx_ready_bridge),
    .avl_st_tx_sop  (avl_st_tx_sop_bridge),
    .avl_st_tx_val  (avl_st_tx_val_bridge)
    );
//-------------------------------------------------------------
localparam ADDR_WIDTH = 25;
localparam LEN_WIDTH = 8;
localparam DATA_WIDTH = 64;
logic                       usr_clk;
logic                       usr_rst_n;
logic [ADDR_WIDTH-1:0]      start_to_wr_addr_in;
logic [LEN_WIDTH-1:0]       bytes_to_write_in;
logic [DATA_WIDTH-1:0]      wr_data_in;
logic                       wr_valid_in;

logic                       rd_req_in;
logic [ADDR_WIDTH-1:0]      start_to_rd_addr_in;
logic [LEN_WIDTH-1:0]       bytes_to_read_in;
logic                       rddata_valid_out;
logic [DATA_WIDTH-1:0]      rddata_out;


        // DDR4 IP interface
logic             emif_clk;
logic             emif_rst_n;
logic             ddr_emif_ready;
logic [511:0]     ddr_emif_read_data;
logic             ddr_emif_rddata_valid;

logic            ddr_emif_read;
logic            ddr_emif_write;
logic [21:0]     ddr_emif_addr;
logic [511:0]    ddr_emif_write_data;
logic [63:0]     ddr_emif_byte_enable;
logic [6:0]      ddr_emif_burst_count;


initial begin
    usr_clk = 0;
    forever begin
        #2 usr_clk = ~usr_clk;

    end
end

initial begin
    emif_clk = 0;
    #3;
    forever begin
        #4 emif_clk = ~emif_clk;
    end
end

initial begin
    usr_rst_n = 1;
    #80;
    usr_rst_n = 0;
    #10;
    usr_rst_n =1;
end
initial begin
    emif_rst_n = 1;
    #90;
    emif_rst_n = 0;
    #10;
    emif_rst_n =1;
end

parameter NUM = 25;
integer len[NUM] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25};


initial begin
    start_to_wr_addr_in = 0;
    bytes_to_write_in = 0;
    wr_valid_in = 0;
    wr_data_in = 0;
    rd_req_in = 0;
    start_to_rd_addr_in = 0;
    bytes_to_read_in = 0;

    #200;

    for (int k = 0; k < NUM; k++) begin
        @(posedge usr_clk) begin
            start_to_wr_addr_in <= 'h10;
            bytes_to_write_in <= len[k];
            wr_data_in <= 'h0001020304050607;
            wr_valid_in <= 1;
        end
        for (int i = 0; i < (bytes_to_write_in - 1); i++) begin
            @(posedge usr_clk) begin
                wr_data_in <= wr_data_in + 'h0808080808080808;
            end
        end
        @(posedge usr_clk);
        start_to_wr_addr_in <= 0;
        bytes_to_write_in <= 0;
        wr_valid_in <= 0;
        #200;
    end


    @(posedge usr_clk);
    rd_req_in <= 1;
    start_to_rd_addr_in <= 'h16;
    bytes_to_read_in <= 2;

    @(posedge usr_clk);
    rd_req_in <= 0;
    start_to_rd_addr_in <= 'h0;
    bytes_to_read_in <= 0;

    #100;
    @(posedge usr_clk);
    rd_req_in <= 1;
    start_to_rd_addr_in <= 'h40;
    bytes_to_read_in <= 12;

    @(posedge usr_clk);
    rd_req_in <= 0;
    start_to_rd_addr_in <= 'h0;
    bytes_to_read_in <= 0;

    #100;
    @(posedge usr_clk);
    rd_req_in <= 1;
    start_to_rd_addr_in <= 'h40;
    bytes_to_read_in <= 1;

    @(posedge usr_clk);
    rd_req_in <= 0;
    start_to_rd_addr_in <= 'h0;
    bytes_to_read_in <= 0;

end


always @(posedge emif_clk) begin
    if (~emif_rst_n) begin
        ddr_emif_read_data <= 64'h0;
        ddr_emif_rddata_valid <= 1;
    end
    if(ddr_emif_read) begin
        ddr_emif_read_data[511:256] <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        ddr_emif_read_data[255:0] <= 256'h202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f;
        ddr_emif_rddata_valid <= 1;
    end
    else begin
        ddr_emif_read_data <= 64'h0;
        ddr_emif_rddata_valid <= 0;
    end
end

emif_buffer emif_buffer_i(
    .usr_clk              (usr_clk),
    .usr_rst_n            (usr_rst_n),
    .start_to_wr_addr_in  (start_to_wr_addr_in),
    .bytes_to_write_in    (bytes_to_write_in),
    .wr_req_in            (wr_req_in),
    .wr_data_in           (wr_data_in),
    .wr_valid_in          (wr_valid_in),

    .rd_req_in            (rd_req_in),
    .start_to_rd_addr_in  (start_to_rd_addr_in),
    .bytes_to_rd_in       (bytes_to_read_in),
    .rddata_valid_out     (rddata_valid_out),
    .rddata_out           (rddata_out),

    .emif_clk             (emif_clk),
    .emif_rst_n           (emif_rst_n),
    .ddr_emif_ready       (ddr_emif_ready),
    .ddr_emif_read_data   (ddr_emif_read_data),
    .ddr_emif_rddata_valid(ddr_emif_rddata_valid),
    .ddr_emif_read        (ddr_emif_read),
    .ddr_emif_write       (ddr_emif_write),
    .ddr_emif_addr        (ddr_emif_addr),
    .ddr_emif_write_data  (ddr_emif_write_data),
    .ddr_emif_byte_enable (ddr_emif_byte_enable),
    .ddr_emif_burst_count (ddr_emif_burst_count)
    );


        // DDR3 IP interface
logic               ddr3_emif_ready;
logic [255:0]       ddr3_emif_read_data;
logic               ddr3_emif_rddata_valid;

logic               ddr3_emif_read;
logic               ddr3_emif_write;
logic [21:0]        ddr3_emif_addr;
logic [255:0]       ddr3_emif_write_data;
logic [31:0]        ddr3_emif_byte_enable;
logic [4:0]         ddr3_emif_burst_count;
// The user data with is 32-bit
ddr3_emif_buffer ddr3_emif_buffer_i(
    .usr_clk              (usr_clk),
    .usr_rst_n            (usr_rst_n),
    .start_to_wr_addr_in  (start_to_wr_addr_in),
    .bytes_to_write_in    (bytes_to_write_in),
    //.wr_req_in            (wr_req_in),
    .wr_data_in           (wr_data_in[31:0]),
    .wr_valid_in          (wr_valid_in),

    .rd_req_in            (rd_req_in),
    .start_to_rd_addr_in  (start_to_rd_addr_in),
    .bytes_to_rd_in       (bytes_to_read_in),
    .rddata_valid_out     (rddata_valid_out),
    .rddata_out           (rddata_out),

    .ddr_emif_clk             (emif_clk),
    .ddr_emif_rst_n           (emif_rst_n),
    .ddr_emif_ready       (ddr3_emif_ready),
    .ddr_emif_read_data   (ddr3_emif_read_data),
    .ddr_emif_rddata_valid(ddr3_emif_rddata_valid),
    .ddr_emif_read        (ddr3_emif_read),
    .ddr_emif_write       (ddr3_emif_write),
    .ddr_emif_addr        (ddr3_emif_addr),
    .ddr_emif_write_data  (ddr3_emif_write_data),
    .ddr_emif_byte_enable (ddr3_emif_byte_enable),
    .ddr_emif_burst_count (ddr3_emif_burst_count)
);

always @(posedge emif_clk) begin
    if (~emif_rst_n) begin
        ddr3_emif_read_data <= 0;
        ddr3_emif_rddata_valid <= 1;
    end
    if(ddr3_emif_read) begin
        //ddr_emif_read_data[512:256] <= 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        ddr3_emif_read_data[255:0] <= 256'h202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f;
        ddr3_emif_rddata_valid <= 1;
    end
    else begin
        ddr3_emif_read_data <= 0;
        ddr3_emif_rddata_valid <= 0;
    end
end

//-------------------------------------- testbench of data_pool.sv -------------------------
localparam CH_NUM = 3;
logic pool_clk, pool_rst_n;
logic [CH_NUM-1:0][31:0]    pool_data_in, pool_data_out;
logic [CH_NUM-1:0]          pool_valid_in, pool_sop_in, pool_eop_in, pool_valid_out, pool_sop_out, pool_eop_out, pool_ready_out, pool_ready_in;

initial begin
    pool_clk = 0;
    forever begin
        #2.5 pool_clk = ~pool_clk;
    end
end

initial begin
    pool_rst_n = 1;
    #60;
    pool_rst_n = 0;
    #20;
    pool_rst_n = 1;
end

genvar m;
generate
    for (m = 0; m < CH_NUM; m++) begin

        initial begin
            pool_data_in[m] = 0;
            pool_valid_in[m] = 0;
            pool_sop_in[m] = 0;
            pool_eop_in[m] = 0;


            #700;

            @(posedge pool_clk) begin
                pool_valid_in[m] <= 1;
                pool_sop_in[m] <= 1;
                pool_data_in[m] <= 32'h00010203;
            end

            for(int k = 0; k < 30; k++) begin
                @(posedge pool_clk) begin
                    pool_data_in[m] <= pool_data_in[m] + 32'h04050607;
                     pool_sop_in[m] <= 0;
                end
            end

            @(posedge pool_clk) begin
                pool_valid_in[m] <= 1;
                pool_eop_in[m] <= 1;
                pool_data_in[m] <= pool_data_in[m] + 32'h04050607;
            end
            @(posedge pool_clk) begin
                pool_valid_in[m] <= 0;
                pool_sop_in[m] <= 0;
                pool_data_in[m] <= 0;
                pool_eop_in[m] <= 0;
            end

            #700;
            @(posedge pool_clk) begin
                pool_valid_in[m] <= 1;
                pool_sop_in[m] <= 1;
                pool_data_in[m] <= 32'h00010203;
            end

            for(int k = 0; k < 30; k++) begin
                @(posedge pool_clk) begin
                    pool_data_in[m] <= pool_data_in[m] + 32'h04050607;
                     pool_sop_in[m] <= 0;
                end
            end

            @(posedge pool_clk) begin
                pool_valid_in[m] <= 1;
                pool_eop_in[m] <= 1;
                pool_data_in[m] <= pool_data_in[m] + 32'h04050607;
            end
            @(posedge pool_clk) begin
                pool_valid_in[m] <= 0;
                pool_sop_in[m] <= 0;
                pool_data_in[m] <= 0;
                pool_eop_in[m] <= 0;
            end
        end
    end
endgenerate

initial begin
     pool_ready_in = 0;

     #180;
     pool_ready_in[0] = 1;
     #20;
     pool_ready_in[1] = 1;
 end



data_pool #(CH_NUM)
data_pool_inst (
    .clk     (pool_clk),
    .rst_n   (pool_rst_n),
    .data_in (pool_data_in),
    .valid_in(pool_valid_in),
    .sop_in  (pool_sop_in),
    .eop_in  (pool_eop_in),
    .ready_o (pool_ready_out),

    .data_o  (pool_data_out),
    .valid_o (pool_valid_out),
    .sop_o   (pool_sop_out),
    .eop_o   (pool_eop_out),
    .ready_in(pool_ready_in)

    );

//------------------------------------------------
pattern_fetch_send_tb pattern_fetch_send_tb_inst();

// ------------ Test fast_pat_fetch --------------
fast_pat_tb fast_pat_tb_inst();

logic       fast_pat_clk;
logic       fast_pat_rst_n;


logic       hsync_o_with_camera_format;//active high
logic       vsync_o_with_camera_format;//active low
logic       de_o;//active high

logic         hsync_o_with_hdmi_format;
logic         vsync_o_with_hdmi_format;
logic         de_o_with_hdmi_format;

logic           de_o_first_offset_line;
logic [23:0]    display_vedio_left_offset;

logic           frame_start_trig;//a
logic           frame_busy;

logic       frame_all_zeros;//we have to send all zero frame during acqisitaion, high active (captured at the edge of frame_start_trig)
logic       de_with_all_zeros;

logic       dmd_correct_15_pixles_slope;//added by wdf @2014/11/03 dmd_correct_15_pixles_slope==1'b1 the display will compensate the slope
logic       dmd_flip_left_and_right;//flip left and right //left right flip: flip first, the correct the 15 pixels == correct the -15 pixels and then flip

logic        [10:0] frame_count;

initial begin
    fast_pat_clk = 0;
    forever begin
        #3.267 fast_pat_clk = ~fast_pat_clk;
    end
end

initial begin
    fast_pat_rst_n = 1;
    #60 fast_pat_rst_n = 0;
    #40;
    fast_pat_rst_n = 1;
end
initial begin
    frame_start_trig <= 0;
    frame_all_zeros <= 0;
    dmd_correct_15_pixles_slope <= 0;
    dmd_flip_left_and_right <= 0;

    #100;
    @(posedge fast_pat_clk) begin
        frame_start_trig <= 1;
    end

    @(posedge fast_pat_clk) begin
        frame_start_trig <= 0;
    end
end



display_vedio_generate_DMD_specific_faster display_vedio_generate_DMD_specific_faster_inst (
    .clk_i                      (fast_pat_clk),
    .rst_ni                     (fast_pat_rst_n),
    .hsync_o_with_camera_format (hsync_o_with_camera_format),
    .vsync_o_with_camera_format (vsync_o_with_camera_format),
    .de_o                       (de_o),
    .hsync_o_with_hdmi_format   (hsync_o_with_hdmi_format),
    .vsync_o_with_hdmi_format   (vsync_o_with_hdmi_format),
    .de_o_with_hdmi_format      (de_o_with_hdmi_format),
    .de_o_first_offset_line     (de_o_first_offset_line),
    .display_vedio_left_offset  (display_vedio_left_offset),
    .frame_start_trig           (frame_start_trig),
    .frame_busy                 (frame_busy),
    .frame_all_zeros            (frame_all_zeros),
    .de_with_all_zeros          (de_with_all_zeros),
    .dmd_correct_15_pixles_slope(dmd_correct_15_pixles_slope),
    .dmd_flip_left_and_right    (dmd_flip_left_and_right),
    .frame_count                (frame_count)
    );

//---------------------------------------------------------------------

endmodule