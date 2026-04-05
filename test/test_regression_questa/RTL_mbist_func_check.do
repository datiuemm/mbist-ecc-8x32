vlib work

vlog MBIST.v
vlog RAM8.v
vlog RTL_mbist_func_check.v

vsim -voptargs=+acc tb

add wave -r *

run -all
