module counter(CLK,Q,clr);
	input CLK, clr;
	output [3:0]Q;

	TFF tff0(CLK,clr,Q[0]);
	TFF tff1(Q[0],clr,Q[1]);
	TFF tff2(Q[1],clr,Q[2]);
	TFF tff3(Q[2],clr,Q[3]);
endmodule

module TFF(CLK,reset,Q);
	output Q;
	input CLK, reset;
	wire d;
	
	DFF dff0(d,CLK,Q,reset);
	not g1(d,Q);
endmodule

module DFF(D,clk,Q,CLR);
	input D, clk, CLR;
	output Q;
	reg Q;

	always @(negedge clk, posedge CLR)
		if(CLR == 1)
			Q=0;
		else
			Q=D;
endmodule


module Test_Bench;
	wire q;
	reg clk, reset;


	counter CUD(clk,q,reset);


	initial
		clk = 0;

	always #5
		clk = ~clk;
	
	initial	
		begin
			reset = 0;
			#17 	reset = 1;
			#25 	reset = 0;
			#184	reset = 1;
			#11		reset = 0;
			$finish;
		end
	
	initial
		$monitor("Time = %t, Reset = %b, CLK = %b, Q = %d",$time,reset,clk,q);

endmodule
