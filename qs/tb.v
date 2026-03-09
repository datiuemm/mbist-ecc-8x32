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
    wire ram_en = 1'b1; 

    //////////////////////////////////////////////////
    // DUT (MBIST Module)
    //////////////////////////////////////////////////
    MBIST dut (
        .clk(clk),
        .rst_n(rst_n),
        .ram_data_o(ram_data_o),
        .ram_addr(ram_addr),
        .ram_data_i(ram_data_i),
        .mbist_en(mbist_en),
        .ram_we(ram_we),
        .ecc_bypass(ecc_bypass),
        .results(results)
    );

    //////////////////////////////////////////////////
    // RAM MODEL (Giả định 8 words x 40 bits)
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
    // DEBUG MONITOR (Bản nâng cấp)
    //////////////////////////////////////////////////
    initial begin
        $display("\n----------------------------------------------------------------------------------------------------------");
        $display("   Time    EN  State  RAM_Addr  local_addr  read_valid     Data_In      Data_Out    Fail");
        $display("----------------------------------------------------------------------------------------------------------");
        
        // Monitor đồng bộ với Clock để thấy đúng giá trị sau khi cập nhật
        forever begin
            @(posedge clk);
            #1; // Delay 1ns để các tín hiệu Flip-flop ổn định
            $display("%8t   %1b     %1d        %1d           %1d            %1b      %010h  %010h    %1b",
                     $time, 
                     mbist_en, 
                     dut.state, 
                     ram_addr, 
                     dut.local_addr,
                     dut.read_valid, 
                     ram_data_i, 
                     ram_data_o, 
                     dut.fail);
        end
    end

    //////////////////////////////////////////////////
    // TEST SEQUENCE
    //////////////////////////////////////////////////
    integer i;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        // 1. Khởi tạo RAM về 0 để tránh 'x'
        // for (i = 0; i < 8; i = i + 1) begin
        //     ram.RAM[i] = 40'h00_0000_0000;
        // end

        // 2. Reset hệ thống
        clk = 0;
        rst_n = 0;
        mbist_en = 0;
        #20 rst_n = 1;
        #40;

        // 3. Bắt đầu chạy MBIST
        $display("\n[TB] --- STARTING MARCH-C TEST ---");
        @(posedge clk);
        mbist_en <= 1'b1;

        // Đợi cho đến khi State chuyển sang DONE hoặc chạy đủ thời gian
        // Giả sử State 7 là DONE (bạn cần định nghĩa trong DUT)
        //wait(dut.state == 3'd4); // Đợi tới lúc chuyển sang W1 hoặc state kết thúc
        
        #1000;
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