`default_nettype none
`timescale 1ns/1ps
/* fetch.sv
 * Purpose:
 *  Issue instruction fetch requests and present valid instructions
 *  to the execution control logic.
 *
 * Functions:
 * - Drive read accesses to instruction memory using the current PC 
 * (will directly use pc outputs `pc_curr` signal).
 * - Observe decode hit/did signals to qualify instruction validity 
 * (will directly use decode outputs `did` and `hit` signals).
 * - Latch fetched instructions into an instruction register.
 * - Generate `valid` signal for downstream control. 
 *
 * Modules:
 * - fetch: Instruction fetch module.
 *
 * Notes:
 * - Does not decode instruction contents.
 * - Does not modify PC.
 * - Relies on decode to classify instruction memory accesses.
 */

/* fetch
 * Purpose:
 *  Fetches instructions from instruction memory using a validated
 *  decode `hit` and `did` signal, operating on rising edge clocks. 
 * 
 * Inputs:
 * - clk: Clock signal
 * - rst: Reset signal
 * - hold: Hold signal
 * - flush: Flush signal
 * - pc_curr: Current program counter
 * - hit: Decode hit signal
 * - did: Decode did signal
 * - drom_data: Data bus from DROM
 *
 * Outputs:
 * - addr: Address bus
 * - rd: Read signal
 * - instr: Instruction bus
 * - valid: Valid signal
 *
 * Notes:
 * - `addr` must be driven directly by `pc_curr`
 * - `rd` is asserted continuously
 * - `valid` must be derived from decode:
 *      EX: `valid = hit && (did == DROM)`
 * - `instr` should latch on clock only when `valid` is true
 * to prevent garbage instructions when unmapped or idle
 * - When `hold` is asserted, fetch does not update and deasserts `rd`
 * - When flush is asserted, set `valid` to 0 for one clock cycle
 *
 * Block diagram:

                  +----------------------+
pc_curr  ------> |                      |
hit       -----> |       FETCH          | -----> addr
did       -----> |                      | -----> rd
drom_data -----> |                      | -----> instr
hold      -----> |                      | -----> valid
flush     -----> |                      |
clk,rst   -----> |                      |
                 +----------------------+

 */
import params_pkg::*; // Is sensitive; alternative:
// "params_pkg::ADDR_W" instead of "ADDR_W"
// "params_pkg::INSTR_W" instead of "INSTR_W"
module fetch (
    input wire clk,
    input wire rst,
    input wire hold,
    input wire flush,
    input wire [ADDR_W-1:0] pc_curr,
    input wire hit,
    input wire [2:0] did,
    input wire [INSTR_W-1:0] drom_data,

    output logic [ADDR_W-1:0] addr,
    output logic rd,
    output logic [INSTR_W-1:0] instr,
    output logic valid
);
    assign addr = pc_curr;

    // Only issue a read when not held
    assign rd = ~hold;

    // Generate a successful fetch signal
    logic instr_ok;
    assign instr_ok = hit && (did == DROM);

    // Latch fetched instruction (sequential)
    always_ff @(posedge clk) begin
        if (rst) begin  // On reset
            instr <= '0;
            valid <= 1'b0;
        end
        else if (hold) begin    // On hold
            instr <= instr;
            valid <= valid;
        end
        else if (flush) begin   // On flush
            valid <= 1'b0;
            instr <= instr;
        end
        else begin  // On instruction fetch
            valid <= instr_ok;
            if (instr_ok) begin
                instr <= drom_data;
            end
        end
    end
endmodule
`default_nettype wire