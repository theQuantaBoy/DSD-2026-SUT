module MUX_2_1 (I0, I1, sel, O);

    input [7:0] I0, I1;
    input sel;
    output [7:0] O;
    reg [7:0] O;

    always @(I0, I1)
        if (sel == 1)
            O = I1;
        else
            O = I0;

endmodule