module priority_arbitration(
	input       arb_clk,
	input       arb_rst_n,
	input       arb_req0,
	input       arb_req1,
	input       arb_req2,
	input       arb_req3,
	output logic[1:0] arb_gnt);
	always_ff @ (posedge arb_clk or negedge arb_rst_n)begin
		if(!arb_rst_n) arb_gnt < = 2'b00;
		else begin
			if     (arb_req1)  arb_gnt < = 2'b01;
			else if(arb_req3)  arb_gnt < = 2'b11;
			else if(arb_req2)  arb_gnt < = 2'b10;
	        	else   (arb_req0)  arb_gnt < = 2'b00;
		end
	end
	endmodule
//--------------------------------------------------------------------------------------------------------------------------------------------
//simple test bench for checking functionality
//------------------------------------------------------------------------------------------------------------------------------------------------

module tb_priority_arbitration;

  logic arb_clk;
  logic arb_rst_n;
  logic arb_req0, arb_req1, arb_req2, arb_req3;
  logic [1:0] arb_gnt;

  priority_arbitration dut (
    .arb_clk(arb_clk),
    .arb_rst_n(arb_rst_n),
    .arb_req0(arb_req0),
    .arb_req1(arb_req1),
    .arb_req2(arb_req2),
    .arb_req3(arb_req3),
    .arb_gnt(arb_gnt)
  );


  initial arb_clk = 0;
  always #5 arb_clk = ~arb_clk;


  initial begin

    arb_rst_n = 0;
    arb_req0  = 0;
    arb_req1  = 0;
    arb_req2  = 0;
    arb_req3  = 0;
    #10 @(posedge arb_clk);

    arb_rst_n = 1; // realse th reset active low reset(1)
    #10@(posedge arb_clk);

    arb_req0 = 1;
    arb_req1 = 1;
    arb_req2 = 1;
    arb_req3 = 1;
    #10@(posedge arb_clk);

    arb_req0 = 1;
    arb_req1 = 0;
    arb_req2 = 1;
    arb_req3 = 1;
    #10;

    $finish;
  end

  initial begin
    $monitor("Time=%0t | Req0=%b Req1=%b Req2=%b Req3=%b | Gnt=%b",
              $time, arb_req0, arb_req1, arb_req2, arb_req3, arb_gnt);
  end

endmodule




