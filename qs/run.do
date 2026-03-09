vlib work

vlog MBIST.v
vlog RAM8.v
vlog tb.v

vsim -voptargs=+acc tb

# full probe tất cả signal
add wave -r *

run -all
