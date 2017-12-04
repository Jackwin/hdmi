module dac (
    input       ref_clk,  // clk is 10 MHz
    input       reset_n,

    output [13:0] dac_data

);

reg [13:0] sin_mem [0:19];
reg [4:0] cnt;
initial begin
    $readmemh("sin.dat",sin_mem);
end

always @(posedge ref_clk) begin
    if (~reset_n) begin
        dac_data <= 0;
        cnt <= 0;
    end
    else begin
        if (cnt == 4'd19) begin
            cnt <= 0;
        end
        else begin
            cnt <= cnt + 1;
        end
    end
end

assign dac_data = sin_mem[cnt];



endmodule