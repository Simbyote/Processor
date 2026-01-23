`default_nettype none
/* reg.sv
 * Purpose:
 *  Provides temporary storage for internal processor registers used
 * during instruction execution.
 *
 * Functions:
 * - Store intermediate values and results
 * - Support read and write access as directed by the execution FSM.
 *
 * Modules:
 * - reg: Register file module.
 *
 * Notes:
 * - Number of registers is kept minimal and justified to consolidate
 *   resource consumption.
 * - No instruction decoding occurs in this module.
 */
`default_nettype wire