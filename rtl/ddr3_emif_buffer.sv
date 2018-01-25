
//  Logic address = {ddr_emif_addr,3'bxxx} , 3'bxxx represents sub_addr
// 0x000000xxx        | <--------------------------- 512 bits --------------------------------------->|
//                     -------------------------------------------------------------------------------
//ddr_emif_addr[24:0] |sub_addr0|sub_addr1|sub_addr2|sub_addr3|sub_addr4|sub_addr5|sub_addr6|sub_addr7|

// Implement the maping relationship between user logic data acess and the physical DDR
// Support consective write
// Support 256-bit read
module ddr3_emif_buffer # (
    parameter       ADDR_WIDTH = 25,
    parameter       DDR3_USR_DATA_WIDTH = 32,
    parameter       LEN_WIDTH = 8,
    parameter       DDR3_PHY_DATA_WIDTH = 256
)
(
input logic                             usr_clk,
input logic                             usr_rst_n,
input logic [ADDR_WIDTH-1:0]            start_to_wr_addr_in,
input logic [LEN_WIDTH-1:0]             bytes_to_write_in,
//logic                                   wr_req_in,
input logic [DDR3_USR_DATA_WIDTH-1:0]   wr_data_in,
input logic                             wr_valid_in,

input logic                             rd_req_in,
input logic [ADDR_WIDTH-1:0]            start_to_rd_addr_in,
input logic [LEN_WIDTH-1:0]             bytes_to_rd_in,
output logic                            rddata_valid_out,
output logic [DDR3_USR_DATA_WIDTH-1:0]  rddata_out,

// DDR3 IP interface
input logic                             ddr_emif_clk,
input logic                             ddr_emif_rst_n,
input logic                             ddr_emif_ready,
input logic [DDR3_PHY_DATA_WIDTH-1:0]   ddr_emif_read_data,
input logic                             ddr_emif_rddata_valid,

output logic                            ddr_emif_read,
output logic                            ddr_emif_write,
output logic [21:0]                     ddr_emif_addr,
output logic [DDR3_PHY_DATA_WIDTH-1:0]  ddr_emif_write_data,
output logic [DDR3_PHY_DATA_WIDTH/8-1:0]ddr_emif_byte_enable,
output logic [4:0]                      ddr_emif_burst_count
);

localparam TIMES = DDR3_PHY_DATA_WIDTH/DDR3_USR_DATA_WIDTH;
logic [ADDR_WIDTH-1:0]  start_wr_addr_r1;
logic [LEN_WIDTH-1:0]   byte_length_r1, byte_length_r2;
logic [LEN_WIDTH-1:0]   byte_counter;
logic [DDR3_USR_DATA_WIDTH-1:0]  wr_data_r1, wr_data_r2, wr_data_r3, wr_data_r4;

logic                   fifo_wr_clk, fifo_wr_ena, fifo_full;
logic                   fifo_rd_clk, fifo_rd_ena, fifo_empty;
logic [DDR3_USR_DATA_WIDTH:0]  fifo_wr_data, fifo_rd_data;
enum logic [3:0] {WR_IDLE, WR_ADDR, WR_LENGTH, WR_DATA, RD_ADDR, RD_LENGTH} cs, ns;
//---------------- User read interface ---------------------------------------
logic [ADDR_WIDTH-1:0]      start_rd_addr_r1;
logic [LEN_WIDTH-1:0]       usr_rd_len_r1, usr_rd_len_r2;


//------------------------- User write operation logics --------------------------
always_comb begin : proc_fifo_wr
    fifo_wr_clk = usr_clk;
end

always_ff @(posedge usr_clk) begin : proc_buffer
    if(~usr_rst_n) begin
        start_wr_addr_r1 <= 0;
        start_rd_addr_r1 <= 0;
        {byte_length_r2, byte_length_r1} <= 0;
        {usr_rd_len_r2, usr_rd_len_r1} <= 0;
        wr_data_r4 <= 0;
        wr_data_r3 <= 0;
        wr_data_r2 <= 0;
        wr_data_r1 <= 0;
    end else begin
        start_wr_addr_r1 <= start_to_wr_addr_in;
        start_rd_addr_r1 <= start_to_rd_addr_in;
        byte_length_r1 <= bytes_to_write_in;
        byte_length_r2 <= byte_length_r1;
        usr_rd_len_r1 <= bytes_to_rd_in;
        usr_rd_len_r2 <= usr_rd_len_r1;
        {wr_data_r4, wr_data_r3, wr_data_r2, wr_data_r1} <= {wr_data_r3, wr_data_r2, wr_data_r1, wr_data_in};
    end
end

always_ff @(posedge usr_clk) begin : proc_state
    if(~usr_rst_n) begin
        cs <= WR_IDLE;
    end else begin
        cs <= ns;
    end
end

always_comb begin : proc_state_update
    case(cs)
        WR_IDLE: begin
            if (wr_valid_in) begin
                ns = WR_ADDR;
            end
            else if (rd_req_in) begin
                ns = RD_ADDR;
            end
            else begin
                ns = WR_IDLE;
            end
        end
        WR_ADDR: ns = WR_LENGTH;
        WR_LENGTH: ns = WR_DATA;
        WR_DATA:begin
            if (byte_counter == 1) begin
                ns = WR_IDLE;
            end
            else begin
                ns =WR_DATA;
            end
        end
        RD_ADDR: ns = RD_LENGTH;
        RD_LENGTH: ns = WR_IDLE;
        default: ns = WR_IDLE;
    endcase // cs
end

always_ff @(posedge usr_clk) begin : proc_byte_counter
    if(~usr_rst_n) begin
         byte_counter <= 0;
    end else begin
         if(cs == WR_LENGTH) begin
            byte_counter <= byte_length_r2;
        end
        else if (cs == WR_DATA) begin
            byte_counter <= byte_counter - 1'd1;
        end
    end
end

always_ff @(posedge usr_clk) begin : proc_wr_fifo
    case(cs)
        WR_IDLE: begin
            fifo_wr_ena <= 0;
            fifo_wr_data <= 0;
        end
        WR_ADDR: begin
            fifo_wr_ena <= 1;
            fifo_wr_data <= {start_wr_addr_r1, 1'b1}; // The last bit '1' represents WRITE
        end
        WR_LENGTH: begin
            fifo_wr_ena <= 1;
            fifo_wr_data <= {byte_length_r2, 1'b1};
        end
        WR_DATA: begin
            fifo_wr_ena <= 1;
            fifo_wr_data <= {wr_data_r3, 1'b1};
        end
        RD_ADDR: begin
            fifo_wr_ena <= 1;
            fifo_wr_data <= {start_rd_addr_r1, 1'b0};
        end
        RD_LENGTH: begin
            fifo_wr_ena <= 1;
            fifo_wr_data <= {usr_rd_len_r2, 1'b0};
        end
        default: begin
            fifo_wr_ena <= 0;
            fifo_wr_data <= 0;
        end
    endcase
end
//--------------------------- User reads FIFO operation --------------------------------------
logic [1:0]                     fifo_rd_cnt;
logic [ADDR_WIDTH-1:0]          start_wr_addr_emif;
logic [21:0]                    ddr_emif_wr_addr;
logic [LEN_WIDTH-1:0]           bytes_to_write_emif;
logic                           emif_wr;
logic [ADDR_WIDTH-1:0]          start_rd_addr_emif, ddr_emif_rd_addr;
logic [LEN_WIDTH-1:0]           bytes_to_read_emif;
logic [4:0]                     rd_burst_len;
logic [3:0]                     rd_burst_remain;

logic [0:7][DDR3_USR_DATA_WIDTH-1:0]     data_emif_r;
logic [DDR3_USR_DATA_WIDTH-1:0]          data_emif;
logic [2:0]                     byte8_cnt;
logic                           data_last, data_first, data_first_flag, data_body;
logic [ADDR_WIDTH-1-3:0]        addr_emif_inc;

enum logic [2:0] {IDLE, ADDR, LENGTH, READ, DATA} emif_cs, emif_ns;

always_comb begin : proc_fifo_rd
    fifo_rd_ena = ~fifo_empty;
    fifo_rd_clk = ddr_emif_clk;
end

// Control the FIFO read operation
always_ff @(posedge ddr_emif_clk) begin : proc_fifo_rd_ctrl
    if(~ddr_emif_rst_n) begin
        fifo_rd_cnt <= 0;
        start_wr_addr_emif <= 0;
        bytes_to_write_emif <= 0;
        data_emif <= 0;
        emif_wr <= 0;
        rd_burst_remain <= 0;
    end else begin
            case(emif_cs)
                IDLE: begin
                    fifo_rd_cnt <= fifo_rd_cnt + 1'd1;
                    if (fifo_rd_ena) emif_cs <= ADDR;
                        emif_wr <= 0;
                        rd_burst_remain <= 0;
                end
                ADDR: begin
                    start_wr_addr_emif <= fifo_rd_data[0] ? fifo_rd_data[ADDR_WIDTH:1] : 0;
                    start_rd_addr_emif <= (~fifo_rd_data[0]) ? fifo_rd_data[ADDR_WIDTH:1] : 0;
                    emif_wr <= fifo_rd_data[0];
                    if (fifo_rd_ena) emif_cs <= LENGTH;

                end
                LENGTH: begin
                    bytes_to_write_emif <= fifo_rd_data[0] ? fifo_rd_data[LEN_WIDTH:1] : 0;
                    bytes_to_read_emif <= (~fifo_rd_data[0]) ? fifo_rd_data[LEN_WIDTH:1] : 0;
                    if (fifo_rd_data[0]) begin
                        emif_cs <= DATA;
                    end
                    else begin
                        emif_cs <= READ;
                    end
                end
                READ: emif_cs <= IDLE;

                DATA: begin
                    data_emif <= fifo_rd_data[DDR3_USR_DATA_WIDTH:1];
                    if (bytes_to_write_emif == 1) begin
                        emif_cs <= IDLE;
                    end
                    else begin
                        bytes_to_write_emif <= bytes_to_write_emif - 1'd1;
                    end
                end
                default: begin
                    emif_cs <= IDLE;
                end
            endcase
        end
end

//------------------------- emif Read -------------------------
logic [7:0] read_byte_enable_head, read_byte_enable_body, read_byte_enable_tail;

always_ff @(posedge ddr_emif_clk) begin : proc_emif_rd
    if(~ddr_emif_rst_n) begin
         ddr_emif_read <= 0;
         ddr_emif_burst_count <= 0;
         ddr_emif_rd_addr <= 0;
    end else begin
        if (emif_cs == READ) begin
            ddr_emif_read <= 1;
            ddr_emif_rd_addr <= start_rd_addr_emif[ADDR_WIDTH-1:3];
        end
        else begin
            ddr_emif_read <= 0;
        end
    end
end

logic                   rdfifo_wr_ena, rdfifo_full;
logic                   rdfifo_rd_ena, rdfifo_empty;
logic [DDR3_PHY_DATA_WIDTH-1:0 ]          rdfifo_wr_data;
logic [DDR3_USR_DATA_WIDTH-1:0]  rdfifo_rd_data;
logic                   rdfifo_rd_valid;
logic [3:0]             rdfifo_rd_cnt;

always_ff @(posedge ddr_emif_clk) begin : proc_rdfifo_wr
    if(~ddr_emif_rst_n) begin
        rdfifo_wr_ena <= 0;
    end else begin
        // rdfifo full should never happens
        rdfifo_wr_ena <= ddr_emif_rddata_valid;
        // Big-Edian
        for (int i = 0; i < TIMES; i++) begin
            rdfifo_wr_data[i*DDR3_USR_DATA_WIDTH+:DDR3_USR_DATA_WIDTH] <= ddr_emif_read_data[(TIMES-1-i)*DDR3_USR_DATA_WIDTH+:DDR3_USR_DATA_WIDTH];
        end
    end
end

always_comb begin : proc_rdfifo_rd_ena
    rdfifo_rd_ena = ~rdfifo_empty;
end

// Ouptut the disired data
always_ff @(posedge usr_clk) begin : proc_rdfifo_rd
    if(~usr_rst_n) begin
        rdfifo_rd_valid <= 0;
        rdfifo_rd_cnt <= 0;
        rddata_valid_out <= 0;
        rddata_out <= 0;
    end else begin
        rdfifo_rd_valid <= rdfifo_rd_ena;
        if (rdfifo_rd_valid) begin
            rdfifo_rd_cnt <= rdfifo_rd_cnt + 1'd1;
        end
        else begin
            rdfifo_rd_cnt <= 0;
        end

        // start_rd_addr_emif and bytes_to_read_emif should keep unchange before next read operation
        if (rdfifo_rd_cnt == start_rd_addr_emif[2:0] && rdfifo_rd_valid) begin
            rddata_valid_out <= 1;
        end
        else if (rdfifo_rd_cnt == (start_rd_addr_emif[2:0] + bytes_to_read_emif)) begin
            rddata_valid_out <= 0;
        end
        else if (~rdfifo_rd_valid) begin
            rddata_valid_out <= 0;
        end

        rddata_out <= rdfifo_rd_data;
    end
end

fifo_256in_32out fifo_256in_32out_inst (
    .data    (rdfifo_wr_data),    //  fifo_input.datain
    .wrreq   (rdfifo_wr_ena),   //            .wrreq
    .rdreq   (rdfifo_rd_ena),   //            .rdreq
    .wrclk   (ddr_emif_clk),   //            .wrclk
    .rdclk   (usr_clk),   //            .rdclk
    .q       (rdfifo_rd_data),       // fifo_output.dataout
    .rdempty (rdfifo_empty), //            .rdempty
    .wrfull  (rdfifo_full)   //            .wrfull
    );


// ------------------------------ emif_addr MUX -------------------------
always_comb begin : proc_emif_addr
    if(ddr_emif_write) begin
        ddr_emif_addr = ddr_emif_wr_addr;
    end
    else if (ddr_emif_read) begin
        ddr_emif_addr = ddr_emif_rd_addr;
    end
    else begin
        ddr_emif_addr = 0;
    end
end

//---------------------------- emif write ------------------------------
// r[7] <- r[6] <- ... <- r[0]
// Data format is Big-Edian, r[0] is MSB
always_ff @(posedge ddr_emif_clk) begin : proc_emif_data_buffer
    if(~ddr_emif_rst_n) begin
         for (int i = 0; i < 8; i++) begin
            data_emif_r[i] <= 0;
        end
    end else begin
         for (int i = 0; i < 7; i++) begin
            data_emif_r[i+1] <= data_emif_r[i];
        end
        data_emif_r[0] <= fifo_rd_data[DDR3_USR_DATA_WIDTH:1];
    end
end

always_ff @(posedge ddr_emif_clk) begin : proc_byte8_cnt
    if(~ddr_emif_rst_n) begin
         byte8_cnt <= 0;
         data_first_flag <= 0;
    end else begin
        if (emif_cs == LENGTH && emif_wr) begin
            byte8_cnt <= start_wr_addr_emif[2:0];
            data_first_flag <= 1;
        end
        else if (emif_cs == DATA) begin
            byte8_cnt <= byte8_cnt + 1'd1;
        end
        else begin
            byte8_cnt <= 0;
        end

        if (byte8_cnt == 7) begin
            data_first_flag <= 0;
        end
    end
end

always_ff @(posedge ddr_emif_clk) begin : proc_addr_emif
    if(~ddr_emif_rst_n ||  data_last) begin
        addr_emif_inc <= 0;
    end else begin
        //if (ddr_emif_write || data_last) begin
        if (data_body || data_first) begin
            addr_emif_inc <= addr_emif_inc + 1'd1;
        end
    end
end

always_ff @(posedge ddr_emif_clk) begin : proc_emif
    if (~ddr_emif_rst_n) begin
        ddr_emif_wr_addr <= 0;
        ddr_emif_write <= 0;
        ddr_emif_byte_enable <= 0;
    end
    else begin
        ddr_emif_wr_addr <= 0;
        ddr_emif_write <= 0;
        ddr_emif_byte_enable <= 0;

        for (int i = 0; i < TIMES; i++) begin
            ddr_emif_write_data[i*DDR3_USR_DATA_WIDTH+:DDR3_USR_DATA_WIDTH] <= data_emif_r[i];
        end
        if (data_first) begin
            ddr_emif_wr_addr <= start_wr_addr_emif[ADDR_WIDTH-1:3];
            ddr_emif_write <= 1;
            case(start_wr_addr_emif[2:0])
                3'd0: ddr_emif_byte_enable <= {8{4'hf}};
                3'd1: ddr_emif_byte_enable <= {{1{4'h0}},{7{4'hf}}};
                3'd2: ddr_emif_byte_enable <= {{2{4'h0}},{6{4'hf}}};
                3'd3: ddr_emif_byte_enable <= {{3{4'h0}},{5{4'hf}}};
                3'd4: ddr_emif_byte_enable <= {{4{4'h0}},{4{4'hf}}};
                3'd5: ddr_emif_byte_enable <= {{5{4'h0}},{3{4'hf}}};
                3'd6: ddr_emif_byte_enable <= {{6{4'h0}},{2{4'hf}}};
                3'd7: ddr_emif_byte_enable <= {{7{4'h0}},{1{4'hf}}};
            endcase // start_wr_addr_emif[2:0]
        end
        else if (data_body) begin
            ddr_emif_byte_enable <= {8{4'hf}};
            ddr_emif_write <= 1;
            ddr_emif_wr_addr <= start_wr_addr_emif[ADDR_WIDTH-1:3] + addr_emif_inc;
        end
        else if (data_last) begin
            ddr_emif_write <= 1;
            ddr_emif_wr_addr <= start_wr_addr_emif[ADDR_WIDTH-1:3] + addr_emif_inc;
        // Big-Edian results in the data starts from the most-left side
            case(byte8_cnt)
                3'd0: begin
                    ddr_emif_byte_enable <= 'h0;
                end
                3'd1: begin
                    ddr_emif_byte_enable <= {{1{4'hf}}, {7{4'h0}}};
                    for (int i = 7; i >=7; i--) begin
                         ddr_emif_write_data[i*DDR3_USR_DATA_WIDTH+:DDR3_USR_DATA_WIDTH] <= data_emif_r[i-7];
                    end
                end
                3'd2: begin
                    ddr_emif_byte_enable <= {{2{4'hf}}, {6{4'h0}}};
                    for (int i = 7; i >= 6; i--) begin
                        ddr_emif_write_data[i*DDR3_USR_DATA_WIDTH+:DDR3_USR_DATA_WIDTH] <= data_emif_r[i-6];
                    end
                end
                3'd3: begin
                    ddr_emif_byte_enable <= {{3{4'hf}}, {5{4'h0}}};
                    for (int i = 7; i >= 5; i--) begin
                        ddr_emif_write_data[i*DDR3_USR_DATA_WIDTH+:DDR3_USR_DATA_WIDTH] <= data_emif_r[i-5];
                    end
                end
                3'd4: begin
                    ddr_emif_byte_enable <= {{4{4'hf}}, {4{4'h0}}};
                    for (int i = 7; i >= 4; i--) begin
                        ddr_emif_write_data[i*DDR3_USR_DATA_WIDTH+:DDR3_USR_DATA_WIDTH] <= data_emif_r[i-4];
                    end
                end
                3'd5: begin
                    ddr_emif_byte_enable <= {{5{4'hf}}, {3{4'h0}}};
                    for (int i = 7; i >= 3; i--) begin
                        ddr_emif_write_data[i*DDR3_USR_DATA_WIDTH+:DDR3_USR_DATA_WIDTH] <= data_emif_r[i-3];
                    end
                end
                3'd6: begin
                    ddr_emif_byte_enable <= {{6{4'hf}}, {2{4'h0}}};
                    for (int i = 7; i >= 2; i--) begin
                        ddr_emif_write_data[i*DDR3_USR_DATA_WIDTH+:DDR3_USR_DATA_WIDTH] <= data_emif_r[i-2];
                    end
                end
                3'd7: begin
                    ddr_emif_byte_enable <= {{7{4'hf}}, {1{4'h0}}};
                    for (int i = 7; i >= 1; i--) begin
                        ddr_emif_write_data[i*DDR3_USR_DATA_WIDTH+:DDR3_USR_DATA_WIDTH] <= data_emif_r[i-1];
                    end
                end
            endcase // byte8_cnt
        end
    end
end

always_ff @(posedge ddr_emif_clk) begin
    if (~ddr_emif_rst_n) begin
        data_last <= 0;
        data_body <= 0;
        data_first <= 0;
    end
    else begin
        data_last <= (bytes_to_write_emif == 1 && emif_cs == DATA) & ~data_last;
        data_first <= 0;
        data_body <= 0;
        if (byte8_cnt == 4'd7 && data_first_flag && emif_cs == DATA) begin
            data_first <= 1;
        end
        else if (byte8_cnt == 7 && emif_cs == DATA) begin
            data_body <= 1;
        end
    end
end

always @(posedge ddr_emif_clk) begin
    if(ddr_emif_write) begin
        $display("$time: DDR3 write addr is %x, write_data is %x.\n", ddr_emif_addr, ddr_emif_write_data);
        $display("$time: DDR3 byte write enable is %x.\n", ddr_emif_byte_enable);
    end

    if (ddr_emif_read) begin
        $display("$time: DDR3 read address is 0x%x, read burst is %d.\n", ddr_emif_rd_addr, ddr_emif_burst_count);
    end
end

dcfifo_33inx256 dcfifo_33inx256_inst (
    .wrclk(fifo_wr_clk),
    .wrreq(fifo_wr_ena),
    .data(fifo_wr_data),
    .wrfull(fifo_full),

    .rdclk(fifo_rd_clk),
    .rdreq(fifo_rd_ena),
    .rdempty(fifo_empty),
    .q(fifo_rd_data)
);

endmodule