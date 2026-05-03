`default_nettype none
`timescale 1ns/1ns
// Mark W. welker
// Instruction memory. 
// holds the instructions that the processor will execute.
//
// the address lines are generic and each module must handle thier own decode. 
// The address bus is large enough that each module can contain a local address decode. This will save on multiple enmables. 
// bit 11-0 are for adressing inside each unit.
// nWrite = 0 means databus is being written into the part on the falling edge of write
// nRead = 0 means it is expected to drive the databus while this signal is low and the address is correct until the nRead goes high independent of addressd bus.

parameter MainMemEn = 0;
parameter RegisterEn = 1;
parameter InstrMemEn = 2;
parameter AluEn = 3;
parameter ExecuteEn = 4;
parameter IntAlu = 5;

// Alu Register setup // same register sequence for both ALU's 
parameter AluStatusIn = 0;
parameter AluStatusOut = 1;
parameter ALU_Source1 = 2;
parameter ALU_Source2 = 3;
parameter  ALU_Result = 4;
parameter Overflow_err = 5;

//////////////////////////////
//Moved stop to third instruction for this example
/////////////////////////////////////////////////
// instruction: OPcode :: dest :: src1 :: src2 Each section is 8 bits.
//Stop::FFh::00::00::00
//MMult::00h::Reg/mem::Reg/mem::Reg/mem
//Madd::01h::Reg/mem::Reg/mem::Reg/mem
//Msub::02h::Reg/mem::Reg/mem::Reg/mem
//Mtranspose::03h::Reg/mem::Reg/mem::Reg/mem
//MScale::04h::Reg/mem::Reg/mem::Reg/mem
//MScaleImm::05h:Reg/mem::Reg/mem::Immediate
//IntAdd::10h::Reg/mem::Reg/mem::Reg/mem
//IntSub::11h::Reg/mem::Reg/mem::Reg/mem
//IntMult::12h::Reg/mem::Reg/mem::Reg/mem
//IntDiv::13h::Reg/mem::Reg/mem::Reg/mem

// add the data at location 0 to the data at location 1 and place result in location 2
parameter Instruct1 = 32'h 10_02_00_01;
parameter Instruct2 = 32'h FF_00_00_00;


// NOTE the lack of datain and write. This is because this is a ROM model
module InstructionMemory(
    input logic Clk,
    input logic [15:0] address,
    input logic nRead,
    input logic nReset,

    output logic [31:0] Dataout
);
    logic [31:0]InstructMemory[10]; // this is the physical memory

    // This memory is designed to be driven into a data multiplexor. 
    always_ff @(negedge Clk or negedge nReset)
    begin
        if (!nReset)
            Dataout = 0;
        else begin
            if(address[15:12] == InstrMemEn) // talking to Instruction IntstrMemEn
            begin
                if(~nRead)begin
                    Dataout <= InstructMemory[address[11:0]]; // data will reamin on dataout until it is changed.
                end
            end
        end
    end // from negedge nRead	

    always @(negedge nReset)
    begin
    //	set in the default instructions 
        InstructMemory[0] = Instruct1;
        InstructMemory[1] = Instruct2;
    end 
endmodule
`default_nettype wire