module ecc_dec #(
  parameter K       = 8,
  parameter LATENCY = 0,
  parameter P0_LSB  = 1,
  parameter m       = calculate_m(K),
  parameter n       = m + K
)
(
  input              rst_ni,
  input              clk_i,
  input              clkena_i,
  input      [n:0]   d_i,
  input              ecc_bypass_i,

  output reg [K-1:0] q_o,
  output reg [m:0]   syndrome_o,
  output reg         sb_err_o,
  output reg         db_err_o,
  output reg         sb_fix_o
);

function integer calculate_m;
  input integer k;
  integer m;
  begin
    m = 1;
    while (2**m < m+k+1)
      m = m + 1;
    calculate_m = m;
  end
endfunction

function [m:1] calculate_syndrome;
  input [n:0] cw;
  integer p_idx, cw_idx;
  begin
    calculate_syndrome = {m{1'b0}};
    for (p_idx=1; p_idx<=m; p_idx=p_idx+1)
      for (cw_idx=1; cw_idx<=n; cw_idx=cw_idx+1)
        if (|(2**(p_idx-1) & cw_idx))
          calculate_syndrome[p_idx] = calculate_syndrome[p_idx] ^ cw[cw_idx];
  end
endfunction

function [n:0] correct_codeword;
  input [n:0] cw;
  input [m:1] syndrome;
  begin
    correct_codeword = cw;
    if (syndrome != 0)
      correct_codeword[syndrome] = ~correct_codeword[syndrome];
  end
endfunction

function [K-1:0] extract_q;
  input [n:0] cw;
  integer bit_idx, cw_idx;
  begin
    extract_q = {K{1'b0}};
    bit_idx = 0;
    for (cw_idx=1; cw_idx<=n; cw_idx=cw_idx+1)
      if (2**$clog2(cw_idx) != cw_idx) begin
        extract_q[bit_idx] = cw[cw_idx];
        bit_idx = bit_idx + 1;
      end
  end
endfunction

function is_power_of_2;
  input integer arg;
  begin
    is_power_of_2 = (arg & (arg-1)) == 0;
  end
endfunction

function information_error;
  input [m:1] syndrome;
  begin
    information_error = |syndrome & !is_power_of_2(syndrome);
  end
endfunction

wire parity;
wire [m:1] syndrome;
wire [n:0] cw_fixed;
wire [n:0] d;
reg  [n:0] d_reg;
reg        parity_reg;
reg  [m:1] syndrome_reg;

wire [K-1:0] q;
wire sb_err;
wire db_err;
wire sb_fix;

assign d        = P0_LSB ? d_i : {d_i[n-1:0], d_i[n]};
assign parity   = ^d;
assign syndrome = calculate_syndrome(d);

generate
if (LATENCY > 1) begin
  always @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin
      d_reg        <= {(n+1){1'b0}};
      parity_reg   <= 1'b0;
      syndrome_reg <= {m{1'b0}};
    end else if (clkena_i) begin
      d_reg        <= d;
      parity_reg   <= parity;
      syndrome_reg <= syndrome;
    end
end else begin
  always @(*) begin
    d_reg        = d;
    parity_reg   = parity;
    syndrome_reg = syndrome;
  end
end
endgenerate

assign cw_fixed = correct_codeword(d_reg, syndrome_reg);
assign q        = ecc_bypass_i ? d_i[K-1:0] : extract_q(cw_fixed);

assign sb_err = ecc_bypass_i ? 1'b0 : (parity_reg & |syndrome_reg);
assign db_err = ecc_bypass_i ? 1'b0 : (~parity_reg & |syndrome_reg);
assign sb_fix = ecc_bypass_i ? 1'b0 : (sb_err & information_error(syndrome_reg));

generate
if (LATENCY > 0) begin
  always @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin
      q_o        <= {K{1'b0}};
      syndrome_o <= {(m+1){1'b0}};
      sb_err_o   <= 1'b0;
      db_err_o   <= 1'b0;
      sb_fix_o   <= 1'b0;
    end else if (clkena_i) begin
      q_o        <= q;
      syndrome_o <= P0_LSB ? {syndrome_reg, parity_reg} : {parity_reg, syndrome_reg};
      sb_err_o   <= sb_err;
      db_err_o   <= db_err;
      sb_fix_o   <= sb_fix;
    end
end else begin
  always @(*) begin
    q_o        = q;
    syndrome_o = P0_LSB ? {syndrome_reg, parity_reg} : {parity_reg, syndrome_reg};
    sb_err_o   = sb_err;
    db_err_o   = db_err;
    sb_fix_o   = sb_fix;
  end
end
endgenerate

endmodule
