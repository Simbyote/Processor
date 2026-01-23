`default_nettype none
/* fetch.sv
 * Purpose:
 *  Interfaces with instruction memory to receive the instruction located
 *  at the address provided by the PC.
 *
 * Functions:
 * - Read instruction words from instruction ROM.
 * - Latch the fetched instruction into an instruction register.
 *
 * Modules:
 * - fetch: Instruction fetch module.
 *
 * Notes:
 * - Does not decode instructions; only fetches and latches them.
 * - Read-only access to instruction memory.
 */
`default_nettype wire