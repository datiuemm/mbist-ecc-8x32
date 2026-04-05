
/*
 * Copyright (c) 2024 Dat Dinh Trong
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_datiuemm (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

//---------------------------------------------------------------------
// Parameter and internal wire
//---------------------------------------------------------------------

parameter NUM_BIT_OF_MODE = 0;

wire [NUM_BIT_OF_MODE:0] mbist_mode;
assign mbist_mode = ui_in[NUM_BIT_OF_MODE:0];

//---------------------------------------------------------------------
// Internal signals
//---------------------------------------------------------------------

wire mbist_en;
assign mbist_en = mbist_mode;

wire [4:0]  ram_we;
wire [2:0]  ram_addr;
wire [39:0] ram_data_i;
wire [39:0] ram_data_o;

wire [38:0] ecc_encoded_data;
wire [39:0] ram_write_data;

wire [31:0] ecc_decoded_data;
wire        ecc_bypass;
wire [2:0]  results;
wire        ram_en;

wire sb_err;
wire db_err;
wire sb_fix;

assign ram_write_data = ecc_bypass ? ram_data_i : {1'b0, ecc_encoded_data};

//---------------------------------------------------------------------
// Output assignment
//---------------------------------------------------------------------

assign uo_out[7]   = sb_fix;
assign uo_out[6]   = db_err;
assign uo_out[5]   = sb_err;
assign uo_out[4]   = ecc_bypass;
assign uo_out[3]   = ram_en;
assign uo_out[2:0] = results;

assign uio_out = 8'b0;
assign uio_oe  = 8'h00;

//---------------------------------------------------------------------
// RAM instance
//---------------------------------------------------------------------

RAM8 inst_RAM8 (
    .CLK  (clk),
    .EN0  (ram_en),
    .WE0  (ram_we),
    .A0   (ram_addr),
    .Di0  (ram_write_data),
    .Do0  (ram_data_o)
);

//---------------------------------------------------------------------
// MBIST instance
//---------------------------------------------------------------------

MBIST inst_MBIST (
    .clk(clk),
    .rst_n(rst_n),
    .mbist_en(mbist_en),
    .ram_data_o(ram_data_o),
    .ram_en(ram_en),
    .ram_we(ram_we),
    .ram_addr(ram_addr),
    .ram_data_i(ram_data_i),
    .ecc_bypass(ecc_bypass),
    .results(results)
);

//---------------------------------------------------------------------
// ECC encoder
//---------------------------------------------------------------------

ecc_enc #(
    .K(32)
) inst_ecc_enc (
    .ecc_bypass_i(ecc_bypass),
    .d_i(ram_data_i[31:0]),
    .q_o(ecc_encoded_data),
    .p_o(),
    .p0_o()
);

//---------------------------------------------------------------------
// ECC decoder
//---------------------------------------------------------------------

ecc_dec #(
    .K(32),
    .LATENCY(0)
) inst_ecc_dec (
    .rst_ni(rst_n),
    .clk_i(clk),
    .clkena_i(1'b1),
    .ecc_bypass_i(ecc_bypass),
    .d_i(ram_data_o[38:0]),
    .q_o(ecc_decoded_data),
    .syndrome_o(),
    .sb_err_o(sb_err),
    .db_err_o(db_err),
    .sb_fix_o(sb_fix)
);

//---------------------------------------------------------------------
// Unused signals
//---------------------------------------------------------------------

wire _unused = &{ena, uio_in, ui_in[7:1], ecc_decoded_data, 1'b0};

endmodule

