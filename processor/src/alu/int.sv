`default_nettype none
`timescale 1ns/1ns
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
module IntegerAlu (
    input logic Clk,
    inout tri [DATA_W-1:0] Dataout, // Set to tri for bidirectional bus
    input logic [ADDR_W-1:0] address,
    input logic nRead,
    input logic nWrite,
    input logic nReset
);

endmodule
`default_nettype wire