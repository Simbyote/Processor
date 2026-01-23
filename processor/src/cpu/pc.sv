`default_nettype none
/* pc.sv
 * Purpose:
 *  Holds the address of the next instruction to fetch from instruction
 *  memory. Updates sequentially or via branch offset as directed by the
 *  execution FSM.
 *
 * Functions:
 * - Will increment PC during normal execution.
 * - Will update PC on branch instruction.
 * - Will reset PC to a known state on system reset.
 *
 * Modules:
 * - pc: Program counter module.
 *
 * Notes:
 * - PC updates occur only under control of the execution FSM.
 * - No instruction decoding or memory access occurs here.
 */
`default_nettype wire