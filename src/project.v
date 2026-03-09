/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

//---------------------------------------------------------------------
// Top wrapper - inout
//---------------------------------------------------------------------

module tt_um_datiuemm (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
 /* assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};
*/

//---------------------------------------------------------------------
// Parameter and internal wire
//---------------------------------------------------------------------

//Please make sure final bit NUM_BIT_OF_MODE+x =< 7
//MBIST mode
parameter NUM_BIT_OF_MODE = 2; 
wire [NUM_BIT_OF_MODE:0] mbist_mode; /* 5 mode of MBIST  //Should try typedef enum next time?
				        000: Run in normal mode
				  	001: MBIST MARCH-C normal test start, also in this mode will bypass ECC
				  	011: Fault injection to MBIST, first bit of Data in RAM with add_in will be flip to make sure MBIST is working, in this state, output (TBD) will be 1
				  	100: Reserved
				  	101: MBIST will start ECC check by fault injection
				  	110: Reserved
				  	111: Reserved
				    */ //If mode is on Reserved: will run like normal (like 000 state) //Can reduce to 2 bit only to save input
			
assign mbist_mode = ui_in[NUM_BIT_OF_MODE:0] ;


//TBD				
wire [2:0] add_in;
assign add_in = ui_in[NUM_BIT_OF_MODE+3:NUM_BIT_OF_MODE+1]; //8 bit address, so need to change this if ram more thab 8x32 //Func: TBD
				
//---------------------------------------------------------------------
// Reset_n (need to init)
//---------------------------------------------------------------------
//Use synchronous reset for good timing and not glitch, you can try asynchronous reset)
always @(posedge clk) begin
	if (rst_n == 1'b0) begin
		//mbist_mode <= NUM_BIT_OF_MODE'b0;
		//More please
		//Don't reset RAM
	end
end
//---------------------------------------------------------------------
// Instance
//---------------------------------------------------------------------

wire mbist_en;
assign mbist_en = (mbist_mode == 3'b001);

wire [4:0]  ram_we;
wire [2:0]  ram_addr;
wire [39:0] ram_data_i;
wire [39:0] ram_data_o;
wire        ecc_bypass;
wire [2:0]  results;

assign uo_out[2:0] = results;
assign uo_out[7:3] = 5'b0;

assign uio_out = 8'b0;
assign uio_oe  = 8'b0;

wire ram_en = 1'b1;

RAM8 inst_RAM8 (
    .CLK  (clk),
    .EN0  (ram_en),
    .WE0  (ram_we),
    .A0   (ram_addr),
    .Di0  (ram_data_i),
    .Do0  (ram_data_o)
);

MBIST inst_MBIST (
    .clk(clk),
    .rst_n(rst_n),
    .mbist_en(mbist_en),
    .ram_data_o(ram_data_o),
    .ram_we(ram_we),
    .ram_addr(ram_addr),
    .ram_data_i(ram_data_i),
    .ecc_bypass(ecc_bypass),
    .results(results)
);

wire _unused = &{ena, uio_in, 1'b0};


//ECC.v
//ECC inst_ECC (
//	.TBD
//);

endmodule
