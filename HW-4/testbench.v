`timescale 1ns / 1ns

module testbench;
    reg [7:0] I0;
    reg [7:0] I1;
    reg sel;
    wire [7:0] O;

    MUX_2_1 mux (I0, I1, sel, O);

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, testbench);

        $display("Time\t I0\t I1\t sel\t O");
        $display("-----------------------------------------");
    end

    always @(I0, I1, sel, O) begin
        #0.1; 
        $display("%4dt\t %h\t %h\t  %b\t %h", $time, I0, I1, sel, O);
    end

    initial begin
        I0 = 8'hAA; I1 = 8'hBB; sel = 1;
        #20;

        sel = 0;
        #20;

        I0 = 8'h00;
        #20;
        
        I0 = 8'hAA;
        #20;

        sel = 1;
        #20;

        $finish;
    end
endmodule