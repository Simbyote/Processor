# Simplistic Processing Engine

## Project Status & Integration Report, HDL 4321 Spring 2026

> **Current milestone:** Stage 1 (operand resolution) is complete and simulation-verified. Stage 2
> is designed but not in the submitted file due to an unresolved timing issue among current files.

> **Remaining work:** Implement the WRITEBACK sub-FSM, fix a memory write timing race blocking Stage 2.

---

## 1. Architecture Overview

Refer to the README for a high-level overview of the project.

---

## 2. Completed & Verified Modules

| Module               | Status      | Description                                                                                                             |
|----------------------|-------------|--------------------------------------------------------------------------------------------------------------------------|
| Execution FSM        | Verified    | Top-level six-state FSM. Staged development documented in `fsm.sv` header.                                              |
| Fetch (`fetch.sv`)   | Verified    | Drives read via `pc_curr`; validates via Decode `hit`/`did`; latches instruction into register; asserts `fetch_valid`.  |
| Program Counter      | Verified    | Increments on `pc_we`; supports arbitrary `pc_next` for branch targets.                                                 |
| Decode (`decode.sv`) | Verified    | Decodes upper address nibble to module select (`did`) and asserts `hit` for read/write cycles.                          |
| Main Memory          | Verified    | 256-bit × 14 word synchronous RAM. Posedge write, posedge registered read.                                              |
| Matrix ALU           | Verified    | Negedge-clocked. Supports MAdd, MSub, MMult1, MScale, MScaleImm, MTranspose. Full 4×4 × 16-bit element datapath.        |
| Integer ALU          | Verified    | Negedge-clocked. Supports Iadd, Isub, Imult, Idiv on 16-bit LSW operands.                                               |
| Instruction ROM      | Verified    | Encodes 13 instructions matching the CPU operation sequence from the spec.                                              |
| EXECUTE sub-FSM      | Verified    | Six sub-states with correct 2-cycle memory read latency.                                                                |
| WRITEBACK sub-FSM    | Not Started | Skeleton only — advances PC with no computation. ALU dispatch, bus writes, and branching are not in the submitted file. |

---

## 3. Key Design Decisions & Implementation Notes

### 3.1 Staged FSM Development

The FSM was developed and verified in explicit stages to avoid compounding undiagnosed bugs as complexity grew. This is a rework of a previous attempt at the FSM where
complexity grew out of control and was scrapped. The following is a summary of the development process:

- **Stage 0:** Initial skeleton. Top-level states wired up, `WRITEBACK` advances PC with no actual computation.
- **Stage 1:** `EXECUTE` expanded into a six-sub-state machine. *(Current submitted state.)*
- **Stage 2:** `WRITEBACK` expanded into an eight-sub-state machine handling ALU dispatch, result read-back, register writes, memory writes, and branch evaluation.

### 3.2 Memory Read Latency

Both the FSM and Main Memory are clocked on `posedge Clk`. Non-blocking assignments in the FSM take effect after the clock edge, so the address and `nRead` driven at
posedge N are not seen by Main Memory until posedge N+1, at which point `MemToOutput` is latched. The FSM can only safely sample `Dataout` at posedge N+2. This 2-cycle
latency was discovered empirically from early simulation output and is the reason EXECUTE uses both a WAIT state and a READ state per operand.

```
EX_IDLE  (posedge N)    drive address + nRead=0
EX_WAIT1 (posedge N+1)  Main Memory latches MemToOutput — FSM idles
EX_READ1 (posedge N+2)  Dataout stable — FSM samples operand 1
(mirrored for the second operand via EX_WAIT2 and EX_READ2)
```

### 3.3 ALU Dispatch Protocol (designed, not in submitted files)

Both ALUs are negedge-clocked. A value the FSM drives at posedge N is stable before the negedge that follows, so each ALU register write takes only one FSM cycle. The
dispatch sequence for any ALU operation would be:

1. `WB_DISPATCH`: Write opcode to `AluStatusIn` at `0x2000` or `0x3000`.
2. `WB_ALU_S1`: Write resolved src1 to `Source1`.
3. `WB_ALU_S2`: Write resolved src2 to `Source2`.
4. `WB_ALU_TRIG`: Write trigger to `ALU_Result` offset; ALU computes on the next negedge.
5. `WB_ALU_WAIT`: Release `nWrite`; assert `nRead` for the Result register.
6. `WB_ALU_READ`: Sample `Dataout` and route to a register or memory destination.

### 3.4 Branch Handling (designed, not in submitted files)

Branching is evaluated directly from the two resolved operands in `WB_DISPATCH`. The branch offset is either a sign-extended 8-bit immediate from the `dest` field or
the lower 16 bits of an internal register. The target address is `pc_inc + offset`. If no branch is taken, `pc_next` is set to `pc_inc`.

### 3.5 Bus Drive Architecture (designed, not in submitted files)

The current file holds the bus at `'z` permanently (`assign Dataout = 'z`). The Stage 2 design replaces this with two registered signals — `bus_out` and `bus_drive` —
gated as `assign Dataout = bus_drive ? bus_out : 'z`, releasing the bus during read cycles so memory and ALU modules can drive it.

---

## 4. Simulation Transcript

Full program execution with the Stage 1 FSM. The grading testbench starts when `Bus=ff000000` appears at t=1215ns. Memory locations 2–6 and internal registers are wrong
because WRITEBACK does not yet write results.

### Instruction sequence (t=5–1205ns)

```
t=5    addr=xxxx nRead=x nWrite=x | Bus=xxxxxxxx | Instr=zzzzzzzz | Mem=xxxxxxxx
t=15   addr=0000 nRead=1 nWrite=1 | Bus=zzzzzzzz | Instr=zzzzzzzz | Mem=zzzzzzzz

-- I1: MAdd (03 02 00 01) — fetch + operand reads MEM[00], MEM[01] --
t=25   addr=1000 nRead=0 nWrite=1 | Bus=03020001 | Instr=03020001 | Mem=zzzzzzzz
t=65   addr=0000 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=75   addr=0000 nRead=0 nWrite=1 | Bus=000c0008 | Instr=zzzzzzzz | Mem=000c0008
t=85   addr=0001 nRead=0 nWrite=1 | Bus=000c0008 | Instr=zzzzzzzz | Mem=000c0008
t=95   addr=0001 nRead=0 nWrite=1 | Bus=00040009 | Instr=zzzzzzzz | Mem=00040009
t=105  addr=0001 nRead=1 nWrite=1 | Bus=zzzzzzzz | Instr=zzzzzzzz | Mem=zzzzzzzz

-- I2: MScale (06 03 00 0a) — fetch + operand reads MEM[00], MEM[0a] --
t=125  addr=1001 nRead=0 nWrite=1 | Bus=0603000a | Instr=0603000a | Mem=zzzzzzzz
t=165  addr=0000 nRead=0 nWrite=1 | Bus=00040009 | Instr=zzzzzzzz | Mem=00040009
t=175  addr=0000 nRead=0 nWrite=1 | Bus=000c0008 | Instr=zzzzzzzz | Mem=000c0008
t=185  addr=000a nRead=0 nWrite=1 | Bus=000c0008 | Instr=zzzzzzzz | Mem=000c0008
t=195  addr=000a nRead=0 nWrite=1 | Bus=00000003 | Instr=zzzzzzzz | Mem=00000003

-- I3: IntAdd (10 10 0a 0b) — fetch + operand reads MEM[0a]=3, MEM[0b]=0xc --
t=225  addr=1002 nRead=0 nWrite=1 | Bus=10100a0b | Instr=10100a0b | Mem=zzzzzzzz
t=265  addr=000a nRead=0 nWrite=1 | Bus=00000003 | Instr=zzzzzzzz | Mem=00000003
t=275  addr=000a nRead=0 nWrite=1 | Bus=00000003 | Instr=zzzzzzzz | Mem=00000003
t=285  addr=000b nRead=0 nWrite=1 | Bus=00000003 | Instr=zzzzzzzz | Mem=00000003
t=295  addr=000b nRead=0 nWrite=1 | Bus=0000000c | Instr=zzzzzzzz | Mem=0000000c

-- I4: MSub (04 04 03 00) --
t=325  addr=1003 nRead=0 nWrite=1 | Bus=04040300 | Instr=04040300 | Mem=zzzzzzzz
t=365  addr=0003 nRead=0 nWrite=1 | Bus=0000000c | Instr=zzzzzzzz | Mem=0000000c
t=375  addr=0003 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=385  addr=0000 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=395  addr=0000 nRead=0 nWrite=1 | Bus=000c0008 | Instr=zzzzzzzz | Mem=000c0008

-- I5: BLT (22 01 04 03) --
t=425  addr=1004 nRead=0 nWrite=1 | Bus=22010403 | Instr=22010403 | Mem=zzzzzzzz
t=465  addr=0004 nRead=0 nWrite=1 | Bus=000c0008 | Instr=zzzzzzzz | Mem=000c0008
t=475  addr=0004 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=485  addr=0003 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=495  addr=0003 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000

-- I6: MTranspose (05 05 02 00) --
t=525  addr=1005 nRead=0 nWrite=1 | Bus=05050200 | Instr=05050200 | Mem=zzzzzzzz
t=565  addr=0002 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=575  addr=0002 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=585  addr=0000 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=595  addr=0000 nRead=0 nWrite=1 | Bus=000c0008 | Instr=zzzzzzzz | Mem=000c0008

-- I7: BEQ (21 81 08 05) --
t=625  addr=1006 nRead=0 nWrite=1 | Bus=21810805 | Instr=21810805 | Mem=zzzzzzzz
t=665  addr=0008 nRead=0 nWrite=1 | Bus=000c0008 | Instr=zzzzzzzz | Mem=000c0008
t=675  addr=0008 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=685  addr=0005 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=695  addr=0005 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000

-- I8: MScaleImm (07 11 03 08) --
t=725  addr=1007 nRead=0 nWrite=1 | Bus=07110308 | Instr=07110308 | Mem=zzzzzzzz
t=765  addr=0003 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=775  addr=0003 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=785  addr=0008 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=795  addr=0008 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000

-- I9: MMult (00 06 04 05) --
t=825  addr=1008 nRead=0 nWrite=1 | Bus=00060405 | Instr=00060405 | Mem=zzzzzzzz
t=865  addr=0004 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=875  addr=0004 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=885  addr=0005 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=895  addr=0005 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000

-- I10: IntMult (12 0a 01 00) --
t=925  addr=1009 nRead=0 nWrite=1 | Bus=120a0100 | Instr=120a0100 | Mem=zzzzzzzz
t=965  addr=0001 nRead=0 nWrite=1 | Bus=00000000 | Instr=zzzzzzzz | Mem=00000000
t=975  addr=0001 nRead=0 nWrite=1 | Bus=00040009 | Instr=zzzzzzzz | Mem=00040009
t=985  addr=0000 nRead=0 nWrite=1 | Bus=00040009 | Instr=zzzzzzzz | Mem=00040009
t=995  addr=0000 nRead=0 nWrite=1 | Bus=000c0008 | Instr=zzzzzzzz | Mem=000c0008

-- I11: IntSub (11 82 0a 01) --
t=1025 addr=100a nRead=0 nWrite=1 | Bus=11820a01 | Instr=11820a01 | Mem=zzzzzzzz
t=1065 addr=000a nRead=0 nWrite=1 | Bus=000c0008 | Instr=zzzzzzzz | Mem=000c0008
t=1075 addr=000a nRead=0 nWrite=1 | Bus=00000003 | Instr=zzzzzzzz | Mem=00000003
t=1085 addr=0001 nRead=0 nWrite=1 | Bus=00000003 | Instr=zzzzzzzz | Mem=00000003
t=1095 addr=0001 nRead=0 nWrite=1 | Bus=00040009 | Instr=zzzzzzzz | Mem=00040009

-- I12: IntDiv (13 0c 82 0a) --
t=1125 addr=100b nRead=0 nWrite=1 | Bus=130c820a | Instr=130c820a | Mem=zzzzzzzz
t=1175 addr=000a nRead=0 nWrite=1 | Bus=00040009 | Instr=zzzzzzzz | Mem=00040009
t=1185 addr=000a nRead=0 nWrite=1 | Bus=00000003 | Instr=zzzzzzzz | Mem=00000003

-- STOP fetch at t=1215, grading block fires, FSM halts --
t=1215 addr=100c nRead=0 nWrite=1 | Bus=ff000000 | Instr=ff000000 | Mem=zzzzzzzz
t=1245 addr=100c nRead=1 nWrite=1 | Bus=zzzzzzzz | Instr=ff000000 | Mem=zzzzzzzz
-- FSM holds in HALT for remainder of simulation --
```

### Memory dump & grading result (t=1205ns)

```
memory location 0  = 000e000c0008000d00080010000f0009000b000800060007000c0005000c0008  [Correct]
memory location 1  = 000a000500070009000c0004000e00020007000600070008000c000700040009  [Correct]
memory location 2  = 0000000000000000000000000000000000000000000000000000000000000000  [Wrong — no write]
memory location 3  = 0000000000000000000000000000000000000000000000000000000000000000  [Wrong — no write]
memory location 4  = 0000000000000000000000000000000000000000000000000000000000000000  [Wrong — no write]
memory location 5  = 0000000000000000000000000000000000000000000000000000000000000000  [Wrong — no write]
memory location 6  = 0000000000000000000000000000000000000000000000000000000000000000  [Wrong — no write]
memory location 7  = 0000000000000000000000000000000000000000000000000000000000000000  [Correct]
memory location 8  = 0000000000000000000000000000000000000000000000000000000000000000  [Correct]
memory location 9  = 0000000000000000000000000000000000000000000000000000000000000000  [Correct]
memory location 10 = 0000000000000000000000000000000000000000000000000000000000000003  [Wrong — no write]
memory location 11 = 000000000000000000000000000000000000000000000000000000000000000c  [Correct]
memory location 12 = 0000000000000000000000000000000000000000000000000000000000000000  [Correct]

Internal Reg 0 = 00...00  [Wrong — no write]
Internal Reg 1 = 00...00  [Wrong — no write]
Internal Reg 2 = 00...00  [Wrong — no write]
Internal Reg 3 = 00...00  [not checked]

Project did not return the proper values
```

All failures are exclusively due to WRITEBACK being a skeleton with no results are written anywhere.
Locations 0, 1, 7, 8, 9, 11, and 12 pass because they are read-only or pre-initialised to the
correct values and were never overwritten.
