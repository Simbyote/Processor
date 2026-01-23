`default_nettype none
/* opmux.sv
 * Purpose:
 *  Selects instruction operands from either registers or memory based on
 * instruction encoding.
 *
 * Functions:
 * - Route operands to the appropriate ALU.
 * - Implement Reg/Mem selection using instruction MSB.
 *
 * Modules:
 * - opmux: Operand multiplexer module.
 *
 * Notes:
 * - Contains no arithmetic or control logic.
 * - Selection is purely combinational.
 */
 `default_nettype wire