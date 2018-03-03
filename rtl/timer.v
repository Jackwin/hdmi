module timer # (
    parameter   MAX = 256
    )
(
    input       clk,    // Clock
    input       rst_n,  // Asynchronous reset active low

    input       timer_ena,
    input       timer_rst,

    output reg      timer_out

);

reg [31:0]       timer_cnt;

always @(posedge clk) begin
    if(~rst_n || timer_rst) begin
        timer_out <= 0;
        timer_cnt <= 0;
    end
    else begin
        timer_out <= 0;
        if (timer_cnt == MAX) begin
            timer_out <= 1;
            timer_cnt <= 0;
        end
        else if (timer_ena) begin
            timer_cnt <= timer_cnt + 1'd1;
        end
        else begin
            timer_cnt <= 0;
        end
    end
end

endmodule