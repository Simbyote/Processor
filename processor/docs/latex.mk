# Latex Makefile for DIGITAL IMAGE PROCESSING
# Only processes one tex file at a time (multiple tex files not supported)
SHELL := /bin/bash
.ONESHELL:	# Fail on error
.SHELLFLAGS := -euo pipefail -c
.DELETE_ON_ERROR:	# Delete the target upon failure
.DEFAULT_GOAL := help

# System variables
PDFLATEXFLAGS := -halt-on-error -file-line-error -interaction=nonstopmode
PDFLATEX ?= pdflatex
BIBTOOL ?= bibtex

# Initialize names and directories (Default directory is current directory of Makefile)
DIR?=.
OUT_DIR := $(DIR)/output
OUTNAME:=$(notdir $(OUT_DIR))
TEXS:=$(wildcard $(DIR)/*.tex)
TEXNAME?=none

# Are there any tex files?
ifeq ($(words $(TEXS)),0)
  $(error No *.tex file found in $(DIR))
endif
# Is there more than one tex file?
ifneq ($(word 2,$(TEXS)),)
	$(error Too many *.tex files found in $(DIR))
endif

# Set appropriate tex file if none is given
ifeq ($(TEXNAME),none)
	TEXFILE:=$(notdir $(firstword $(TEXS)))
	TEXNAME:=$(basename $(TEXFILE))
else
	TEXFILE  := $(TEXNAME).tex
endif

# Auto detection of bibtex files: checks for bib commands in the tex
BIBFLAG ?= auto
BIB_FILES := $(wildcard $(DIR)/*.bib)

# Rules for each target
.PHONY: all run clean

help:	# Display available targets
	@echo "Targets:"
	@echo "  run      - Setup temporary directory and build specified tex file. Upon failure, temp files are deleted"
	@echo "  build    - Build specified $(OUT_DIR)/"
	@echo "  clean    - Remove all outputs and temporary directory"


run: build	# Builds a specified dump directory and runs the tex file
# If a failure occurs in the trap, all temp files are deleted
	cd "$(DIR)"
	trap 's=$$?; echo "Build failed (exit $$s). Cleaning..."; \
	     rm -f "$(TEXNAME).pdf" *.{aux,log,out,toc,lof,lot,bbl,blg,bcf,run.xml} 2>/dev/null || true; \
	     exit $$s' ERR

	$(PDFLATEX) $(PDFLATEXFLAGS) $(TEXFILE)

# If there are bibtex files, run bibtex twice to ensure proper build
ifneq ($(strip $(BIB_FILES)),)
	$(BIBTOOL) $(TEXNAME)
	for i in 1 2; do \
		$(PDFLATEX) $(PDFLATEXFLAGS) $(TEXFILE); \
	done
endif

	$(PDFLATEX) $(PDFLATEXFLAGS) $(TEXFILE)

# After successful build, move temp files to dump directory
	mv -f *.{aux,log,out,toc,lof,lot,bbl,blg,bcf,run.xml} "$(OUTNAME)/" 2>/dev/null || true
	echo "Built $@"

build:	# Build specified dump directory
	mkdir -p $(OUT_DIR)

clean:	# Remove all outputs and temp directory
	rm -rf $(OUT_DIR)
	rm -f $(DIR)/*.{aux,log,out,toc,lof,lot,bbl,blg,bcf,run.xml,pdf}
