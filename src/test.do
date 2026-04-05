vlib work

vlog MBIST.v
vlog -sv RAM8.v
vlog -sv ecc_enc.sv
vlog -sv ecc_dec.sv
vlog project.v

vsim -voptargs=+acc  tt_um_datiuemm
