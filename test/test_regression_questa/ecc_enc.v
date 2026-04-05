module ecc_enc #(
  parameter K       = 8,
  parameter P0_LSB  = 1,
  parameter m       = calculate_m(K),
  parameter n       = m + K
)
(
  input  [K-1:0] d_i,
  input          ecc_bypass_i,
  output [n:0]   q_o,
  output [m:1]   p_o,
  output         p0_o
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

function [n:1] store_dbits_in_codeword;
  input [K-1:0] d;
  integer bit_idx, cw_idx;
  begin
    store_dbits_in_codeword = {n{1'b0}};
    bit_idx = 0;
    for (cw_idx=1; cw_idx<=n; cw_idx=cw_idx+1)
      if (2**$clog2(cw_idx) != cw_idx) begin
        store_dbits_in_codeword[cw_idx] = d[bit_idx];
        bit_idx = bit_idx + 1;
      end
  end
endfunction

function [m:1] calculate_p;
  input [n:1] cw;
  integer p_idx, cw_idx;
  begin
    calculate_p = {m{1'b0}};
    for (p_idx=1; p_idx<=m; p_idx=p_idx+1)
      for (cw_idx=1; cw_idx<=n; cw_idx=cw_idx+1)
        if (|(2**(p_idx-1) & cw_idx))
          calculate_p[p_idx] = calculate_p[p_idx] ^ cw[cw_idx];
  end
endfunction

function [n:1] store_p_in_codeword;
  input [n:1] cw;
  input [m:1] p;
  integer i;
  begin
    store_p_in_codeword = cw;
    for (i=1; i<=m; i=i+1)
      store_p_in_codeword[2**(i-1)] = p[i];
  end
endfunction

wire [n:1] cw_w_dbits;
wire [n:1] cw;

assign cw_w_dbits = store_dbits_in_codeword(d_i);
assign p_o        = calculate_p(cw_w_dbits);
assign cw         = store_p_in_codeword(cw_w_dbits, p_o);
assign p0_o       = ^cw;

assign q_o = ecc_bypass_i ? {{(n+1-K){1'b0}}, d_i} :
             (P0_LSB ? {cw,p0_o} : {p0_o,cw});

endmodule
