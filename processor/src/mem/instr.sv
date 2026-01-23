`default_nettype none
/* instr.sv
 * Purpose:
 *  Stores the program by the processor.
 *
 * Functions:
 * - Provide 256-bit wide read/write storage.
 * - Support memory-mapped access by the CPU.
 *
 * Modules:
 * - instr: Top-level instruction memory module.
 *
 * Notes:
 * - Address alignment enforced externally.
 * - No internal address decoding logic.
 */
`default_nettype wire