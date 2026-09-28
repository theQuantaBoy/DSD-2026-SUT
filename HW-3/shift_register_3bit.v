`timescale 1ns / 1ns
module shift_register_3bit (input clk, input sin, output [2:0] q);
    dff ff0 (clk, sin,  q[0]);
    dff ff1 (clk, q[0], q[1]);
    dff ff2 (clk, q[1], q[2]);
endmodule