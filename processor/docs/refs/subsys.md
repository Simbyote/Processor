# <Subsystem Name> (<short_id>)

## Purpose
<Brief sentence. Must include what it produces or controls.>

## Scope
**Included**
- <Actionable goals.>

**Excluded**
- <Explicit non-goals.>

## Interfaces
### Inputs
| Signal | Width | Description | Valid / Assumptions |
|--------|------:|-------------|---------------------|
|  clk   |   1   |    Clock    | rising edge         |
|  rst   |   1   |    Reset    | active-high         |
| ...    |  ...  |    ...      | ...                 |

### Outputs
| Signal | Width | Description | Valid / Assumptions |
|--------|------:|-------------|---------------------|
| ...    |  ...  |    ...      | ...                 |

### Parameters / Constants
| Name | Value | Meaning |
|--------|------:|-------------|---------------------|
| ...    |  ...  |    ...      | ...                 |
## Behavioral Contract
### Reset
- <Exact values after reset>

### Update rule (clocked)
- If <condition>: <state updates>
- Else: <state holds>

### Output rule
- <registered/combinational>
- <when outputs are valid>

### Illegal / undefined
- <what happens if inputs violate assumptions>

## Addressing / Mapping (if applicable)
- Base / range: <e.g., 0x1000–0x1FFF>
- Indexing: <addr -> index formula>
- Stride: <PC increment rule>
- Example: <one worked example>

## State
| Register | Width  | Reset | Updates when | Description |
|----------|-------:|-------|--------------|-------------|
| ...      |  ...   |  ...  |  ...         |  ...        |

## Verification
### Invariants
- <Must always hold; phrase as assertions>

### Scenarios
- <3–7 simple tests with expected results>

### Known limitations / Follow-ups
- <What is intentionally postponed>

## Change Log
- YYYY-MM-DD: <change> (commit: <hash>)
