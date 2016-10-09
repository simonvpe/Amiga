`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:37:42 09/03/2016 
// Design Name: 
// Module Name:    diskslayer_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module diskslayer_top (
    input   clk,          /* 50MHz clock. */
    input   rst_n,        /* Reset circuitry. */
    
    /* FLOPPY INTERFACE */
    output wire DSKMOTOR_n,                           
    output wire DSKSEL0_n,
    output wire DSKSIDE,
    output wire DSKDIREC, 
    output wire DSKSTEP_n,
    output wire DSKWD_n,
    output wire DSKWE_n,
    input  wire DSKIDX_n,
    input  wire DSKRDY_n,
    input  wire DSKTRACK0_n,
    input  wire DSKPROT_n,
    input  wire DSKCHANGE_n,
    input  wire DSKRD_n,
    
    /* LED */
    output wire [7:0] led,
    
    /* UART */
    input  UART_RX,
    output UART_TX
    );
  
  assign DSKMOTOR_n = 0;
  assign DSKSEL0_n  = 0;
  assign DSKSIDE    = 0;
  assign DSKDIREC   = 0;
  assign DSKSTEP_n  = 1;
  assign DSKWD_n    = 0;
  assign DSKWE_n    = 1;
  
  
  reg [7:0] lock_count = 0;
  assign led = { lock_count };
  
  reg       tx_new_data;
  reg [7:0] tx_data;
  wire      tx_busy;
  serial_tx #( 50 ) (
    .clk       ( clk         ),
    .rst       ( ~rst_n      ),
    .tx        ( UART_TX     ),
    .new_data  ( tx_new_data ),
    .data      ( tx_data     ),
    .busy      ( tx_busy     )
  );
    
  always @ ( posedge clk ) begin
    tx_data <= "h";
    if( ~tx_busy ) begin
      tx_new_data <= 1'b1;
    end else begin
      tx_new_data <= 1'b0;
    end
  end
  
  // Clock
  wire clk200, clk32, clk16;
  clksrc clock( .CLK_IN( clk ), .RESET(0), .CLK200( clk200 ), .CLK32( clk32 ), .CLK16( clk16 ) );

  wire dout, cout, lck_o;
  mfm_pll #( .F_K( 32_000_000 ), .F_ID( 16_000_000 ) ) PLL ( 
    .clk_k( clk32 ),
    .clk_id( clk16 ),
    .din( ~DSKRD_n ),
    .dout( dout ),
    .cout( cout ),
    .lck(lck_o)
    );
  
  always @ ( posedge lck_o ) begin
    lock_count <= lock_count + 1;
  end
endmodule
