
//--------------------------------------------------------------------------------------------------------------------------------
//DUT
//----------------------------------------------------------------------------------------------------------------------------------

module shift_registers(
    input  logic shift_reg_clk,           
    input  logic shift_reg_rst_n,
    input  logic shift_reg_din_vld,
    input  logic  shift_piso_load,
    input  logic [3:0] shift_reg_din,
    input  logic [3:0] shift_reg_one_hot,
    output logic [3:0] shift_reg_dout_vld,
    output logic [3:0] shift_reg_dout
);

    logic       siso_reg;
    logic       siso_reg_vld;
    logic       sipo_reg_vld;
    logic       piso_reg_vld;
    logic       pipo_reg_vld;
    
    logic [3:0] sipo_reg;
    logic [3:0] piso_reg;
    logic [3:0] pipo_reg;

   // ---------------- SISO ----------------
always_ff @(posedge shift_reg_clk or negedge shift_reg_rst_n) 
{siso_reg_vld,siso_reg}<= (!shift_reg_rst_n) ? 2'b00:
  (shift_reg_one_hot[0] & shift_reg_din_vld) ? {1'b1,shift_reg_din[0]} : 4'h0;

// ---------------- SIPO ----------------
always_ff @(posedge shift_reg_clk or negedge shift_reg_rst_n) 
{sipo_reg_vld,sipo_reg} <= (!shift_reg_rst_n) ? 5'h0 :
  (shift_reg_one_hot[1] & shift_reg_din_vld) ? {sipo_reg[2:0], {1'b1,shift_reg_din[0]}} : 4'h0;


// ---------------- PISO ----------------
always_ff @(posedge shift_reg_clk or negedge shift_reg_rst_n) 
{piso_reg_vld,piso_reg} <= (!shift_reg_rst_n) ? 5'h0 :
  ((shift_reg_one_hot[2]) & shift_piso_load & shift_reg_din_vld) ? {1'b1,shift_reg_din[3:0]}:
  ((shift_reg_one_hot[2]) & (!shift_piso_load)) ? piso_reg << 1 :4'h0;        
  /*assign piso_serial_out = shift_reg_piso[3];*/   

// ---------------- PIPO ----------------
always_ff @(posedge shift_reg_clk or negedge shift_reg_rst_n) 
{pipo_reg_vld,pipo_reg} <= (!shift_reg_rst_n) ? 4'h0 :
  (shift_reg_one_hot[3] & shift_reg_din_vld) ? {1'b1, shift_reg_din} :
                4'h0;


    // ---------------- OUTPUT VALID ----------------
    always_comb 
    shift_reg_dout_vld = (shift_reg_one_hot[0] & shift_reg_din_vld) ? 4'b0001 :
                         (shift_reg_one_hot[1] & shift_reg_din_vld) ? 4'b0010 :
                         (shift_reg_one_hot[2] & shift_reg_din_vld) ? 4'b0100 :
                         (shift_reg_one_hot[3] & shift_reg_din_vld) ? 4'b1000 :
                         4'b0000;


    // ---------------- OUTPUT DATA ----------------
    always_comb 
      shift_reg_dout = (shift_reg_one_hot[0] & siso_reg_vld ) ? {3'b000, siso_reg} :
      shift_reg_one_hot[1] & sipo_reg_vld ? sipo_reg[3:0] :
      shift_reg_one_hot[2]& piso_reg_vld ? {3'b000, piso_reg[3]} :
      shift_reg_one_hot[3] & pipo_reg_vld ? pipo_reg : 4'h0;

endmodule
//------------------------------------------------------------------------------------------------------------------------------------
//test_bench
//------------------------------------------------------------------------------------------------------------------------------

module shift_registers_tb;

    logic clk;
    logic rst_n;
    logic din_vld;
    logic piso_load;
    logic [3:0] din;
    logic [3:0] one_hot;
    logic [3:0] dout_vld;
    logic [3:0] dout;

    // Instantiate DUT
    shift_registers dut (
        .shift_reg_clk(clk),
        .shift_reg_rst_n(rst_n),
        .shift_reg_din_vld(din_vld),
      .shift_piso_load(piso_load),
        .shift_reg_din(din),
        .shift_reg_one_hot(one_hot),
        .shift_reg_dout_vld(dout_vld),
        .shift_reg_dout(dout)
    );
    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; 

    initial begin
        // Reset
        rst_n = 0; din_vld = 0; din = 0; one_hot = 4'b0000;
      #20 @(posedge clk) rst_n = 1;

        // ---------- SISO TEST ----------
        $display("===== SISO TEST =====");
        one_hot = 4'b0001; // SISO mode

      din = 4'b0001; din_vld = 1; #10 @(posedge clk);
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

      din = 4'b0000; din_vld = 1; #10 @(posedge clk) ;
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

        din_vld = 0; #10 ;@(posedge clk)
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

        // ---------- SIPO TEST ----------
      $display("=============== SIPO TEST =====================");
        one_hot = 4'b0010; // SIPO mode

      din = 1; din_vld = 1; #10 @(posedge clk) ;
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

        din = 0; din_vld = 1; #10 @(posedge clk) ;
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

        din = 1; din_vld = 1; #10 @(posedge clk);
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

      din=1;din_vld = 1;// #10 @(posedge clk);
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

        // ---------- PISO TEST ----------
        $display("===== PISO TEST =====");
        one_hot = 4'b0100; // PISO mode

      din = 4'b1111;piso_load=1; din_vld = 1; #10 @(posedge clk); // Load
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

      piso_load =0;din_vld = 1; #10 @(posedge clk); // Shift 1
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

     din_vld = 1; #10 @(posedge clk); // Shift 2
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

     din_vld = 1; #10 @(posedge clk); // Shift 3
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

        // ---------- PIPO TEST ----------
        $display("===== PIPO TEST =====");
        one_hot = 4'b1000; // PIPO mode

      din = 4'b1010; din_vld = 1; #10 @(posedge clk);
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

      din_vld = 0; #10 @(posedge clk);
        $display("Time=%0t | DIN=%b | DIN_VLD=%b | DOUT=%b | DOUT_VLD=%b", $time, din, din_vld, dout, dout_vld);

        $finish;
    end
initial begin
$dumpfile("dump.vcd"); $dumpvars;
end

endmodule


