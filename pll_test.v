`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:35:47 10/07/2016
// Design Name:   pll
// Module Name:   C:/Users/simonp/DiskSlayer/Documents/DiskSlayer/pll_test.v
// Project Name:  DiskSlayer
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: pll
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module pll_test;

	// Inputs
	reg clk_k;
	reg clk_id;
	reg sig;

	// Outputs
	wire cout;
  wire dout;
  wire lck;

	// Instantiate the Unit Under Test (UUT)
	mfm_pll uut (
		.clk_k(clk_k), 
		.clk_id(clk_id), 
		.din(sig), 
		.cout(cout),
    .dout(dout),
    .lck(lck)
	);

	initial begin
		// Initialize Inputs
		clk_k = 0;
		clk_id = 0;
		sig = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
  
  reg clk8 = 1, clk4 = 1, clk2 = 1, clk1 = 1, clk05 = 1;
  
  always begin                     // 32 MHz
    #1; clk_k <= ~clk_k;
  end
  
  always @ ( posedge clk_k ) begin // 16 MHz
    clk_id <= ~clk_id;
  end
  
  always @ ( posedge clk_id ) clk8 <= ~clk8; // 8MHz
  always @ ( posedge clk8   ) clk4 <= ~clk4;
  always @ ( posedge clk4   ) clk2 <= ~clk2;
  always @ ( posedge clk2   ) clk1 <= ~clk1; // 1MHz
  always @ ( posedge clk1   ) clk05 <= ~clk05;
  //always @ ( posedge clk1   ) sig  <= ~sig;
 
  // Simulate short MFM pulses with 2us intervals
  reg [31:0] synk = 32'b0100_0100_1000_1001_0100_0100_1000_1001; // 0x4489
  //reg [31:0] synk = ~0;
  reg [$clog2(32)-1:0] pos = 0;
  always @(posedge clk05) begin
    //d <= { d[3:0], d[4] ^ d[3] };
    #70;
    sig <= synk[pos];
    pos <= pos + 1;
    #8; 
    sig <= 0;
  end
  
  
endmodule

