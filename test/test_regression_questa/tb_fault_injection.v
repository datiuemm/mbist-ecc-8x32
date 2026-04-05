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
    wire        ram_en;

    integer pass_count;
    integer fail_count;

    //////////////////////////////////////////////////
    // DUT
    //////////////////////////////////////////////////
    MBIST dut (
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

    //////////////////////////////////////////////////
    // RAM
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
    // START MBIST
    //////////////////////////////////////////////////
    task start_mbist;
    begin
        rst_n    = 0;
        mbist_en = 0;
        #20;
        rst_n    = 1;
        #20;
        @(posedge clk);
        mbist_en = 1;
    end
    endtask

    //////////////////////////////////////////////////
    // FAULT INJECTION
    //////////////////////////////////////////////////
    task inject_fault(input [39:0] fault_data);
    begin
        wait(dut.check_pipe[0] == 1'b1);
        force ram_data_o = fault_data;
        repeat(3) @(posedge clk);
        release ram_data_o;
    end
    endtask

    //////////////////////////////////////////////////
    // RESULT CHECKER
    //////////////////////////////////////////////////
    task check_result(input [127:0] test_name);
    begin
        wait(dut.state == 3'd7);

        if (dut.fail) begin
            $display("[PASS] %s detected fault correctly", test_name);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] %s was NOT detected", test_name);
            fail_count = fail_count + 1;
        end

        #20;
    end
    endtask

    //////////////////////////////////////////////////
    // DEBUG MONITOR
    //////////////////////////////////////////////////
    initial begin
        $display("\n---------------------------------------------------------------");
        $display(" Time   State Addr   WE      Data_Out        Fail");
        $display("---------------------------------------------------------------");

        forever begin
            @(posedge clk);
            #1;

            if (!ram_en)
                $display("%8t %2d    %1d   %5b   -----------   %1b",
                         $time,
                         dut.state,
                         ram_addr,
                         ram_we,
                         dut.fail);

            else if (^ram_data_o === 1'bX)
                $display("%8t %2d    %1d   %5b   XXXXXXXXXX    %1b",
                         $time,
                         dut.state,
                         ram_addr,
                         ram_we,
                         dut.fail);

            else
                $display("%8t %2d    %1d   %5b   %010h    %1b",
                         $time,
                         dut.state,
                         ram_addr,
                         ram_we,
                         ram_data_o,
                         dut.fail);
        end
    end

    //////////////////////////////////////////////////
    // DUMP
    //////////////////////////////////////////////////
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0,tb);
    end

    //////////////////////////////////////////////////
    // MAIN TEST
    //////////////////////////////////////////////////
    initial begin
        clk = 0;
        pass_count = 0;
        fail_count = 0;

        ////////////////////////////////////////////////
        // SAF
        ////////////////////////////////////////////////
        $display("\n=== Running SAF test ===");
        start_mbist();
        inject_fault(40'h0000000020);
        check_result("SAF");

        ////////////////////////////////////////////////
        // TF
        ////////////////////////////////////////////////
        $display("\n=== Running TF test ===");
        start_mbist();
        inject_fault(40'hFFFFFFFFFB);
        check_result("TF");

        ////////////////////////////////////////////////
        // AF
        ////////////////////////////////////////////////
        $display("\n=== Running AF test ===");
        start_mbist();
        inject_fault(40'hAAAAAAAAAA);
        check_result("AF");

        ////////////////////////////////////////////////
        // CF
        ////////////////////////////////////////////////
        $display("\n=== Running CF test ===");
        start_mbist();
        inject_fault(40'h0000000001);
        check_result("CF");

        ////////////////////////////////////////////////
        // FINAL SUMMARY
        ////////////////////////////////////////////////
        $display("\n======================================");
        $display("         FINAL TEST SUMMARY");
        $display("======================================");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);

        if (fail_count == 0)
            $display("[TB RESULT] ALL TESTS PASSED");
        else
            $display("[TB RESULT] SOME TESTS FAILED");

        $display("======================================\n");

        #100;
        $finish;
    end

endmodule