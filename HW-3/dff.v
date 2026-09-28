`timescale 1ns / 1ns
module dff (input clk, input d, output reg q);
    initial begin
        q = 0;
    end

    always @(posedge clk) begin
        q <= #3 d;
    end
endmodule