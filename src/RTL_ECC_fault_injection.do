vlib work

vlog ecc_enc.v
vlog ecc_dec.v
vlog RTL_ECC_fault_injection.v

vsim -voptargs=+acc work.RTL_ECC_fault_injection

add wave *

run -all
