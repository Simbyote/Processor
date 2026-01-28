# Address Decoder (DEC)

## Purpose
Combinationally decode a 16-bit memory-mapped address and access request 
to produce a device identification and a validity signal for downstream 
subsystem selection. 

## Scope
**Included**
- Extracts upper address bits.
- Selects mapped region.
- Generates device ID.
- Validates access request.
- Flags unmapped addresses.

**Excluded**
- Data movement.
- Bus arbitration.
- Timing control.
- Access serialization.
- Protection or privilege checks.
- Read/write conflict resolution.

## Interfaces
### Inputs
| Signal | Width | Description              | Valid / Assumptions                   |
|--------|------:|--------------------------|---------------------------------------|
| rd     | 1     | Read request             | Active-high                           |
| wr     | 1     | Write request            | Active-high                           |
| addr   | 16    | Memory-mapped address    | Aligned (addr[15:12] selects region)  |

### Outputs
| Signal | Width | Description         | Valid / Assumptions                                        |
|--------|------:|---------------------|------------------------------------------------------------|
| hit    | 1     | Valid-mapped access | High only when rd or wr are asserted and addr is in range  |
| did    | 3     | Device ID           | Valid only when hit is high                                |

### Parameters / Constants
| Name        |  Value | Meaning              |
|-------------|-------:|----------------------|
| ADDR_MSB    |   15   | Upper Decode field   |
| ADDR_LSB    |   12   | Lower Decode field   |
| REGION_SIZE | 0x1000 | Fixed region window  |
| MAX_REGION  |   6    | Highest valid region |

## Behavioral Contract
### Reset
- No internal state.
- Outputs are purely combinational.
- After system reset, outputs depend only on input values.

### Update rule (clocked)
- If `(rd || wr) && addr[15:12] <= 4'h6)`:
    - `hit = 1`
    - `did = decode(addr[15:12])`
- Else: 
    - `hit = 0`
    - `did = DNONE`

### Output rule
- Purely combinational.
- Outputs valid once inputs stabilize.
- No clock dependence.

### Illegal / undefined
- Simultaneous `rd` and `wr` is tolerated but treated as a system-level 
protocol violation.
- Downstream logic must ignore `did` when `hit = 0`.

## Addressing / Mapping (if applicable)
- Base / range: `0x0000 - 0x6FFF`
- Indexing: `region = addr[15:12]`
- Stride: fixed 0x1000 windows
- Example:
    - `addr = 0x2ABC` -> `region = 2` -> `did = DMAT`, `hit = 1`
    - `addr = 0x8000` -> invalid -> `did = DNONE`, `hit = 0`

## State
| Register | Width | Reset | Updates when | Description       |
| -------- | ----: | ----: | ------------ | ----------------- |
| —        |     — |     — | —            | No internal state |


## Verification
### Invariants
- `hit == 0` implies `did == DNONE`
- `hit == 1` implies `addr[15:12]` $\in$ `[0x0, 0x6]`
- Decoder output is independent of clock.

### Scenarios
- Valid read to each mapped region.
- Valid write to each mapped region.
- rd = 0 and wr = 0 -> idle output.
- Boundary addresses (0x0FFF -> DRAM, 0x1000 -> ROM, etc.)
- Invalid region accesses ($\ge$ 0x7000).
- Simultaneous rd and wr assertion.

### Known limitations / Follow-ups
- Fixed region granularity (0x1000).
- Limited to 7 mapped devices.
- `did` width must expand if regions increase.
- No protection or access control.

## Change Log
- 2026-01-27: Initial combinational decoder implementation.
