DIR ?= .
DATA ?= .

.DEFAULT_GOAL := help

.PHONY:
	tex tex.open tex.clean
	verilog verilog.clean verilog.sim

#####################################################################
# Project Commands
#####################################################################
# Help
help:
	@echo "Verilog Configuration"
	$(MAKE) -C processor -f verilog.mk

# Verilog
verilog:
	$(MAKE) -C processor -f verilog.mk all
verilog.clean:
	$(MAKE) -C processor -f verilog.mk clean

# Simulation
verilog.sim:
	gtkwave processor/build/sim/$(DATA).vcd