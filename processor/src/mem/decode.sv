`default_nettype none
/* decode.sv
 * Purpose:
 *  Decodes memory addresses and selects the appropriate memory-mapped
 *  signals.
 *
 * Functions:
 * - Map address ranges to memory, ALUs, and peripherals.
 * - Generate module select signals.
 *
 * Modules:
 * - decode: Central address decoding module.
 *
 * Notes:
 * - Centralizes all memory map logic.
 * - Prevents address decoding duplication.
 */
`default_nettype wire