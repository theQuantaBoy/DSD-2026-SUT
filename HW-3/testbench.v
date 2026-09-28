`timescale 1ns / 1ns
module testbench;
    reg clk;
    reg sin;
    wire [2:0] q;

    shift_register_3bit uut (clk, sin, q);

    always #7 clk = ~clk;

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, testbench);

        $display("Time\t clk\t sin\t q[2:0]");
        $display("-------------------------------");
    end

    always @(clk, sin, q) begin
        #0.1; 
        $display("%2dt\t  %b\t  %b\t  %b", $time, clk, sin, q);
    end

    initial begin
        clk = 0;
        sin = 0;

        #5; sin = 1;
        #5; sin = 0;
        #8; sin = 1;

        #40; $finish;
    end
endmodule