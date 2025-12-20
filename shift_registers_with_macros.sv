
//`define SISO_REG_VLD
//`define SIPO_REG_VLD
`define PISO_REG_VLD
//`define PIPO_REG_VLD


module shift_registers(
    input  logic        shift_reg_clk,
    input  logic        shift_reg_rst_n,
    input  logic [3:0]  shift_reg_din_vld,
    input  logic        shift_piso_load,
    input  logic [3:0]  shift_reg_din,

    output logic [3:0]  shift_reg_dout_vld,
    output logic [3:0]  shift_reg_dout
);

    // -----------------------------
    // Internal registers
    // -----------------------------

`ifdef SISO_REG_VLD
    logic       siso_reg;
    logic       siso_reg_dout_vld;
`endif

`ifdef SIPO_REG_VLD
    logic [3:0] sipo_reg;
    logic       sipo_reg_dout_vld;
`endif

`ifdef PISO_REG_VLD
    logic [3:0] piso_reg;
    logic       piso_reg_dout_vld;
`endif

`ifdef PIPO_REG_VLD
    logic [3:0] pipo_reg;
    logic       pipo_reg_dout_vld;
`endif


    // ============================================================
    // SISO LOGIC
    // ============================================================
`ifdef SISO_REG_VLD
    always_ff @(posedge shift_reg_clk or negedge shift_reg_rst_n)
      if(!shift_reg_rst_n){siso_reg_dout_vld, siso_reg} <= 2'b00;
     else {siso_reg_dout_vld, siso_reg} <= shift_reg_din_vld[0] ?{1'b1, shift_reg_din[0]} :2'b00;
`endif


    // ============================================================
    // SIPO LOGIC
    // ============================================================
`ifdef SIPO_REG_VLD
    always_ff @(posedge shift_reg_clk or negedge shift_reg_rst_n)
      if(!shift_reg_rst_n) {sipo_reg_dout_vld, sipo_reg} <= 5'b0;
  else {sipo_reg_dout_vld, sipo_reg} <= (shift_reg_din_vld[1])? {1'b1, sipo_reg[2:0], shift_reg_din[0]} :5'b0;
`endif


    // ============================================================
    // PISO LOGIC
    // ===========================================================
`ifdef PISO_REG_VLD
always_ff @(posedge shift_reg_clk or negedge shift_reg_rst_n)
  if (!shift_reg_rst_n) {piso_reg_dout_vld, piso_reg} <= 5'b0;

  // Parallel load
  else if (shift_piso_load && shift_reg_din_vld[2]) {piso_reg_dout_vld, piso_reg} <= {1'b1, shift_reg_din};

  // Shift out (serial operation)
  else if (!shift_piso_load && !shift_reg_din_vld[2])
  {piso_reg_dout_vld, piso_reg} <= {1'b1, {piso_reg<<1}};

`endif
// ============================================================

    // ============================================================
    // PIPO LOGIC
    // ============================================================
`ifdef PIPO_REG_VLD
    always_ff @(posedge shift_reg_clk or negedge shift_reg_rst_n)
      if(!shift_reg_rst_n) {pipo_reg_dout_vld, pipo_reg} <= 5'b0;
  else {pipo_reg_dout_vld, pipo_reg} <= (shift_reg_din_vld[3]? {1'b1, shift_reg_din} :5'b0);
`endif




    // ============================================================
    // OUTPUT VALID (based only on enabled blocks)
    // ============================================================
    always_comb begin
        shift_reg_dout_vld = 4'b0000;

`ifdef SISO_REG_VLD
        shift_reg_dout_vld = siso_reg_dout_vld ? 4'b0001 : shift_reg_dout_vld;
`endif

`ifdef SIPO_REG_VLD
        shift_reg_dout_vld = sipo_reg_dout_vld ? 4'b0010 : shift_reg_dout_vld;
`endif

`ifdef PISO_REG_VLD
        shift_reg_dout_vld = piso_reg_dout_vld ? 4'b0100 : shift_reg_dout_vld;
`endif

`ifdef PIPO_REG_VLD
        shift_reg_dout_vld = pipo_reg_dout_vld ? 4'b1000 : shift_reg_dout_vld;
`endif
    end



    // ============================================================
    // OUTPUT DATA (based on enabled blocks)
    // ============================================================
    always_comb begin
        shift_reg_dout = 4'h0;

`ifdef SISO_REG_VLD
        shift_reg_dout = siso_reg_dout_vld ? {3'b000, siso_reg} : shift_reg_dout;
`endif

`ifdef SIPO_REG_VLD
        shift_reg_dout = sipo_reg_dout_vld ? sipo_reg : shift_reg_dout;
`endif

`ifdef PISO_REG_VLD
      shift_reg_dout = piso_reg_dout_vld ? { piso_reg[3]} : shift_reg_dout;
`endif

`ifdef PIPO_REG_VLD
        shift_reg_dout = pipo_reg_dout_vld ? pipo_reg : shift_reg_dout;
`endif
    end

endmodule

//----------------------------------------------------------------------------------------------------------------------------------

//---------------------------------------  test_bench--------------------------------------------------------------------------

// ----------------------------------------------------
// ENABLE ONLY ONE BLOCK FOR TEST
// ----------------------------------------------------
//`define SISO_REG_VLD
//`define SIPO_REG_VLD
`define PISO_REG_VLD
//`define PIPO_REG_VLD

module tb_shift_registers;

    logic        clk;
    logic        rst_n;
    logic [3:0]  shift_reg_din_vld;
    logic        shift_piso_load;
    logic [3:0]  shift_reg_din;

    logic [3:0]  shift_reg_dout_vld;
    logic [3:0]  shift_reg_dout;

    // ----------------------------------------------------
    // DUT
    // ----------------------------------------------------
    shift_registers DUT(
        .shift_reg_clk(clk),
        .shift_reg_rst_n(rst_n),
        .shift_reg_din_vld(shift_reg_din_vld),
        .shift_piso_load(shift_piso_load),
        .shift_reg_din(shift_reg_din),
        .shift_reg_dout_vld(shift_reg_dout_vld),
        .shift_reg_dout(shift_reg_dout)
    );

    // ----------------------------------------------------
    // Clock generation
    // ----------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ----------------------------------------------------
    // Reset sequence
    // ----------------------------------------------------
    task apply_reset();
        begin
            rst_n = 0;
            shift_reg_din_vld = 4'b0000;
            shift_piso_load   = 0;
            shift_reg_din     = 0;

            @(posedge clk);
           @(posedge clk);
            rst_n = 1;
            @(posedge clk);
        end
    endtask

    // ----------------------------------------------------
    // TEST: SISO BLOCK
    // ----------------------------------------------------
`ifdef SISO_REG_VLD
    task run_siso();
        begin
            $display("====== SISO TEST START ======");

            // Input pattern: 1 → 0 → 1 → 1
            shift_reg_din = 4'b0001;

            // ------------ input #1 (1) ------------
            shift_reg_din_vld = 4'b0001;
            @(posedge clk);

            // ------------ input #2 (0) ------------
            shift_reg_din = 4'b0000;
            @(posedge clk);

            // ------------ input #3 (1) ------------
            shift_reg_din = 4'b0001;
            @(posedge clk);

            // ------------ input #4 (1) ------------
            shift_reg_din = 4'b0001;
            @(posedge clk);

            shift_reg_din_vld = 0;
            @(posedge clk);

            $display("====== SISO TEST END ======");
        end
    endtask
`endif

    // ----------------------------------------------------
    // TEST: SIPO BLOCK
    // ----------------------------------------------------
`ifdef SIPO_REG_VLD
    task run_sipo();
        begin
            $display("====== SIPO TEST START ======");
            
            // Shift in 4 bits 1, 0, 1, 1
            shift_reg_din_vld = 4'b0010;

            shift_reg_din = 4'b0001; @(posedge clk);
            shift_reg_din = 4'b0000; @(posedge clk);
            shift_reg_din = 4'b0001; @(posedge clk);
            shift_reg_din = 4'b0001; @(posedge clk);

            shift_reg_din_vld = 0;
            @(posedge clk);

            $display("====== SIPO TEST END ======");
        end
    endtask
`endif

    // ----------------------------------------------------
    // TEST: PISO BLOCK
    // ----------------------------------------------------
`ifdef PISO_REG_VLD
task run_piso();
    begin
        $display("====== PISO TEST START ======");

        // -----------------------------
        // RESET ASSUMED DONE BEFORE
        // -----------------------------

        // LOAD parallel data (1101)
        shift_piso_load    <= 1'b1;
        shift_reg_din      <= 4'b1101;
        shift_reg_din_vld  <= 4'b0100;   // bit[2] = 1 ONLY for load
        #10 @(posedge clk);


        // -----------------------------
        // START SHIFTING
        // -----------------------------
        shift_piso_load    <= 1'b0;
        shift_reg_din_vld  <= 4'b0000;   // MUST be 0 durin

      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);

    end
endtask
`endif



    // ----------------------------------------------------
    // TEST: PIPO BLOCK
    // ----------------------------------------------------
`ifdef PIPO_REG_VLD
    task run_pipo();
        begin
            $display("====== PIPO TEST START ======");

            // Give multiple parallel inputs
            shift_reg_din_vld = 4'b1000;

            shift_reg_din = 4'b1010; @(posedge clk);
            shift_reg_din = 4'b1111; @(posedge clk);
            shift_reg_din = 4'b0001; @(posedge clk);

            shift_reg_din_vld = 0;

            //$display("====== PIPO TEST END ======");
        end
    endtask
`endif

    // ----------------------------------------------------
    // Monitor
    // ----------------------------------------------------
    initial begin
      $monitor("TIME |INPUT|INPUT_VLD| OUT_VLD | OUT_DATA");
      $monitor("%0t | %4b|%4b|%4b | %4b", $time, shift_reg_din,shift_reg_din_vld,shift_reg_dout_vld, shift_reg_dout);
    end

    // ----------------------------------------------------
    // Main sequence
    // ----------------------------------------------------
    initial begin
        apply_reset();
#30;

`ifdef SISO_REG_VLD
        run_siso();
`endif

`ifdef SIPO_REG_VLD
        run_sipo();
`endif

`ifdef PISO_REG_VLD
        run_piso();
`endif

`ifdef PIPO_REG_VLD
        run_pipo();
`endif

        #50;
        $finish;
    end
initial begin
$dumpfile("dump.vcd"); $dumpvars;
end
endmodule

