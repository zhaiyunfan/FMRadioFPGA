setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -reportprogress 300 -work work ../iir.sv
vlog -reportprogress 300 -work work ../iir_top.sv
vlog -reportprogress 300 -work work iir_tb.sv

vlog -reportprogress 300 -work work ../gain.sv
vlog -reportprogress 300 -work work ../gain_top.sv
vlog -reportprogress 300 -work work gain_tb.sv

# vsim -voptargs=+acc work.iir_tb
vsim -voptargs=+acc work.gain_tb

# add wave -position insertpoint sim:/iir_tb/dut/*
# add wave -position insertpoint sim:/iir_tb/dut/fifo_in/*
# add wave -position insertpoint sim:/iir_tb/dut/iir_inst/*
# add wave -position insertpoint sim:/iir_tb/dut/fifo_out/*

add wave -position insertpoint sim:/gain_tb/dut/*
add wave -position insertpoint sim:/gain_tb/dut/input_fifo/*
add wave -position insertpoint sim:/gain_tb/dut/gain_inst/*
add wave -position insertpoint sim:/gain_tb/dut/output_fifo/*

run -all