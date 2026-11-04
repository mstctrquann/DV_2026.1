# Makefile cho DoTruongQuan_20233592_BTTuan6
# Chay tren he thong co iverilog (de lint) va QuestaSim/ModelSim (de mo phong .vp)

SHELL := /bin/bash
NBIT ?= 8
V    ?= 1
SEED ?= 1
DUT_DIR = ../../dut
DUT_ADD = $(DUT_DIR)/adder_v$(V).vp
DUT_MUL = $(DUT_DIR)/mult_serial_v$(V).vp $(DUT_DIR)/mult_booth_v$(V).vp

.PHONY: add mul all lint clean

add:
	@mkdir -p ../run ../log
	vlog -work ../run/work_add$(NBIT)_v$(V) +define+NBIT=$(NBIT) +define+SEED=$(SEED) $(DUT_ADD) tb_adder_top.v > ../run/add$(NBIT)_v$(V).build.log 2>&1
	vsim -c -work ../run/work_add$(NBIT)_v$(V) tb_adder_top -do "run -all; quit -f" | tee ../log/add$(NBIT)_v$(V).log

mul:
	@mkdir -p ../run ../log
	vlog -work ../run/work_mul$(NBIT)_v$(V) +define+NBIT=$(NBIT) +define+SEED=$(SEED) $(DUT_MUL) tb_mult_top.v > ../run/mul$(NBIT)_v$(V).build.log 2>&1
	vsim -c -work ../run/work_mul$(NBIT)_v$(V) tb_mult_top -do "run -all; quit -f" | tee ../log/mul$(NBIT)_v$(V).log

all:
	for v in 1 2 3 4; do \
	  for n in 4 8 16 32 64; do $(MAKE) add NBIT=$$n V=$$v; done; \
	  for n in 4 8 16; do $(MAKE) mul NBIT=$$n V=$$v; done; \
	done

lint:
	@mkdir -p ../run
	iverilog -g2001 -s tb_adder_top -o ../run/lint_add.vvp ../../tb_skeleton/stubs.v tb_adder_top.v
	iverilog -g2001 -s tb_mult_top  -o ../run/lint_mul.vvp ../../tb_skeleton/stubs.v tb_mult_top.v
	@echo "lint OK: Verilog-2001"

clean:
	rm -rf ../run
