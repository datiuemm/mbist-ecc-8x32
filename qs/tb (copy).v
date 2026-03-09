`timescale 1ns/1ps

module tb;

reg clk;
reg rst_n;
reg [1:0] mbist_mode;

wire [2:0] ram_addr;
wire [39:0] ram_data_i;
wire [39:0] ram_data_o;
wire ecc_bypass;
wire [2:0] results;

// RAM control
wire ram_en;
assign ram_en = 1'b1;
wire [4:0] ram_we;

//////////////////////////////////////////////////
// DUT
//////////////////////////////////////////////////

MBIST dut (
    .clk(clk),
    .rst_n(rst_n),
    .mbist_mode(mbist_mode),
    .ram_data_o(ram_data_o),
    .ram_we(ram_we),
    .ram_addr(ram_addr),
    .ram_data_i(ram_data_i),
    .ecc_bypass(ecc_bypass),
    .results(results)
);

//////////////////////////////////////////////////
// RAM MODEL
//////////////////////////////////////////////////

RAM8 ram (
    .CLK(clk),
    .EN0(ram_en),
    .WE0(ram_we),
    .A0(ram_addr),
    .Di0(ram_data_i),
    .Do0(ram_data_o)
);

//////////////////////////////////////////////////
// CLOCK
//////////////////////////////////////////////////

always #5 clk = ~clk;

//////////////////////////////////////////////////
// TEST SEQUENCE
//////////////////////////////////////////////////

initial begin

    $dumpfile("tb.vcd");
    $dumpvars(0, tb);

    clk = 0;
    rst_n = 0;
    mbist_mode = 2'b00;

    #20
    rst_n = 1;

    ///////////////////////////////////////
    // NORMAL MODE
    ///////////////////////////////////////

    #20;
    mbist_mode = 2'b00;

    #50;

    ///////////////////////////////////////
    // START MARCH C
    ///////////////////////////////////////

    $display("Start MARCH-C test");

    mbist_mode = 2'b01;

    #1000;

    ///////////////////////////////////////
    // STOP MBIST
    ///////////////////////////////////////

    mbist_mode = 2'b00;

    #50;

    ///////////////////////////////////////
    // CHECK RESULT
    ///////////////////////////////////////

    $display("RESULTS = %b", results);

    if(results == 3'b011)
        $display("MBIST PASS");
    else
        $display("MBIST FAIL");

    #50;
    $finish;

end

endmodule
