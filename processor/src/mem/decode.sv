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
 * - When no hit is found, the selection signal is set to DNONE.
 * - Decode logic activates when either:
 *   - both are active, 
 *   - rd is active
 *   - wr is active
 */
module decode (
    input wire rd, wr,
    input wire [15:0] addr,

    output logic hit,
    output logic [2:0] did
);
    /* Internal wires for select signals
    * - DRAM: Select signal for RAM (0x0000-0x0FFF range)
    * - DROM: Select signal for ROM (0x1000-0x1FFF range)
    * - DMAT: Select signal for matrix ALU (0x2000-0x2FFF range)
    * - DINT: Select signal for integer ALU (0x3000-0x3FFF range)
    * - DREG: Select signal for register file (0x4000-0x4FFF range)
    * - DEXEC: Select signal for execution engine (0x5000-0x5FFF range)
    * - DSPI: Select signal for SPI peripheral (0x6000-0x6FFF range)
    * - DNONE: Invalid select signal
    */
    localparam logic [2:0]
        DRAM  = 3'd0,
        DROM  = 3'd1,
        DMAT  = 3'd2,
        DINT  = 3'd3,
        DREG  = 3'd4,
        DEXEC = 3'd5,
        DSPI  = 3'd6,
        DNONE = 3'd7;

    // Address decoding logic (combinational)
    always_comb begin
        // Initialize selection
        hit = 1'b0;
        did = DNONE;

        // Decode when read or write is active
        if (rd || wr) begin
            unique case (addr[15:12]) // Read bits first 4 MSBs
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
                    did = DEXEC;
                end
                4'h6: begin
                    hit = 1'b1;
                    did = DSPI;
                end
                default: begin
                    hit = 1'b0;
                    did = DNONE;
                end
            endcase
        end
    end
endmodule
`default_nettype wire