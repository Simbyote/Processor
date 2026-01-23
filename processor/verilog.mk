# System Variables
IVERILOG = iverilog
SIMULATOR = vvp
.DEFAULT_GOAL := help

# Overhead Directories
CURR_DIR = $(shell pwd)
SRC_DIR = $(CURR_DIR)/src
TEST_DIR = $(CURR_DIR)/tb
OUT_DIR = $(CURR_DIR)/out

## Output Directories
SIM_DIR = $(OUT_DIR)/out
WAVE_DIR = $(OUT_DIR)/sim

# Recursively gather all SystemVerilog files in src/
SRC_FILES = $(shell find $(SRC_DIR) -type f -name "*.sv")
TB_FILES = $(shell find $(TEST_DIR) -type f -name "*.sv")

# Simulation targets
SIMULATIONS = $(patsubst $(TEST_DIR)/%.sv, $(SIM_DIR)/%.out, $(TB_FILES))

# Rules for each target
.PHONY: help all run clean

# Default Rule
help:	# Display available targets
	@echo "Targets:"
	@echo "  all      - Build all simulation targets"
	@echo "  build    - Create output directories"
	@echo "  run      - Run all simulations and generate VCD files"
	@echo "  clean    - Remove all output files"

all: build $(SIMULATIONS) run

# Build Rule
build:
	mkdir -p $(WAVE_DIR) $(SIM_DIR)

# Build the simulation targets
$(SIM_DIR)/%.out: $(TEST_DIR)/%.sv $(SRC_FILES)
	$(IVERILOG) -g2012 -o $@ $(SRC_FILES) $<

# Run all the simulations
run: $(SIMULATIONS)
	for sim in $^; do \
		$(SIMULATOR) $$sim; \
	done
	mv *.vcd $(WAVE_DIR)

# Clean up the output directory
clean:
	rm -rf $(OUT_DIR)