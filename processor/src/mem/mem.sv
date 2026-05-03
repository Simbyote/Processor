`default_nettype none
/* mem.sv
 * Purpose:
 *  Implements the main memory module for the processor, providing storage
 *  for instructions and data. Supports read and write operations based on
 *  address decoding
 */
module MainMemory(
    input logic Clk,
    input logic [255:0] Dataout,
    input logic [15:0] address,
    input logic nRead,
    input logic nWrite,
    input logic nReset
);
`include "params.vh"

    logic [255:0]MainMemory[14]; // this is the physical memory
    logic ItsMe; // the address bus is talking to this module. used to enable tristate buffers
    logic [255:0] MemToOutput; // this is a temporary data register to be set to go to the output 

    always_ff @(negedge Clk or negedge nReset) begin
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
        end
        else if(address[15:12] == MainMem) begin
            if (~nRead) begin
                ItsMe = 1; // Only Drive Bus on read
                MemToOutput = MainMemory[address[3:0]]; // data will remain on dataout until it is changed.
            end
            if(~nWrite) begin
                ItsMe = 0; // only drive bus on read
                MainMemory[address[3:0]] <= Dataout;
            end
        end
        else ItsMe = 0;
    end 	
assign Dataout = ItsMe ? MemToOutput : 255'bz;
endmodule
`default_nettype wire