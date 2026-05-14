`default_nettype none
`timescale 1ns/1ns
/* mem.sv
 * Purpose:
 *  Implements the main memory module for the processor, providing storage
 *  for instructions and data
 *
 * Functions:
 * - Read and write to main memory
 *
 * Modules:
 * - MainMemory: The main memory module
 */

/* MainMemory
 * Purpose:
 *  The main memory is a read-only memory that holds the instructions
 *  and data that the processor will execute
 *
 * Inputs:
 * - clk: Clock signal
 * - address: 16-bit address bus
 * - nRead: Read signal
 * - nWrite: Write signal
 * - nReset: Reset signal
 *
 * Outputs:
 * - Dataout: Data bus
 */
//`include "params.vh"
module MainMemory (
    input  logic Clk,
    inout  tri [DATA_W-1:0] Dataout,
    input  logic [ADDR_W-1:0] address,
    input  logic nRead,
    input  logic nWrite,
    input  logic nReset
);
    // Internal signals
    logic [DATA_W-1:0] MainMemory[14];
    logic [DATA_W-1:0] MemToOutput;
    logic ItsMe;

    // Sets when MainMemory is being read
    assign ItsMe = (address[ADDR_W-1:LOCAL_W] == MainMem) && ~nRead;

    always_ff @(posedge Clk or negedge nReset) begin
        if (~nReset) begin
            MainMemory[0] = 256'h000e_000c_0008_000d_0008_0010_000f_0009_000B_0008_0006_0007_000c_0005_000c_0008;
            MainMemory[1] = 256'h000a_0005_0007_0009_000c_0004_000e_0002_0007_0006_0007_0008_000c_0007_0004_0009;
            MainMemory[2] = 256'h0;
            MainMemory[3] = 256'h0;
            MainMemory[4] = 256'h0;
            MainMemory[5] = 256'h0;
            MainMemory[6] = 256'h0;
            MainMemory[7] = 256'h0;
            MainMemory[8] = 256'h0;
            MainMemory[9] = 256'h0;
            MainMemory[10] = 256'h3;
            MainMemory[11] = 256'hc;
            MainMemory[12] = 256'h0;
            MainMemory[13] = 256'h0;
            MemToOutput=0;
        end else begin
            if (address[ADDR_W-1:LOCAL_W] == MainMem && ~nWrite) begin
                MainMemory[address[3:0]] <= Dataout;
            end else if (address[ADDR_W-1:LOCAL_W] == MainMem && ~nRead) begin
                MemToOutput <= MainMemory[address[3:0]];
            end
        end
    end

    // Assign the main memory to the databus
    assign Dataout = ItsMe ?  MemToOutput : 'z;
endmodule
`default_nettype wire