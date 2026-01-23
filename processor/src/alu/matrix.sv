`default_nettype none
/* matrix.sv
 * Purpose:
 *  Executes matrix-based arithmetic operations on 4x4 matrices.
 *
 * Functions:
 * - Matrix addition, subtraction, multiplication.
 * - Scalar multiplication and transposition.
 *
 * Modules:
 * - matrix: Matrix ALU module.
 *
 * Notes:
 * - Operations may be multi-cycle.
 * - Execution is fully controlled by the execution FSM.
 */
`default_nettype wire