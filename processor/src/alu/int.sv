`default_nettype none
`timescale 1ns/1ns
/* int.sv
 * Purpose:
 *  Performs integer arithmetic operations as specified by the instruction
 *  set.
 *
 * Functions:
 * - Add, subtract, multiply, and divide integer operands.
 * - Return results to registers or memory.
 *
 * Modules:
 * - int: Integer ALU module.
 *
 * Notes:
 * - Uses built-in arithmetic operators for synthesis.
 * - Overflow handling is not required (but is optional).
 */
//`include "params.vh"
module IntegerAlu (
    input logic Clk,
    inout tri [DATA_W-1:0] Dataout,
    input logic [ADDR_W-1:0] address,
    input logic nRead,
    input logic nWrite,
    input logic nReset
);
    logic AluEn;
    logic [LOCAL_W-1:0] offset;
    assign AluEn = address[ADDR_W-1:LOCAL_W] == IntAlu;
    assign offset = address[LOCAL_W-1:0];

    logic [DATA_W-1:0] src1, src2, result;
    logic [7:0] opcode;

    always_ff @(negedge Clk or negedge nReset) begin
        if (!nReset) begin
            src1 <= '0; src2 <= '0; result <= '0; opcode <= '0;
        end else if (AluEn && !nWrite) begin
            case (offset)
                AluStatusIn: opcode <= Dataout[7:0];
                ALU_Source1: src1 <= Dataout;
                ALU_Source2: src2 <= Dataout;
                ALU_Result: begin
                    case (opcode)   // ALU operations
                        Iadd: result <= {{(DATA_W-16){1'b0}}, src1[15:0] + src2[15:0]};
                        Isub: result <= {{(DATA_W-16){1'b0}}, src1[15:0] - src2[15:0]};
                        Imult: result <= {{(DATA_W-32){1'b0}}, src1[15:0] * src2[15:0]};
                        Idiv: result <= (src2[15:0] != 0)
                                           ? {{(DATA_W-16){1'b0}}, src1[15:0] / src2[15:0]}
                                           : '0;
                        default: result <= '0;
                    endcase
                end
                default: ;
            endcase
        end
    end

    // Tristate Read
    assign Dataout = (AluEn && !nRead) ?
                     (offset == ALU_Result ? result : '0)
                     : 'z;
endmodule
`default_nettype wire