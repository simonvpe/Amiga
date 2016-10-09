`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:40:09 10/07/2016 
// Design Name: 
// Module Name:    pll 
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
// http://www.ti.com/lit/ds/symlink/sn74ls297.pdf
// http://fpga4fun.com/Counters1.html

module mfm_pll #(
  parameter F_K  = 32_000_000,
  parameter F_ID = 16_000_000
) (
  input  wire clk_k,
  input  wire clk_id,
  input  wire din,
  output wire dout,
  output wire cout,
  output wire lck
);
  parameter F_C = 500_000; // MF Data rate
  
  // Signal conditioner
  reg [$clog2(F_K/F_C)-2:0] sig_count = 0;
  always @ ( posedge clk_k ) begin
    if( din | ( sig_count > 0 ) ) begin
      sig_count <= sig_count + 1;
    end
  end
  assign dout = sig_count > 0;
  
  // PLL
  pll #( .F_K(F_K), .F_ID(F_ID), .F_C(F_C) ) PLL_Obj (
    .clk_k( clk_k ),
    .clk_id( clk_id ),
    .sig( dout ),
    .clk_c( cout ),
    .lck( lck )
  );
endmodule

module pll #(
  // Clock frequencies must be powers of two
  parameter F_K   = 32_000_000,
  parameter F_ID  = 16_000_000,
  parameter F_C   =    500_000
) (
  input  wire clk_k,
  input  wire clk_id,
  input  wire sig,
  output wire clk_c,
  output reg  lck     = 0
);
  parameter M      = F_K  / F_C;     // K multiplier              64
  parameter N      = F_ID / F_C / 2; // N modulo                  16
  parameter K      = M     ;         // K modulo                  32
  parameter K_BITS = $clog2(K);      // K number of counter bits
  parameter N_BITS = $clog2(N);      // N number of counter bits

  // TODO: OPTIMIZE COUNTERS
  // Input signal may be short pulses so we smooth them out to be half an F_C period long
  
  // Only enable the K counter directly after a signal and hold it for half an F_C period since
  // adjusting during an MFM zero would be bad
  reg [$clog2(M)-1:0] en_count = 0;
  always @ ( posedge clk_k ) begin
    if( sig | ( en_count > 0 ) ) begin
      en_count <= en_count + 1;
    end
  end
  wire en = ( en_count > 0 );

  wire carry, borrow, id;         // Module interconnections
  wire edgedet = ~(sig ^ clk_c);  // Edge detector
  
  pll_k      #( .K_BITS(K_BITS) ) K_MODULE  ( .clk(clk_k),  .enable(en),    .down(edgedet), .carry(carry), .borrow(borrow) );
  pll_id                          ID_MODULE ( .clk(clk_id), .inc(carry),    .dec(borrow),   .out(id)                       );
  pll_divbyn #( .N_BITS(N_BITS) ) DN_MODULE ( .clk(id),     .out(clk_c)                                                    );
  
  always @ ( posedge clk_c ) begin
    if( en )
      lck <= sig;
    else
      lck <= lck;
  end
endmodule

// Divide-by-N counter
module pll_divbyn #(
  parameter N_BITS  = 3// 2^N_BITS ticks for one period
) (
  input  wire clk,
  output wire out
);
  reg [N_BITS-1:0] u = 0;
  always @ (posedge clk) begin
    u <= u + 1;
  end
  assign out = u[N_BITS-1];
endmodule

// K Counter
module pll_k #(
  parameter K_BITS = 4// 2^K_BITS resolution for one period
)(
  input  wire       clk,
  input  wire       enable,
  input  wire       down,
  output reg        carry  = 0,
  output reg        borrow = 0
);
  reg  [K_BITS-1:0] u      = 0;
  reg  [K_BITS-1:0] d      = 0;
  wire [K_BITS:0]   u_next = u[K_BITS-1:0] + 1;
  wire [K_BITS:0]   d_next = d[K_BITS-1:0] + 1;
  always @ (posedge clk) begin
    if( enable ) begin
      u <= ~down ? u_next : u;
      d <=  down ? d_next : d;
      carry  <= u_next[K_BITS];
      borrow <= d_next[K_BITS];
    end
  end
endmodule
  
// I/D Module
module pll_id(
  input  wire clk, 
  input  wire inc, 
  input  wire dec,
  output reg  out
);
  reg [3:0] si  = 0;
  reg [3:0] sd  = 0;
  reg       jko = 0;
  
  always @ ( negedge clk ) begin
    si <= { ( ~si[0] & si[1] | ~si[1] & si[2] ) &  jko, si[1], si[0], inc };
    sd <= { ( ~sd[0] & sd[1] | ~sd[1] & sd[2] ) & ~jko, sd[1], sd[0], dec };
    case({ ~si[3], ~sd[3] })
      2'b0_0: jko <= jko;
      2'b0_1: jko <= 0;
      2'b1_0: jko <= 1;
      2'b1_1: jko <= ~jko;
    endcase
  end
  always @ ( clk ) begin
    out <= ~( jko | clk );
  end
endmodule