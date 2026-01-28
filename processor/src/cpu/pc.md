# Program Counter (PC)

## Purpose
Holds the instruction index of the next instruction to fetch and 
updates it only when authorized by the execution FSM.

## Scope
**Included**
- Registers the current PC value on rising clock edge.
- Stalls PC updates while write-enable is low.
- Redirects PC by loading a new instruction index.
- A combinational sequential-next value is offered.

**Excluded**
- Compute branch conditions.
- Compute branch targets.
- Fetch instructions or interface to ROM or memory.
- Validate PC range and alignment.
- Raise traps/faults on invalid PC. Fails silently.

## Interfaces
### Inputs
| Signal  | Width | Description                 | Valid / Assumptions                                               |
|---------|------:|-----------------------------|-------------------------------------------------------------------|
| clk     | 1     | Clock                       | rising edge                                                       |
| rst     | 1     | Reset                       | active-high, synchronous                                          |
| pc_we   | 1     | PC write enable             | `1`: update, `0`: hold                                            |
| pc_next | PC_W  | Next instruction index value| Must be a valid instruction index chosen by execution FSM/control |


### Outputs
| Signal  | Width | Description                     | Valid / Assumptions               |
|---------|------:|---------------------------------|-----------------------------------|
| pc_curr | PC_W  | Current instruction index       | registered, stable between clocks |
| pc_inc  | PC_W  | Next sequential index (`+1`)    | combinational                     |

### Parameters / Constants
| Name | Value        | Meaning                                |
|------|-------------:|----------------------------------------|
| PC_W | 10 (default) | Width of PC instruction index register |
## Behavioral Contract
### Reset
- On any rising edge with `rst = 1`,: `pc_curr <= '0`.

### Update rule (clocked)
- If `rst == 1`: `pc_curr <= '0`
- Else if `pc_we == 1`: `pc_curr <= pc_next`
- Else: `pc_curr <= pc_curr` (holds)

### Output rule
- `pc_curr` is registered, updates only on rising clock edge.
- `pc_inc` is combinational: `pc_inc = pc_curr + 1`.
- Outputs are valid every cycle (no `ready` signal).

### Illegal / undefined
- If `pc_next` is not an instruction index, the PC will still load it. 
This results is a "wrong fetch" upstream.
- No internal protection.
- If `pc_next` exceeds instruction memory depth, no handling currently
exists.

## Addressing / Mapping
- Base / range: 
    - PC stores and instruction index beginning at 0.
    - Address ranges and memory windows are applied outside the module.
- Indexing: 
    - Instruction fetch forms the instruction-memory address as:
        - `instr_addr = ROM_BASE + (pc_curr << INSTR_SHIFT)`
- Stride: 
    - Sequential instruction flow advances by one instruction index per 
    update:
        - `pc_inc = pc_curr + 1`
- Example:
    - If `pc_curr = 0`: `pc_inc = 1`
    - If `pc_we = 1` and `pc_next = pc_inc`: the clock updates `pc_curr`
    from `0` to `1`.

## State
| Register | Width | Reset | Updates when           | Description                               |
|----------|------:|------:|------------------------|-------------------------------------------|
| pc_curr  | PC_W  | 0     | `rst==1` or `pc_we==1` | Instruction index of next fetch           |

## Verification
### Invariants
- If `rst == 0` and `pc_we == 0`: `pc_curr` is stable across rising 
edges.
- If `rst == 1` on a rising edge: `pc_curr` is reset to `0`.
- `pc_inc == pc_curr + 1` must always hold combinationally.

### Scenarios
-Reset assertion -> PC initializes instruction index to `0`.
- Sequential progression when enabled -> `pc_we = 1` and `pc_next = pc_inc` advances PC by one instruction per cycle.
- PC holds -> `pc_we = 0` holds the current instruction index regardless of `pc_next`.
- Redirect update -> `pc_we = 1` with `pc_next` $\neq$ `inc` loads a 
non-sequential instruction index.
- No unintended update -> chnages on `pc_next` while `pc_we = 0` do not
affect PC state.
- Reset dominance -> if `rst = 1`, PC resets to `0` regardless of `pc_we` or `pc_next`.

### Known limitations / Follow-ups
- No protection or access control.
- Define PC width from ROM depth.

## Change Log
- 2026-01-27: Initial PC implementation.
