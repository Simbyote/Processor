.DEFAULT_GOAL := help

# System variables
IVERILOG  = iverilog
SIMULATOR = vvp

# Directory variables
CURR_DIR  = $(shell pwd)
SRC_DIR   = $(CURR_DIR)/src
TB_DIR    = $(CURR_DIR)/tb
INC_DIR   = $(CURR_DIR)/inc

# Subdirectory variables
BUILD_DIR = $(CURR_DIR)/build
SIM_DIR   = $(BUILD_DIR)/out
WAVE_DIR  = $(BUILD_DIR)/sim

# Top file variables
TOP_FILE   = $(CURR_DIR)/top.sv
TOP_MODULE = top
TOP_OUT    = $(SIM_DIR)/top.out

# Source file variables
PKG_FILES = $(shell find $(INC_DIR) -type f -name "*.sv")
SRC_FILES = $(shell find $(SRC_DIR) -type f -name "*.sv")
TB_FILES  = $(shell find $(TB_DIR)  -type f -name "*.sv")

.PHONY: all help build run clean
help:
	@echo "Available targets:"
	@echo "  all    - Build and run the simulation"
	@echo "  build  - Compile the System Verilog source and testbench files"
	@echo "  run    - Execute the simulation"
	@echo "  clean  - Remove build artifacts"

all: build $(TOP_OUT) run

build:
	mkdir -p $(SIM_DIR) $(WAVE_DIR)

$(TOP_OUT): $(PKG_FILES) $(TOP_FILE) $(SRC_FILES) $(TB_FILES)
	$(IVERILOG) -g2012 -Wall -s $(TOP_MODULE) -o $@ \
		$(PKG_FILES) $(SRC_FILES) $(TB_FILES) $(TOP_FILE)


run: $(TOP_OUT)
	$(SIMULATOR) $<
	mv *.vcd $(WAVE_DIR)

clean:
	rm -rf $(BUILD_DIR)
