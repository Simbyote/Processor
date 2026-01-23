`default_nettype none
/* int.sv
 * Purpose:
 *  Performs integer arithmetic operations as specified by the instruction
 *  set.
 *
 * Functions:
 * - Add, subtract, multiply, and divide integer operands.
 * - Return results to registers or memory.
 *
 * Modules:
 * - int: Integer ALU module.
 *
 * Notes:
 * - Uses built-in arithmetic operators for synthesis.
 * - Overflow handling is not required (but is optional).
 */
`default_nettype wire