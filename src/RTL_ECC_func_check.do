vlib work

vlog ecc_enc.v
vlog ecc_dec.v
vlog RTL_ECC_func_check.v

vsim -voptargs=+acc work.RTL_ECC_func_check

add wave *

run -all
