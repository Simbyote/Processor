`default_nettype none
`timescale 1ns/1ns
// Mark W. Welker
// Matrix_add assignment
// Spring 2021

// Specific addresses to decode from
parameter MainMemEn = 0;
parameter RegisterEn = 1;
parameter InstrMemEn = 2;
parameter AluEn = 3;
parameter ExecuteEn = 4;

parameter matrixMemory0 = 256'h0020_001f_001e_001d_001c_001b_001a_0019_0018_0017_0016_0015_0014_0013_0012_0011;
parameter matrixMemory1 = 256'h0001_0002_0003_0004_0005_0006_0007_0008_0009_000a_000b_000c_000d_000e_000f_0010;

module MainMemory(
    input logic Clk,
    input logic [255:0] DataIn,     
    input logic [15:0] address, 
    input logic nRead,
    input logic nWrite, 
    input logic nReset,

    output logic [255:0] Dataout
);
    // Physical memory
    logic [255:0] MainMemory [12];

    always_ff @(negedge Clk or negedge nReset)
    begin
        if (~nReset) begin
            MainMemory[0] = matrixMemory0;
            MainMemory[1] = matrixMemory1;
            MainMemory[2] = 256'h0;
            MainMemory[3] = 256'h0;
            MainMemory[4] = 256'h0;
            MainMemory[5] = 256'h0;
            MainMemory[6] = 256'h0;
            MainMemory[7] = 256'h0;
            MainMemory[8] = 256'h4;
            MainMemory[9] = 256'hb;
            MainMemory[10] = 256'h0;
            MainMemory[11] = 256'h0;

            Dataout=0;
        end
        else if(address[15:12] == MainMemEn) // talking to Instruction
        begin
            if (~nRead)begin
                Dataout <= MainMemory[address[11:0]]; // data will remain on dataout until it is changed.
            end
            if(~nWrite)begin
            MainMemory[address[11:0]] <= DataIn;
            end
        end
    end // from negedge nRead
endmodule
`default_nettype wire