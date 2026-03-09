`default_nettype none
//Don't compile this file, simulation only
module RAM8 (
    input  wire        CLK,
    input  wire        EN0,
    input  wire [4:0]  WE0,
    input  wire [2:0]  A0,
    input  wire [39:0] Di0,
    output reg  [39:0] Do0
);

    reg [39:0] mem [0:7];

    always @(posedge CLK) begin
        if (EN0) begin
            mem[A0] <= Di0;
            Do0 <= mem[A0];
        end
    end

endmodule
