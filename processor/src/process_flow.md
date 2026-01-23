# 1. Address decode + bus contract (1st)
- Implement `decode.sv` for addr[15:12] to select: 
    - main RAM, 
    - instr ROM, 
    - ALUs, 
    - reg block,
    - execution engine,
    - SPI.
- Define a single read/write handshake for all memory-mapped devices.

# Instruction ROM + fetch + PC (2nd)
- Implement `pc.sv` to work with ROM at 0x1000.
- Minimally implement a small program; emulate no-op moves into a 
`STOP (FFh)` instruction.

# Execution FSM skeleton (3rd)
- Implement `fsm.sv` to:
    - fetch instruction
    - decode opcode
    - do a single memory read or write micro-step
    - halt on STOP instruction

# Main RAM (4th)
- Implement `mem.sv` for 256-bit word, 16-bit address, lower 7 bits not 
on external bus.
- Validate progress by writing a small program to check correct flow:
    - store immediate -> load back -> branch test -> STOP

# Register block + Reg/Mem addressing (5th)
- Implement `reg.sv` for 16-bit registers.
- Allow any operand to be sourced from reg/memory without special cases.

# ALU & SPI Units (6th)
- Implement `alu.sv` for matrix and integer ALUs.
- Implement `spi.sv` for SPI module.