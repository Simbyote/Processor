`default_nettype none
`timescale 1ns/1ns
/*
 * matrix_add.sv
 * Purpose:
 *  Parallel 4x4 matrix adder over a 256-bit data bus.
 *
 * Inputs:
 *  - Clk: Clock signal
 *  - nReset: Reset signal
 *  - nRead: active-low read enable for DataBus
 *  - nWrite: active-low write enable for DataBus
 *  - address: 16-bit address bus for memory access
 *
 * Inout:
 *  - DataBus: 256-bit tri-state data bus for memory read/write
 *
 * Notes:
 *  Address decode for the matrix device is set as address[15:12] == 4'h3
 *  Offset map of the address bus:
 *   0 -> Source0  - 256-bit, write-only from bus
 *   1 -> Source1  - 256-bit, write-only from bus
 *   2 -> Result   - 256-bit, read-only  to   bus
 *   3 -> StatusIn - write-any triggers addition
 */ 

module MatrixAdd (
    input  logic Clk,
    input  logic nReset,
    input  logic nRead,
    input  logic nWrite,
    input  logic [15:0] address,
    inout  tri [255:0] DataBus
);
    // Internal wires
    logic [255:0] Source0;
    logic [255:0] Source1;
    logic [255:0] Result;
    logic [255:0] AddResult;

    // Deconstruct deviceID and its offset 
    logic AluEn;
    logic [11:0] offset;
    assign AluEn  = (address[15:12] == 4'h3);
    assign offset =  address[11:0];

    /* parallel hardware
     * - performs matrix addition on 16 16-bit inputs
     * - continuously updates AddResult
     */
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : gen_add
            assign AddResult[i*16 +: 16] =
                $signed(Source0[i*16 +: 16]) + $signed(Source1[i*16 +: 16]);
        end // signed handles twos complement overflow
    endgenerate

    // Matrix addition logic
    always_ff @(negedge Clk or negedge nReset) begin
        if (!nReset) begin  // Initialize internal wires
            Source0 <= '0;
            Source1 <= '0;
            Result  <= '0;
        end else if (AluEn && !nWrite) begin    // Compute the addition
            case (offset)
                12'd0: Source0 <= DataBus;          // Load matrix S0
                12'd1: Source1 <= DataBus;          // Load matrix S1
                12'd3: Result  <= AddResult;        // Update result
                default: ;
            endcase
        end
    end

    // Tristate assignment for databus
    assign DataBus = (AluEn && !nRead && (offset == 12'd2)) ? Result : 'z;
endmodule
`default_nettype wire