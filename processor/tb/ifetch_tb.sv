`default_nettype none
`timescale 1ns/1ps
/* ifetch_tb.sv
 * Purpose:
 *  Generates an instruction memory address, performs validation (making sure
 *  that it assigns to ROM correctly), and latches the instruction with a valid 
 *  flag.
 *
 * Functions:
 * - Produce an address for instruction memory
 * - Use said address to request instruction memory
 * - Classify the address
 * - Verifies and latches the instruction
 *
 * Modules:
 * - ifetch_tb: Testbench for instruction fetch module
 *
 * Notes:
 * 
 */
import params_pkg::*;
module ifetch_tb (
    input wire [ADDR_W-1:0] pc_curr,
    input wire [ADDR_W-1:0] addr,
    input wire rd,
    input wire hit,
    input wire [2:0] did,
    input wire [INSTR_W-1:0] instr,
    input wire valid,

    output logic clk,
    output logic rst,
    output logic pc_we,
    output logic [ADDR_W-1:0] pc_next,
    output logic hold,
    output logic flush
);
    // Initialize clock and reset signals
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    initial begin
        rst = 1;
        repeat (2) @(posedge clk);
        rst = 0;
    end

    // Proceed to testing
    
    initial begin

        #100;
        $finish;
    end
endmodule
`default_nettype wire