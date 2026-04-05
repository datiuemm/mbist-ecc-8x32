`timescale 1ns/1ps

module RTL_ECC_func_check;

parameter K = 8;
parameter m = 4;
parameter n = 12;

reg  [K-1:0] data_in;
reg          ecc_bypass_i;

wire [n:0]   enc_out;
wire [m:1]   p_o;
wire         p0_o;

reg          rst_ni;
reg          clk_i;
reg          clkena_i;

wire [K-1:0] q_o;
wire [m:0]   syndrome_o;
wire         sb_err_o;
wire         db_err_o;
wire         sb_fix_o;

integer errors;

ecc_enc uut_enc (
    .d_i(data_in),
    .ecc_bypass_i(ecc_bypass_i),
    .q_o(enc_out),
    .p_o(p_o),
    .p0_o(p0_o)
);

ecc_dec uut_dec (
    .rst_ni(rst_ni),
    .clk_i(clk_i),
    .clkena_i(clkena_i),
    .d_i(enc_out),
    .ecc_bypass_i(ecc_bypass_i),
    .q_o(q_o),
    .syndrome_o(syndrome_o),
    .sb_err_o(sb_err_o),
    .db_err_o(db_err_o),
    .sb_fix_o(sb_fix_o)
);

always #5 clk_i = ~clk_i;

task check_result;
input [7:0] expected;
begin
    #1;
    if (q_o !== expected || syndrome_o !== 0 || sb_err_o !== 0 || db_err_o !== 0) begin
        $display("FAIL: expected=%h got=%h syndrome=%b sb=%b db=%b",
                  expected,q_o,syndrome_o,sb_err_o,db_err_o);
        errors = errors + 1;
    end
    else begin
        $display("PASS: data=%h enc=%h dec=%h",
                  expected,enc_out,q_o);
    end
end
endtask

initial begin
    clk_i = 0;
    rst_ni = 0;
    clkena_i = 1;
    ecc_bypass_i = 0;
    errors = 0;

    #10 rst_ni = 1;

    data_in = 8'hA5;
    #10 check_result(8'hA5);

    data_in = 8'h3C;
    #10 check_result(8'h3C);

    data_in = 8'hF0;
    #10 check_result(8'hF0);

    data_in = 8'h55;
    #10 check_result(8'h55);

    if (errors == 0)
        $display("========== ALL TESTS PASSED ==========");
    else
        $display("========== TEST FAILED : %0d errors ==========", errors);

    $finish;
end

endmodule
