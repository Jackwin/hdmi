
//  Logic address = {ddr_emif_addr,3'bxxx} , 3'bxxx represents sub_addr
// 0x000000xxx        | <--------------------------- 512 bits --------------------------------------->|
//                     -------------------------------------------------------------------------------
//ddr_emif_addr[24:0] |sub_addr0|sub_addr1|sub_addr2|sub_addr3|sub_addr4|sub_addr5|sub_addr6|sub_addr7|

//
module emif_buffer # (
    parameter       ADDR_WIDTH = 25,
    parameter       DATA_WIDTH = 64,
    parameter       LEN_WIDTH = 8
)
(
    input logic                     usr_clk,
    input logic                     usr_rst_n,
    input logic [ADDR_WIDTH-1:0]    start_to_wr_addr_in,
    input logic [LEN_WIDTH-1:0]     bytes_to_write_in,
    logic                           wr_req_in,
    input logic [DATA_WIDTH-1:0]    wr_data_in,
    input logic                     wr_valid_in,

    input logic                     rd_req_in,
    input logic [ADDR_WIDTH-1:0]    start_to_rd_addr_in,
    input logic [LEN_WIDTH-1:0]     bytes_to_rd_in,
    output logic                    rddata_valid_out,
    output logic [DATA_WIDTH-1:0]   rddata_out,

        // DDR4 IP interface
    input logic             emif_clk,
    input logic             emif_rst_n,
    input logic             ddr_emif_ready,
    input logic [511:0]     ddr_emif_read_data,
    input logic             ddr_emif_rddata_valid,

    output logic            ddr_emif_read,
    output logic            ddr_emif_write,
    output logic [21:0]     ddr_emif_addr,
    output logic [511:0]    ddr_emif_write_data,
    output logic [63:0]     ddr_emif_byte_enable,
    output logic [6:0]      ddr_emif_burst_count
);

logic [ADDR_WIDTH-1:0]  start_wr_addr_r1,  start_wr_addr_r3;
logic [LEN_WIDTH-1:0]   byte_length_r1, byte_length_r2;
logic [LEN_WIDTH-1:0]   byte_counter;
logic [DATA_WIDTH-1:0]  wr_data_r1, wr_data_r2, wr_data_r3, wr_data_r4;

logic                   fifo_wr_clk, fifo_wr_ena, fifo_full;
logic                   fifo_rd_clk, fifo_rd_ena, fifo_empty;
logic [DATA_WIDTH:0]  fifo_wr_data, fifo_rd_data;
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

always_comb begin : proc_wr_fifo
    case(cs)
        WR_IDLE: begin
            fifo_wr_ena = 0;
            fifo_wr_data = 0;
        end
        WR_ADDR: begin
            fifo_wr_ena = 1;
            fifo_wr_data = {start_wr_addr_r1, 1'b1}; // The last bit '1' represents WRITE
        end
        WR_LENGTH: begin
            fifo_wr_ena = 1;
            fifo_wr_data = {byte_length_r2, 1'b1};
        end
        WR_DATA: begin
            fifo_wr_ena = 1;
            fifo_wr_data = {wr_data_r3, 1'b1};
        end
        RD_ADDR: begin
            fifo_wr_ena = 1;
            fifo_wr_data = {start_rd_addr_r1, 1'b0};
        end
        RD_LENGTH: begin
            fifo_wr_ena = 1;
            fifo_wr_data = {usr_rd_len_r2, 1'b0};
        end
        default: begin
            fifo_wr_ena = 0;
            fifo_wr_data = 0;
        end
    endcase
end

//-----------------------------------------------------------------
logic [1:0]                     fifo_rd_cnt;
logic [ADDR_WIDTH-1:0]          start_wr_addr_emif, ddr_emif_wr_addr;
logic [LEN_WIDTH-1:0]           bytes_to_write_emif;
logic                           emif_wr;
logic [ADDR_WIDTH-1:0]          start_rd_addr_emif, ddr_emif_rd_addr;
logic [LEN_WIDTH-1:0]           bytes_to_read_emif;
logic [6:0]                     rd_burst_len;
logic [3:0]                     rd_burst_remain;

logic [0:7][DATA_WIDTH-1:0]     data_emif_r;
logic [DATA_WIDTH-1:0]          data_emif;
logic [2:0]                     byte8_cnt;
logic                           data_last, data_first, data_first_flag, data_body;
logic [ADDR_WIDTH-1-3:0]        addr_emif;

enum logic [2:0] {IDLE, ADDR, LENGTH, READ, DATA} emif_cs, emif_ns;

always_comb begin : proc_fifo_rd
    fifo_rd_ena = ~fifo_empty;
    fifo_rd_clk = emif_clk;
end

// Control the FIFO read operation
always_ff @(posedge emif_clk) begin : proc_fifo_rd_ctrl
    if(~emif_rst_n) begin
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
                    start_wr_addr_emif <= fifo_rd_data[0] ? fifo_rd_data[DATA_WIDTH:1] : 0;
                    start_rd_addr_emif <= (~fifo_rd_data[0]) ? fifo_rd_data[DATA_WIDTH:1] : 0;
                    emif_wr <= fifo_rd_data[0];
                    if (fifo_rd_ena) emif_cs <= LENGTH;

                end
                LENGTH: begin
                    bytes_to_write_emif <= fifo_rd_data[0] ? fifo_rd_data[DATA_WIDTH:1] : 0;
                    bytes_to_read_emif <= (~fifo_rd_data[0]) ? fifo_rd_data[DATA_WIDTH:1] : 0;

                    if (fifo_rd_data[0]) begin
                        emif_cs <= DATA;
                    end
                    else begin
                        emif_cs <= READ;
                    end
                end
                READ: emif_cs <= IDLE;

                DATA: begin
                    data_emif <= fifo_rd_data;
                    if (bytes_to_write_emif ==1) begin
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
logic [3:0] byte_enble_cnt_head, byte_enble_cnt_body, byte_enble_cnt_tail;
logic [7:0] read_byte_enable_head, read_byte_enable_body, read_byte_enable_tail;

always_ff @(posedge emif_clk) begin : proc_emif_rd
    if(~emif_rst_n) begin
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
logic [511:0 ]          rdfifo_wr_data;
logic [DATA_WIDTH-1:0]  rdfifo_rd_data;
logic                   rdfifo_rd_valid;
logic [3:0]             rdfifo_rd_cnt;

always_ff @(posedge emif_clk) begin : proc_rdfifo_wr
    if(~emif_rst_n) begin
        rdfifo_wr_ena <= 0;
    end else begin
        // rdfifo full should never happens
        rdfifo_wr_ena <= ddr_emif_rddata_valid;
        // Big-Edian
        for (int i = 0; i < 8; i++) begin
            rdfifo_wr_data[i*64+:64] <= ddr_emif_read_data[(7-i)*64+:64];
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

fifo_512inx64out fifo_512inx64out (
    .data    (rdfifo_wr_data),    //  fifo_input.datain
    .wrreq   (rdfifo_wr_ena),   //            .wrreq
    .rdreq   (rdfifo_rd_ena),   //            .rdreq
    .wrclk   (emif_clk),   //            .wrclk
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
always_ff @(posedge emif_clk) begin : proc_emif_data_buffer
    if(~emif_rst_n) begin
         for (int i = 0; i < 8; i++) begin
            data_emif_r[i] <= 0;
        end
    end else begin
         for (int i = 0; i < 7; i++) begin
            data_emif_r[i+1] <= data_emif_r[i];
        end
        data_emif_r[0] <= fifo_rd_data[DATA_WIDTH:1];
    end
end

always_ff @(posedge emif_clk) begin : proc_byte8_cnt
    if(~emif_rst_n) begin
         byte8_cnt <= 0;
         data_first_flag <= 0;
    end else begin
        if (emif_cs == LENGTH && emif_wr) begin
            byte8_cnt <= start_wr_addr_emif;
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

always_ff @(posedge emif_clk) begin : proc_addr_emif
    if(~emif_rst_n || emif_cs == IDLE) begin
        addr_emif <= 0;
    end else begin
        if (ddr_emif_write) begin
            addr_emif <= addr_emif + 1'd1;
        end
    end
end

always_comb begin : proc_emif
    ddr_emif_wr_addr = 0;
    ddr_emif_write = 0;
    ddr_emif_byte_enable = 0;
    for (int i = 0; i < 8; i++) begin
        ddr_emif_write_data[i*64+:64] = data_emif_r[i];
    end
    if (data_first) begin
        ddr_emif_wr_addr = start_wr_addr_emif[ADDR_WIDTH-1:3];
        ddr_emif_write = 1;
        case(start_wr_addr_emif[2:0])
            3'd0: ddr_emif_byte_enable = {8{8'hff}};
            3'd1: ddr_emif_byte_enable = {{1{8'h00}},{7{8'hff}}};
            3'd2: ddr_emif_byte_enable = {{2{8'h00}},{6{8'hff}}};
            3'd3: ddr_emif_byte_enable = {{3{8'h00}},{5{8'hff}}};
            3'd4: ddr_emif_byte_enable = {{4{8'h00}},{4{8'hff}}};
            3'd5: ddr_emif_byte_enable = {{5{8'h00}},{3{8'hff}}};
            3'd6: ddr_emif_byte_enable = {{6{8'h00}},{2{8'hff}}};
            3'd7: ddr_emif_byte_enable = {{7{8'h00}},{1{8'hff}}};
        endcase // start_wr_addr_emif[2:0]
    end
    else if (data_body) begin
        ddr_emif_byte_enable = {8{8'hff}};
        ddr_emif_write = 1;
        ddr_emif_wr_addr = start_wr_addr_emif[ADDR_WIDTH-1:3] + addr_emif;
    end
    else if (data_last) begin
        ddr_emif_write = 1;
        ddr_emif_wr_addr = start_wr_addr_emif[ADDR_WIDTH-1:3] + addr_emif;
        // Big-Edian results in the data starts from the most-left side
        case(byte8_cnt)
            3'd0: begin
                ddr_emif_byte_enable = 'h0;
            end
            3'd1: begin
                ddr_emif_byte_enable = {{1{8'hff}}, {7{8'h00}}};
                for (int i = 7; i >=7; i--) begin
                     ddr_emif_write_data[i*64+:64] = data_emif_r[i-7];
                end
            end
            3'd2: begin
                ddr_emif_byte_enable = {{2{8'hff}}, {6{8'h00}}};
                for (int i = 7; i >= 6; i--) begin
                    ddr_emif_write_data[i*64+:64] = data_emif_r[i-6];
                end
            end
            3'd3: begin
                ddr_emif_byte_enable = {{3{8'hff}}, {5{8'h00}}};
                for (int i = 7; i >= 5; i--) begin
                    ddr_emif_write_data[i*64+:64] = data_emif_r[i-5];
                end
            end
            3'd4: begin
                ddr_emif_byte_enable = {{4{8'hff}}, {4{8'h00}}};
                for (int i = 7; i >= 4; i--) begin
                    ddr_emif_write_data[i*64+:64] = data_emif_r[i-4];
                end
            end
            3'd5: begin
                ddr_emif_byte_enable = {{5{8'hff}}, {3{8'h00}}};
                for (int i = 7; i >= 3; i--) begin
                    ddr_emif_write_data[i*64+:64] = data_emif_r[i-3];
                end
            end
            3'd6: begin
                ddr_emif_byte_enable = {{6{8'hff}}, {2{8'h00}}};
                for (int i = 7; i >= 2; i--) begin
                    ddr_emif_write_data[i*64+:64] = data_emif_r[i-2];
                end
            end
            3'd7: begin
                ddr_emif_byte_enable = {{7{8'hff}}};
                for (int i = 7; i >= 1; i--) begin
                    ddr_emif_write_data[i*64+:64] = data_emif_r[i-1];
                end
            end
        endcase // byte8_cnt
    end
end

always_ff @(posedge emif_clk) begin
    if (~emif_rst_n) begin
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


always @(posedge emif_clk) begin
    if(ddr_emif_write) begin
        $display("$time: write addr is %x, write_data is %x.\n", ddr_emif_addr, ddr_emif_write_data);
        $display("$time: byte write enable is %x.\n", ddr_emif_byte_enable);
    end

    if (ddr_emif_read) begin
        $display("$time: read address is 0x%x, read burst is %d.\n", ddr_emif_rd_addr, ddr_emif_burst_count);
    end
end


fifo_69x8192 fifo_64inx128_i (
    .wrclk(fifo_wr_clk),
    .wrreq(fifo_wr_ena),
    .data(fifo_wr_data),
    .wrfull(fifo_full),

    .rdclk(fifo_rd_clk),
    .rdreq(fifo_rd_ena),
    .rdempty(fifo_empty),
    .q(fifo_rd_data)
);


/*
            if (bytes_to_read_emif <= (4'd8 - start_rd_addr_emif[2:0])) begin
                ddr_emif_burst_count <= 1;
                byte_enble_cnt_head <= (4'd8 - start_rd_addr_emif[2:0]);
                byte_enble_cnt_body <= 0;
                byte_enble_cnt_tail <= 0;
            end
            else if (bytes_to_read_emif  > (4'd8 - start_rd_addr_emif[2:0]) &&
                    bytes_to_read_emif <= (16 - start_rd_addr_emif[2:0])) begin
                ddr_emif_burst_count <= 2;
                byte_enble_cnt_head <= (4'd8 - start_rd_addr_emif[2:0]);
                byte_enble_cnt_body <= (16 - start_rd_addr_emif[2:0]);
                byte_enble_cnt_tail <= 0;
            end
            else begin
               // 1 + [(bytes_to_read_emif - (8 - start_rd_addr_emif[2:0]))/8]
                ddr_emif_burst_count <= ((start_rd_addr_emif[2:0] + bytes_to_read_emif) >> 3)
                                        + (|(start_rd_addr_emif[2:0] ^ bytes_to_read_emif[2:0]));
                byte_enble_cnt_head <= (4'd8 - start_rd_addr_emif[2:0]);
                byte_enble_cnt_body <= 8;
                byte_enble_cnt_tail <= (start_rd_addr_emif[2:0] + bytes_to_read_emif) & 'h7;
            end
            */

endmodule