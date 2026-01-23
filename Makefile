DIR ?= .
DATA ?= .

.PHONY:
	tex tex.open tex.clean
	verilog verilog.clean verilog.sim

#####################################################################
# Project Commands
#####################################################################
# Help
help:
	@echo "Latex Configuration"
	$(MAKE) -C processor/docs -f latex.mk

	@echo "Verilog Configuration"
	$(MAKE) -C processor -f verilog.mk

# Latex
latex:
	$(MAKE) -C processor/docs -f latex.mk run DIR="$(DIR)"
latex.open:
	open processor/docs/$(DIR)
latex.clean:
	$(MAKE) -C processor/docs -f latex.mk clean DIR="$(DIR)"

# Verilog
verilog:
	$(MAKE) -C processor -f verilog.mk all
verilog.clean:
	$(MAKE) -C processor -f verilog.mk clean

# Simulation
verilog.sim:
	gtkwave processor/build/sim/$(DATA).vcd