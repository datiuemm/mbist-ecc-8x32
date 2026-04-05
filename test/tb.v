`default_nettype none
`timescale 1ns / 1ps

module tb ();

  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  tt_um_datiuemm dut (
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (ena),
      .clk    (clk),
      .rst_n  (rst_n)
  );

  reg        tb_mbist_fi_en;
  reg [2:0]  tb_mbist_fi_addr;
  reg [39:0] tb_mbist_fi_data;

  reg        tb_ecc_fi_en;
  reg [39:0] tb_ecc_fi_data;

  reg        tb_ecc_enc_en;
  reg [31:0] tb_ecc_enc_data_in;

  wire [2:0]  tb_mbist_state;
  wire [2:0]  tb_mbist_check_pipe;
  wire [31:0] tb_ecc_decoded_data;
  wire [38:0] tb_ecc_encoded_data;

`ifndef GL_TEST
  assign tb_mbist_state = dut.inst_MBIST.state;
  assign tb_mbist_check_pipe = dut.inst_MBIST.check_pipe;
  assign tb_ecc_decoded_data = dut.ecc_decoded_data;
  assign tb_ecc_encoded_data = dut.ecc_encoded_data;

  always @(posedge clk) begin
      if (tb_mbist_fi_en) begin
          dut.inst_RAM8.RAM[tb_mbist_fi_addr] <= tb_mbist_fi_data;
      end
  end

  always @(*) begin
      if (tb_ecc_fi_en) begin
          force dut.ram_data_o = tb_ecc_fi_data;
      end else begin
          release dut.ram_data_o;
      end
  end

  always @(*) begin
      if (tb_ecc_enc_en) begin
          force dut.ram_data_i = {8'b0, tb_ecc_enc_data_in};
      end else begin
          release dut.ram_data_i;
      end
  end
`else
  assign tb_mbist_state = 3'b0;
  assign tb_mbist_check_pipe = 3'b0;
  assign tb_ecc_decoded_data = 32'b0;
  assign tb_ecc_encoded_data = 39'b0;
`endif

endmodule
