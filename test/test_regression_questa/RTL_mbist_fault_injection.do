vlib work

vlog MBIST.v
vlog RAM8.v
vlog tb_fault_injection.v

vsim -voptargs=+acc tb

add wave -r *

run -all
