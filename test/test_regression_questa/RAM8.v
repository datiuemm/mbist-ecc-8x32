/// sta-blackbox

`default_nettype wire

module RAM8 (
    input CLK,
    input [4:0] WE0,
    input EN0,
    input [2:0] A0,
    input [39:0] Di0,
    output reg [39:0] Do0
);

  reg [39:0] RAM[7:0];

  always @(posedge CLK)
    if (EN0) begin
      Do0 <= RAM[A0];

      if (WE0[0]) RAM[A0][7:0]   <= Di0[7:0];
      if (WE0[1]) RAM[A0][15:8]  <= Di0[15:8];
      if (WE0[2]) RAM[A0][23:16] <= Di0[23:16];
      if (WE0[3]) RAM[A0][31:24] <= Di0[31:24];
      if (WE0[4]) RAM[A0][39:32] <= Di0[39:32];

    end else begin
      Do0 <= 40'b0;
    end

endmodule
