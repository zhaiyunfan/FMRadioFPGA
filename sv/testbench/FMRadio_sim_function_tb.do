setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -reportprogress 300 -work work ../iir.sv
vlog -reportprogress 300 -work work ../iir_top.sv
vlog -reportprogress 300 -work work iir_tb.sv

vlog -reportprogress 300 -work work ../gain.sv
vlog -reportprogress 300 -work work ../gain_top.sv
vlog -reportprogress 300 -work work gain_tb.sv

vlog -reportprogress 300 -work work ../fir.sv
vlog -reportprogress 300 -work work ../fir_top.sv
vlog -reportprogress 300 -work work fir_tb.sv

vlog -reportprogress 300 -work work ../fir_cmplx.sv
vlog -reportprogress 300 -work work ../fir_cmplx_top.sv
vlog -reportprogress 300 -work work fir_cmplx_tb.sv

vlog -reportprogress 300 -work work ../demodulate.sv
vlog -reportprogress 300 -work work ../demod_top.sv
vlog -reportprogress 300 -work work demod_tb.sv

vlog -reportprogress 300 -work work ../div.sv
vlog -reportprogress 300 -work work div_tb.sv

# vsim -voptargs=+acc work.iir_tb
 vsim -voptargs=+acc work.gain_tb
# vsim -voptargs=+acc work.fir_tb
# vsim -voptargs=+acc work.fir_cmplx_tb
# vsim -voptargs=+acc work.demod_tb
# vsim -voptargs=+acc work.div_tb


# add wave -position insertpoint sim:/iir_tb/dut/*
# add wave -position insertpoint sim:/iir_tb/dut/fifo_in/*
# add wave -position insertpoint sim:/iir_tb/dut/iir_inst/*
# add wave -position insertpoint sim:/iir_tb/dut/fifo_out/*

#add wave -position insertpoint sim:/gain_tb/dut/*
#add wave -position insertpoint sim:/gain_tb/dut/input_fifo/*
#add wave -position insertpoint sim:/gain_tb/dut/gain_inst/*
#add wave -position insertpoint sim:/gain_tb/dut/output_fifo/*

# add wave -position insertpoint sim:/fir_tb/dut/*

#add wave -position insertpoint sim:/fir_cmplx_tb/dut/*

#add wave -position insertpoint sim:/demod_tb/dut/*

#add wave -position insertpoint sim:/div_tb/dut/*

run -all