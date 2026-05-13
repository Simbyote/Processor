`default_nettype none
`timescale 1ns/1ns
/* instr.sv
 * Purpose:
 *  Holds the instructions that the processor will execute. Is
 *  a read-only memory.
 */

//parameter MainMemEn = 0;
//parameter RegisterEn = 1;
//parameter InstrMemEn = 2;
//parameter AluEn = 3;
//parameter ExecuteEn = 4;
//parameter IntAlu = 5;

// Alu Register setup // same register sequence for both ALU's 
//parameter AluStatusIn = 0;
//parameter AluStatusOut = 1;
//parameter ALU_Source1 = 2;
//parameter ALU_Source2 = 3;
//parameter  ALU_Result = 4;
//parameter Overflow_err = 5;

/* Moved stop to third instruction for this example
 * instruction: OPcode :: dest :: src1 :: src2 Each section is 8 bits.
 * Stop::FFh::00::00::00
 * MMult1::00h::Reg/mem::Reg/mem::Reg/mem
 * MMult2::01h::Reg/mem::Reg/mem::Reg/mem
 * MMult3::02h::Reg/mem::Reg/mem::Reg/mem
 * Madd::03h::Reg/mem::Reg/mem::Reg/mem
 * Msub::04h::Reg/mem::Reg/mem::Reg/mem
 * Mtranspose::05h::Reg/mem::Reg/mem::Reg/mem
 * MScale::06h::Reg/mem::Reg/mem::Reg/mem
 * MScaleImm::07h:Reg/mem::Reg/mem::Immediate
 * IntAdd::10h::Reg/mem::Reg/mem::Reg/mem
 * IntSub::11h::Reg/mem::Reg/mem::Reg/mem
 * IntMult::12h::Reg/mem::Reg/mem::Reg/mem
 * IntDiv::13h::Reg/mem::Reg/mem::Reg/mem
 */
//`include "params.vh"
module InstructionMemory(
    input logic Clk,
    inout tri [INSTR_W-1:0]Dataout,    // Changed from logic to tri for bidirectional bus
    input logic [ADDR_W-1:0] address,
    input logic nRead,
    input logic nReset
);
    logic [INSTR_W-1:0]InstructMemory[15]; // this is the physical memory
    logic ItsMe; // the address bus is talking to this module. used to enable tristate buffers
    logic [INSTR_W-1:0] InstToOutput; // this is a temporary data register to be set to go to the output

    always_ff @(negedge Clk or negedge nReset) begin
        if (!nReset) begin
            InstToOutput <= '0;
            ItsMe <= 0;
        end else begin
            if (address[ADDR_W-1:LOCAL_W] == InstrMem) begin
                ItsMe <= 1;
                if (~nRead) begin
                    InstToOutput <= InstructMemory[address[LOCAL_W-1:0]];
                end
            end else begin
                ItsMe <= 0;
            end
        end
    end

    always @(negedge nReset) begin
        //	set in the default instructions
        InstructMemory[0] = Instruct1;  	
        InstructMemory[1] = Instruct2;  	
        InstructMemory[2] = Instruct3;
        InstructMemory[3] = Instruct4;	
        InstructMemory[4] = Instruct5;
        InstructMemory[5] = Instruct6;
        InstructMemory[6] = Instruct7;
        InstructMemory[7] = Instruct8;
        InstructMemory[8] = Instruct9;
        InstructMemory[9] = Instruct10;
        InstructMemory[10] = Instruct11;
        InstructMemory[11] = Instruct12;
        InstructMemory[12] = Instruct13;
    end 

    // Assign the instruction memory to the databus
    assign Dataout = ItsMe ?  InstToOutput : 'z;
endmodule
`default_nettype wire