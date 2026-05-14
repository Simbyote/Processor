`default_nettype none
`timescale 1ns/1ns
/* instr.sv
 * Purpose:
 *  Holds the instructions that the processor will execute. Is
 *  a read-only memory
 *
 * Functions:
 * - Read instructions from memory
 *
 * Modules:
 * - InstructionMemory: The instruction memory
 *
 * Notes:
 * - Relies on decode to classify instruction memory accesses
 */

/* InstructionMemory
 * Purpose:
 *  The instruction memory is a read-only memory that holds the instructions
 *  that the processor will execute
 *
 * Inputs:
 * - clk: Clock signal
 * - address: 16-bit address bus
 * - nRead: Read signal
 * - nReset: Reset signal
 *
 * Outputs:
 * - Dataout: Data bus
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