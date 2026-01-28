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
    /* Local parameters
     * - ADDR_MSB: Most significant address bit
     * - ADDR_LSB: Least significant address bit
     * - REGION_SIZE: Size of each memory region
     * - MAX_REGION: Number of valid memory regions
	 * - DNONE: Invalid select signal
     */
    localparam int unsigned ADDR_MSB = 15;
    localparam int unsigned ADDR_LSB = 12;
    localparam logic [15:0] REGION_SIZE = 16'h1000;
    localparam logic [3:0] MAX_REGION = 4'd6;
	localparam logic [2:0] DNONE = 3'd7; 

    logic [3:0] region;
    assign region = addr[ADDR_MSB:ADDR_LSB];

    // Address decoding logic (combinational)
    always_comb begin
        // Initialize selection
        hit = 1'b0;
        did = DNONE;

        // Decode when read or write is active
        if (rd || wr) begin
            if (region <= MAX_REGION) begin
                hit = 1'b1;
				did = region[2:0];
            end
        end
    end
endmodule
`default_nettype wire