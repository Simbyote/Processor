`default_nettype none
`timescale 1ns / 1ps
/* pc.sv
 * Purpose:
 *  Holds the instruction index of the next instruction to fetch from instruction
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

/* pc
 * Purpose:
 * Program counter module waits until execution FSM authorizes progression
 * by asserting `pc_we` and providing a valid `pc_next`.
 *
 * Parameters:
 * - PC_W: Width of the program counter (Initial value is 10).
 *
 * Inputs:
 * - clk: Clock signal.
 * - rst: Reset signal.
 * - pc_we: Write enable for the program counter.
 * - pc_next: Next value for the program counter.
 *
 * Outputs:
 * - pc_curr: Current value of the program counter.
 * - pc_inc: Incremented value of the program counter.
 * 
 * Notes:
 * - PC is updated only under control of the execution FSM.
 */
 module pc #(
    parameter int PC_W = 10
 ) (
    input wire clk,
    input wire rst,
    input wire pc_we,
    input wire [PC_W-1:0] pc_next,

    output logic [PC_W-1:0] pc_curr,
    output logic [PC_W-1:0] pc_inc
 );

    // Offer the next sequential instruction
    assign pc_inc = pc_curr + {{(PC_W-1){1'b0}}, 1'b1}; // Concatenate 1 to the MSB

    // Update the program counter (sequential)
    always_ff @(posedge clk) begin  // Check on every rising edge
        if (rst) begin
            pc_curr <= '0;
        end
        // If pc_we is high, update the program counter
        // If pc_we is low, hold the current value
        else if (pc_we) begin
            pc_curr <= pc_next;
        end
    end
 endmodule
`default_nettype wire