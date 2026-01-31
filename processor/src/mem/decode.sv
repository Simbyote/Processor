`default_nettype none
`timescale 1ns/1ps
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

/* decode
 * Purpose:
 *  The decode module interprets the bits at addr[15:12] and
 *  generates a select signal for the appropriate memory-mapped
 *  device.
 *
 * Inputs:
 * - rd: Read signal
 * - wr: Write signal
 * - addr: 16-bit address bus
 *
 * Outputs:
 * - hit: Indicates if the address maps to a valid device 
 *   (1 = valid, 0 = invalid)
 * - did: Select signal for the appropriate memory-mapped device
 *
 * Notes:
 * - Hit indicates whether a selection is valid or invalid. A hit
 *   of 0 means no device is selected or some error occurred.
 * - When no hit is found, the selection signal is set to NONE.
 * - Decode logic activates when either:
 *   - both are active, 
 *   - rd is active
 *   - wr is active
 *
 * Block Diagram:

              +----------------+
rd  -------> |                |
wr  -------> |    DECODE      | -----> hit
addr ------> |                | -----> did
             +----------------+

 */
import params_pkg::*; // Is sensitive; alternative:
// "params_pkg::ADDR_W" instead of "ADDR_W"
module decode (
    input wire rd, wr,
    input wire [ADDR_W-1:0] addr,

    output logic hit,
    output logic [2:0] did
);
    // Address decoding logic (combinational)
    always_comb begin
        hit = 1'b0;
        did = DNON;

        // Decode when read or write is active
        if (rd || wr) begin
            // Decode address range
            unique case (addr[15:12])
                4'h0: begin 
                    hit = 1'b1;
                    did = DRAM;
                end
                4'h1: begin
                    hit = 1'b1;
                    did = DROM;
                end
                4'h2: begin
                    hit = 1'b1;
                    did = DMAT;
                end
                4'h3: begin
                    hit = 1'b1;
                    did = DINT;
                end
                4'h4: begin
                    hit = 1'b1;
                    did = DREG;
                end
                4'h5: begin
                    hit = 1'b1;
                    did = DEXE;
                end
                4'h6: begin
                    hit = 1'b1;
                    did = DSPI;
                end
                default: begin
                    hit = 1'b0;
                    did = DNON;
                end
            endcase
        end
    end
endmodule
`default_nettype wire