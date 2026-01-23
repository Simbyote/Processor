# Simplistic Processing Engine
## Table of Contents

---
# Overview
The SPE will be a processor that contains a:
- Matrix ALU
- Integer ALU
- SPI Master Module
- Instruction Fetch
- Execution,
- Memory FSM 

### Matrix Unit
The matrix unit will perform matrix multiplication, scalar multiplication, subtraction, addition, and transposition.

### Top Module Unit
The top module will tie all the pieces together.

### Testbenching
A testbench will drive the master clock and reset, a testing module will
be added to make certain that the outputs properly perform all tasks.
Following a reset, the CPU will request the first instruction from the 
ROM and begin execution of the program.

---
# Project Details
The registers mentioned in this document are internal processor 
registers, with a reasonable justification for the number of registers 
used.

### Requirements
- The processor **must** be able to execute Branches.
- The processor **must** communicate with the SPI Master Module.

- Matrices will be 4x4 16 bit deep.

- Matrix multiplication will multiply two 4x4 matrices and return an
appropriate size matrix.

- Scalar multiplication is multiplying a matrix by a single number.

- Add and subtract will add or subtract two 4x4 matrices.

- Transpose will flip a matrix along its diagonal.

## Architecture
![System Architecture](docs/figs/arch.png "System Architecture")

The system is architected to be 256 bits.


## Memory Organization
- Memory is to be 256 bits wide and 256 bit aligned. Note that the lower
7 bits are *not* on the address bus.

- Instruction memory is only limited to user utilization.

- The table below shows the organization of memory mapping.

| Memory Location | Module                  |
|-----------------|-------------------------|
| 0000h           | Main Memory             |
| 1000h           | Instruction Memory      |
| 2000H           | Matrix ALU              |
| 3000H           | Integer ALU             |
| 4000H           | Internal Register Block |
| 5000H           | Execution Engine        |
| 6000H           | SPI Master Module       |

- The address bus will be 16 bits.

| Module Address | Module Offset                |
|----------------|------------------------------|
| 15 14 13 12    | 11 10 9 8 7 6 5 4 3 2 1 0    |

### Main Memory Organization
| Memory Location | Information | Memory Location | Information     |
|-----------------|-------------|-----------------|-----------------|
| 0000h           | Matrix 1    | 000Ah           | Integer Data 1  |
| 0001h           | Matrix 2    | 000Bh           | Integer Data 2  |
| 0002h           | Result 1    | 000Ch           | Integer Results |
| 0003h           | Result 2    | 000Dh           | Integer Results |
| 0004h           | Result 3    | 000Eh           | Integer Results |
| 0005h           | Result 4    | 000Fh           | Integer Results |
| 0006h           | Result 5    | 0010h           | Integer Results |
| 0007h           | Result 6    | 0011h           | Integer Results |
| 0008h           | Result 7    | 0012h           | Integer Results |
| 0009h           | Result 8    | 0013h           | Integer Results |

- Matrix 1 is at address 0
- Matrix 2 is at address 1

---
# How It Operates
- The test bench will start the system clock and toggle reset.
- Execution engine will fetch the first opcode from instruction memory 
and begin execution.
- The execution engine will direct the transfer of data between the
memory, the appropriate matrix modules, and memory.
- The execution engine will continue executing programs until it finds
a `STOP` opcode.
- Matrix ALU and integer ALU will *not* require overflow (optional but
not required).

## Project Instruction Set
The instruction set will be a subset of the following table:

| Instruction   | Opcode    | Destination   | Source 1  | Source 2  |
|---------------|-----------|---------------|-----------|-----------|
| Stop          | FFh       | 00            | 00        | 00        |
| MMult1        | 00h       | Reg/Mem       | Reg/Mem   | Reg/Mem   |
| Madd          | 03h       | Reg/Mem       | Reg/Mem   | Reg/Mem   |
| Msub          | 04h       | Reg/Mem       | Reg/Mem   | Reg/Mem   |
| Mtranspose    | 05h       | Reg/Mem       | Reg/Mem   | Reg/Mem   |
| MScale        | 06h       | Reg/Mem       | Reg/Mem   | Reg/Mem   |
| MScalelmm     | 07h       | Reg/Mem       | Reg/Mem   | Reg/Mem   |
| IntAdd        | 10h       | Reg/Mem       | Reg/Mem   | Reg/Mem   |
| IntSub        | 11h       | Reg/Mem       | Reg/Mem   | Reg/Mem   |
| IntMult       | 12h       | Reg/Mem       | Reg/Mem   | Reg/Mem   |
| IntDiv        | 13h       | Reg/Mem       | Reg/Mem   | Reg/Mem   |
| BNE           | 20h       | Offset        | Reg 1     | Reg 2     |
| BEQ           | 21h       | Offset        | Reg 1     | Reg 2     |
| BLT           | 22h       | Offset        | Reg 1     | Reg 2     |
| BGT           | 23h       | Offset        | Reg 1     | Reg 2     |
| SPI           | 30h       | Reg/Mem       | Offset    | Data      |

---
# CPU Operation
- Matrix Operations:

1. Add the first matrix to the second matrix and store the result in
memory.
2. Scale the first matrix by the value in location 0x0A and store in 
memory.
3. Add the 16-bit numbers at the memory location 0x0a to location 0x0b
and store them in a temporary register.
4. Subtract the first matrix from the result in step 2 and store the 
result somewhere else in memory.
5. If results from step 4 is less than the result from step 2, go to
step 7.
6. Transpose the result from step 1 and store it in memory.
7. If the memory location 5 != to location 8, go to step 6.
8. Scale immediate result in step 2 by the data in the instruction and
store in a temporary register.
9. Multiply the result from step 4 by the result in step 5, storing the
result in memory. 

- Integer operations: 
    - Note that those which are in memory locations 0 and 1—are 
assumed to only use the LSW (first 16 bits) of the 256 data located at 0 
and 1

10. Multiply the integer value in memory location 0 to memory location 1.
Store it in memory location 0x0A.
11. Subtract the integer value in memory location 1 from memory location 0x0A. Store it in a register.
12. Divide the result from step 8 by the result from step 9 and store
the result in location 0x0B.

- SPI Operations:
13. Copy the first 8 locations in the main memory to the SPI module. Will
be done in a series of instructions.

---
# Testing
A top module and testbench will be created to grade the modules 
developed. The top module will have the same interface as the IO. The order in which operations are executed will be changing to verify the
correctness of the system.

---

# Repository Layout
Processor
├── Makefile
└── processor
    ├── verilog.mk
    ├── docs
    │   ├── latex.mk
    │   ├── figs
    │   ├── tex1
    │   ├── tex2
    │   └── ...
    ├── src
    │   ├── alu
    │   │   └── int.sv
    │   ├── cpu
    │   │   ├── fetch.sv
    │   │   ├── fsm.sv
    │   │   ├── opmux.sv
    │   │   ├── pc.sv
    │   │   └── reg.sv
    │   ├── io
    │   │   └── io.sv
    │   ├── mem
    │   │   ├── decode.sv
    │   │   ├──instr.sv
    │   │   └── mem.sv
    │   └── top.sv
    └── tb
        └── tb.sv

- The project is split into its parts:
    - `processor` contains the main modules of the project.
    - `tb` contains the testbench for the project.
- Each section of language of code—Verilog or LaTeX—contains their own Makefile
that drive the build process. The tex files are commanded by the `latex.mk` file
and the verilog files are commanded by the `verilog.mk` file. Two commands can
proceed the main build process:
    - `DIR` is the path to the current directory of the Makefile. This is used in
    conjunction with the `latex.mk` file to build the documentation per directory.
    - `DATA` is the path to the data files for any generated Verilog simulations—in
    conjunction with the `verilog.mk` file. These are processed using gtkwave.

# Build & Run
- The Makefile can be used to build and compile any section of the project; either
the processor or the documentation.

# License
Free access to this code is granted under the MIT license to any person
with a copy of this software and associated documentation files.