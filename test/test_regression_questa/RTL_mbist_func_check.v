`timescale 1ns/1ps

module tb;

    reg clk;
    reg rst_n;
    reg mbist_en;

    wire [2:0]  ram_addr;
    wire [39:0] ram_data_i;
    wire [39:0] ram_data_o;
    wire [4:0]  ram_we;
    wire        ecc_bypass;
    wire [2:0]  results;

    // RAM control
    wire ram_en; 

    //////////////////////////////////////////////////
    // DUT (MBIST Module)
    //////////////////////////////////////////////////
    MBIST dut (
        .clk(clk),
        .rst_n(rst_n),
        .ram_en(ram_en),
        .ram_data_o(ram_data_o),
        .ram_addr(ram_addr),
        .ram_data_i(ram_data_i),
        .mbist_en(mbist_en),
        .ram_we(ram_we),
        .ecc_bypass(ecc_bypass),
        .results(results)
    );

    //////////////////////////////////////////////////
    // RAM MODEL (8 words x 40 bits)
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
    // CLOCK GENERATOR
    //////////////////////////////////////////////////
    always #5 clk = ~clk;

    //////////////////////////////////////////////////
    // DEBUG MONITOR 
    //////////////////////////////////////////////////
    initial begin
        $display("\n----------------------------------------------------------------------------------------------------------");
        $display("   Time	EN	State	RAM_EN	RAM_Addr	Data_In	Data_Out	Results");
        $display("----------------------------------------------------------------------------------------------------------");
        
        //Little help from ChatGPT
        forever begin
            @(posedge clk);
            #1;
             // Delay 1ns để các tín hiệu Flip-flop ổn định
            $display("%8t	%1b	%1d	%1d	%1d	%010h	%010h	%1b",
                     $time, 
                     mbist_en, 
                     dut.state, 
                     ram_en,
                     ram_addr, 
                     ram_data_i, 
                     ram_data_o, 
                     results);
        end
    end

    //////////////////////////////////////////////////
    // TEST SEQUENCE
    //////////////////////////////////////////////////
    integer i;

    `ifdef FSDB
initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0, tb);
end
`endif

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        clk = 0;
        rst_n = 0;
        mbist_en = 0;
        #20 rst_n = 1;
        #40;

        $display("\n[TB] --- STARTING MARCH-C TEST ---");
        @(posedge clk);
        mbist_en <= 1'b1;
	
	
	//Pattern gen from ChatGPT for better view
        #10000;
        $display("\n-------------------------------------------------------");
        $display("[TB] --- MBIST FINISHED ---");
        if (dut.fail)
            $display("[RESULT] >>> TEST STATUS: FAILED <<< (Detected mismatch)");
        else
            $display("[RESULT] >>> TEST STATUS: PASSED <<< (All patterns matched)");
        $display("-------------------------------------------------------\n");

        #50;
        $finish;
    end

endmodule
