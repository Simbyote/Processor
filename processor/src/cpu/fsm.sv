`default_nettype none
/* fsm.sv
 * Purpose:
 *  Controls the sequencing of instruction execution through fetch, decode,
 * execute, and write-back phases.
 *
 * Functions:
 * - Manage instruction life cycles.
 * - Control PC updates, memory accesses, and ALU operations.
 * - Stall execution for multi-cycle operations.
 * - Halt execution on `STOP` instruction.
 *
 * Modules:
 * - fsm: Central execution control module.
 *
 * Notes:
 * - All control decisions originate here.
 * - Datapath modules perform no autonomous control.
 */
`default_nettype wire