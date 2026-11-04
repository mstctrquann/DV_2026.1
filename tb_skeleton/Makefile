# Khung chạy bài tập tuần 6 (ET4356). DUT mã hoá (../dut/*_v<V>.vp) chỉ biên dịch được bằng QuestaSim.
#   make add NBIT=16 V=2  : adder_v2, N = 16; log ở run/add16_v2.log
#   make mul NBIT=8 V=3   : mult_serial_v3 và mult_booth_v3, N = 8; log ở run/mul8_v3.log
#   make all              : 4 phiên bản × (adder N = 4, 8, 16, 32, 64; bộ nhân N = 4, 8, 16)
#   make lint             : kiểm tra testbench chỉ dùng Verilog-2001 (Icarus -g2001 với stubs.v, không cần DUT)
SHELL := /bin/bash
NBIT ?= 8
V    ?= 1
SEED ?= 1
DUT_ADD = ../dut/adder_v$(V).vp
DUT_MUL = ../dut/mult_serial_v$(V).vp ../dut/mult_booth_v$(V).vp

.PHONY: add mul all lint clean
add:
	@mkdir -p run
	vlog -work run/work_add$(NBIT)_v$(V) +define+NBIT=$(NBIT) +define+SEED=$(SEED) $(DUT_ADD) tb_adder_top.v > run/add$(NBIT)_v$(V).build.log 2>&1
	vsim -c -work run/work_add$(NBIT)_v$(V) tb_adder_top -do "run -all; quit -f" | tee run/add$(NBIT)_v$(V).log

mul:
	@mkdir -p run
	vlog -work run/work_mul$(NBIT)_v$(V) +define+NBIT=$(NBIT) +define+SEED=$(SEED) $(DUT_MUL) tb_mult_top.v > run/mul$(NBIT)_v$(V).build.log 2>&1
	vsim -c -work run/work_mul$(NBIT)_v$(V) tb_mult_top -do "run -all; quit -f" | tee run/mul$(NBIT)_v$(V).log

all:
	for v in 1 2 3 4; do \
	  for n in 4 8 16 32 64; do $(MAKE) add NBIT=$$n V=$$v; done; \
	  for n in 4 8 16; do $(MAKE) mul NBIT=$$n V=$$v; done; \
	done

lint:
	@mkdir -p run
	iverilog -g2001 -s tb_adder_top -o run/lint_add.vvp stubs.v tb_adder_top.v
	iverilog -g2001 -s tb_mult_top  -o run/lint_mul.vvp stubs.v tb_mult_top.v
	@echo "lint OK: Verilog-2001"

clean:
	rm -rf run
