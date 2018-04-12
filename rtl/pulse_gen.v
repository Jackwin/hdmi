`timescale 1ns/1ps
// Generate a pulse that holds a certain number of clock cycles
module pulse_gen (
    input       clk,
    input       rst_n,
    input       start,
    input[31:0] pulse_cycle_in,
    output      pulse_out,
    output reg  end_out
);

reg         pulse;
reg [31:0]  cnt;
reg [31:0]  pulse_cycle_reg;

assign pulse_out = pulse;

always @(posedge clk) begin
    if(~rst_n) begin
       cnt <= 'h0;
       pulse <= 1'b0;
       pulse_cycle_reg <= 'h0;
       end_out <= 1'b0;
    end else begin
        end_out <= 1'b0;
        if (start) begin
            pulse <= 1'b1;
            pulse_cycle_reg <= pulse_cycle_in - 1'd1;
        end
        else if (end_out) begin
            cnt <= 'h0;
        end

        if (cnt == pulse_cycle_reg & (|cnt)) begin
            pulse <= 1'b0;
            end_out <= 1'b1;
            cnt <= 'h0;
        end

        if (pulse) cnt <= cnt + 1'd1;
    end
end
endmodule
