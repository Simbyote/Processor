`default_nettype none
`timescale 1ns/1ns
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
//`include "params.vh"
module MatrixALU (
    input logic Clk,
    inout tri [DATA_W-1:0] Dataout, // Set to tri for bidirectional bus
    input logic [ADDR_W-1:0] address,
    input logic nRead,
    input logic nWrite,
    input logic nReset
);

endmodule
`default_nettype wire