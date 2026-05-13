`default_nettype none
`timescale 1ns/1ns
/* matrix.sv
 * Purpose:
 *  Executes matrix-based arithmetic operations on 4x4 matrices.
 *
 * Functions:
 * - Matrix addition, subtraction, multiplication.
 * - Scalar multiplication and transposition.
 *
 * Modules:
 * - matrix: Matrix ALU module.
 *
 * Notes:
 * - Operations may be multi-cycle.
 * - Execution is fully controlled by the execution FSM.
 */
//`include "params.vh"
module MatrixALU (
    input logic Clk,
    inout tri [DATA_W-1:0] Dataout, // Set to tri for bidirectional bus
    input logic [ADDR_W-1:0] address,
    input logic nRead,
    input logic nWrite,
    input logic nReset
);
    // Address Decode
    logic AluEn;
    logic [LOCAL_W-1:0] offset;
    assign AluEn = address[ADDR_W-1:LOCAL_W] == MatrixAlu;
    assign offset = address[LOCAL_W-1:0];

    // Internal signals
    logic [DATA_W-1:0] src1; // Matrix A
    logic [DATA_W-1:0] src2; // Matrix B
    logic [DATA_W-1:0] result;
    logic [7:0] opcode;     // Latched from AluStatusIn

    /* Writing Interface 
     * All 16 element assignments are written out per operation
     * Bit changes follow row-major packing: element(r,c) = [(r*4+c)*16 +: 16]
     *
     * r/c  | col0      | col1      | col2      |
     * -----+-----------+-----------+-----------|
     * row0 | [15:0]    | [31:16] | [47:32]     |
     * row1 | [79:64]   | [95:80]  | [111:96]   |
     * row2 | [143:128] | [159:144] | [175:160] |
     * row3 | [207:192] | [223:208] | [239:224] |
     */
    always_ff @(negedge Clk or negedge nReset) begin
        if (!nReset) begin
            src1 <= '0;
            src2 <= '0;
            result <= '0;
            opcode <= '0;
        end else if (AluEn && !nWrite) begin
            case (offset)
                AluStatusIn: opcode <= Dataout[7:0];    // Load opcode
                ALU_Source1: src1 <= Dataout;           // Load src1
                ALU_Source2: src2 <= Dataout;           // Load src2
                ALU_Result: begin                       // Do operation
                    case (opcode)
                        MAdd: begin // Matrix addition
                            result[15:0] <= $signed(src1[15:0]) + $signed(src2[15:0]); // [0][0]
                            result[31:16] <= $signed(src1[31:16]) + $signed(src2[31:16]); // [0][1]
                            result[47:32] <= $signed(src1[47:32]) + $signed(src2[47:32]); // [0][2]
                            result[63:48] <= $signed(src1[63:48]) + $signed(src2[63:48]); // [0][3]
                            result[79:64] <= $signed(src1[79:64]) + $signed(src2[79:64]); // [1][0]
                            result[95:80] <= $signed(src1[95:80]) + $signed(src2[95:80]); // [1][1]
                            result[111:96] <= $signed(src1[111:96]) + $signed(src2[111:96]); // [1][2]
                            result[127:112] <= $signed(src1[127:112]) + $signed(src2[127:112]); // [1][3]
                            result[143:128] <= $signed(src1[143:128]) + $signed(src2[143:128]); // [2][0]
                            result[159:144] <= $signed(src1[159:144]) + $signed(src2[159:144]); // [2][1]
                            result[175:160] <= $signed(src1[175:160]) + $signed(src2[175:160]); // [2][2]
                            result[191:176] <= $signed(src1[191:176]) + $signed(src2[191:176]); // [2][3]
                            result[207:192] <= $signed(src1[207:192]) + $signed(src2[207:192]); // [3][0]
                            result[223:208] <= $signed(src1[223:208]) + $signed(src2[223:208]); // [3][1]
                            result[239:224] <= $signed(src1[239:224]) + $signed(src2[239:224]); // [3][2]
                            result[255:240] <= $signed(src1[255:240]) + $signed(src2[255:240]); // [3][3]
                        end
                        MSub: begin
                            result[15:0] <= $signed(src1[15:0]) - $signed(src2[15:0]); // [0][0]
                            result[31:16] <= $signed(src1[31:16]) - $signed(src2[31:16]); // [0][1]
                            result[47:32] <= $signed(src1[47:32]) - $signed(src2[47:32]); // [0][2]
                            result[63:48] <= $signed(src1[63:48]) - $signed(src2[63:48]); // [0][3]
                            result[79:64] <= $signed(src1[79:64]) - $signed(src2[79:64]); // [1][0]
                            result[95:80] <= $signed(src1[95:80]) - $signed(src2[95:80]); // [1][1]
                            result[111:96] <= $signed(src1[111:96]) - $signed(src2[111:96]); // [1][2]
                            result[127:112] <= $signed(src1[127:112]) - $signed(src2[127:112]); // [1][3]
                            result[143:128] <= $signed(src1[143:128]) - $signed(src2[143:128]); // [2][0]
                            result[159:144] <= $signed(src1[159:144]) - $signed(src2[159:144]); // [2][1]
                            result[175:160] <= $signed(src1[175:160]) - $signed(src2[175:160]); // [2][2]
                            result[191:176] <= $signed(src1[191:176]) - $signed(src2[191:176]); // [2][3]
                            result[207:192] <= $signed(src1[207:192]) - $signed(src2[207:192]); // [3][0]
                            result[223:208] <= $signed(src1[223:208]) - $signed(src2[223:208]); // [3][1]
                            result[239:224] <= $signed(src1[239:224]) - $signed(src2[239:224]); // [3][2]
                            result[255:240] <= $signed(src1[255:240]) - $signed(src2[255:240]); // [3][3]
                        end
                        MTranspose: begin
                            result[15:0]    <= src1[15:0];     // [0][0] = [0][0]
                            result[31:16]   <= src1[79:64];    // [0][1] = [1][0]
                            result[47:32]   <= src1[143:128];  // [0][2] = [2][0]
                            result[63:48]   <= src1[207:192];  // [0][3] = [3][0]
                            result[79:64]   <= src1[31:16];    // [1][0] = [0][1]
                            result[95:80]   <= src1[95:80];    // [1][1] = [1][1]
                            result[111:96]  <= src1[159:144];  // [1][2] = [2][1]
                            result[127:112] <= src1[223:208];  // [1][3] = [3][1]
                            result[143:128] <= src1[47:32];    // [2][0] = [0][2]
                            result[159:144] <= src1[111:96];   // [2][1] = [1][2]
                            result[175:160] <= src1[175:160];  // [2][2] = [2][2]
                            result[191:176] <= src1[239:224];  // [2][3] = [3][2]
                            result[207:192] <= src1[63:48];    // [3][0] = [0][3]
                            result[223:208] <= src1[127:112];  // [3][1] = [1][3]
                            result[239:224] <= src1[191:176];  // [3][2] = [2][3]
                            result[255:240] <= src1[255:240];  // [3][3] = [3][3]
                        end
                        MScale: begin
                            result[15:0] <= $signed(src1[15:0]) * $signed(src2[15:0]); // [0][0]
                            result[31:16] <= $signed(src1[31:16]) * $signed(src2[15:0]); // [0][1]
                            result[47:32] <= $signed(src1[47:32]) * $signed(src2[15:0]); // [0][2]
                            result[63:48] <= $signed(src1[63:48]) * $signed(src2[15:0]); // [0][3]
                            result[79:64] <= $signed(src1[79:64]) * $signed(src2[15:0]); // [1][0]
                            result[95:80] <= $signed(src1[95:80]) * $signed(src2[15:0]); // [1][1]
                            result[111:96] <= $signed(src1[111:96]) * $signed(src2[15:0]); // [1][2]
                            result[127:112] <= $signed(src1[127:112]) * $signed(src2[15:0]); // [1][3]
                            result[143:128] <= $signed(src1[143:128]) * $signed(src2[15:0]); // [2][0]
                            result[159:144] <= $signed(src1[159:144]) * $signed(src2[15:0]); // [2][1]
                            result[175:160] <= $signed(src1[175:160]) * $signed(src2[15:0]); // [2][2]
                            result[191:176] <= $signed(src1[191:176]) * $signed(src2[15:0]); // [2][3]
                            result[207:192] <= $signed(src1[207:192]) * $signed(src2[15:0]); // [3][0]
                            result[223:208] <= $signed(src1[223:208]) * $signed(src2[15:0]); // [3][1]
                            result[239:224] <= $signed(src1[239:224]) * $signed(src2[15:0]); // [3][2]
                            result[255:240] <= $signed(src1[255:240]) * $signed(src2[15:0]); // [3][3]
                        end
                        MScaleImm: begin
                            result[15:0] <= $signed(src1[15:0]) * $signed(src2[7:0]);
                            result[31:16] <= $signed(src1[31:16]) * $signed(src2[7:0]);
                            result[47:32] <= $signed(src1[47:32]) * $signed(src2[7:0]);
                            result[63:48] <= $signed(src1[63:48]) * $signed(src2[7:0]);
                            result[79:64] <= $signed(src1[79:64]) * $signed(src2[7:0]);
                            result[95:80] <= $signed(src1[95:80]) * $signed(src2[7:0]);
                            result[111:96] <= $signed(src1[111:96]) * $signed(src2[7:0]);
                            result[127:112] <= $signed(src1[127:112]) * $signed(src2[7:0]);
                            result[143:128] <= $signed(src1[143:128]) * $signed(src2[7:0]);
                            result[159:144] <= $signed(src1[159:144]) * $signed(src2[7:0]);
                            result[175:160] <= $signed(src1[175:160]) * $signed(src2[7:0]);
                            result[191:176] <= $signed(src1[191:176]) * $signed(src2[7:0]);
                            result[207:192] <= $signed(src1[207:192]) * $signed(src2[7:0]);
                            result[223:208] <= $signed(src1[223:208]) * $signed(src2[7:0]);
                            result[239:224] <= $signed(src1[239:224]) * $signed(src2[7:0]);
                            result[255:240] <= $signed(src1[255:240]) * $signed(src2[7:0]);
                        end
                        MMult1: begin
                            // [0][0]: row0 · col0
                            result[15:0]    <= $signed(src1[15:0])   * $signed(src2[15:0])
                                            + $signed(src1[31:16])  * $signed(src2[79:64])
                                            + $signed(src1[47:32])  * $signed(src2[143:128])
                                            + $signed(src1[63:48])  * $signed(src2[207:192]);
                            // [0][1]: row0 · col1
                            result[31:16]   <= $signed(src1[15:0])   * $signed(src2[31:16])
                                            + $signed(src1[31:16])  * $signed(src2[95:80])
                                            + $signed(src1[47:32])  * $signed(src2[159:144])
                                            + $signed(src1[63:48])  * $signed(src2[223:208]);
                            // [0][2]: row0 · col2
                            result[47:32]   <= $signed(src1[15:0])   * $signed(src2[47:32])
                                            + $signed(src1[31:16])  * $signed(src2[111:96])
                                            + $signed(src1[47:32])  * $signed(src2[175:160])
                                            + $signed(src1[63:48])  * $signed(src2[239:224]);
                            // [0][3]: row0 · col3
                            result[63:48]   <= $signed(src1[15:0])   * $signed(src2[63:48])
                                            + $signed(src1[31:16])  * $signed(src2[127:112])
                                            + $signed(src1[47:32])  * $signed(src2[191:176])
                                            + $signed(src1[63:48])  * $signed(src2[255:240]);

                            // [1][0]: row1 · col0
                            result[79:64]   <= $signed(src1[79:64])  * $signed(src2[15:0])
                                            + $signed(src1[95:80])  * $signed(src2[79:64])
                                            + $signed(src1[111:96]) * $signed(src2[143:128])
                                            + $signed(src1[127:112])* $signed(src2[207:192]);
                            // [1][1]: row1 · col1
                            result[95:80]   <= $signed(src1[79:64])  * $signed(src2[31:16])
                                            + $signed(src1[95:80])  * $signed(src2[95:80])
                                            + $signed(src1[111:96]) * $signed(src2[159:144])
                                            + $signed(src1[127:112])* $signed(src2[223:208]);
                            // [1][2]: row1 · col2
                            result[111:96]  <= $signed(src1[79:64])  * $signed(src2[47:32])
                                            + $signed(src1[95:80])  * $signed(src2[111:96])
                                            + $signed(src1[111:96]) * $signed(src2[175:160])
                                            + $signed(src1[127:112])* $signed(src2[239:224]);
                            // [1][3]: row1 · col3
                            result[127:112] <= $signed(src1[79:64])  * $signed(src2[63:48])
                                            + $signed(src1[95:80])  * $signed(src2[127:112])
                                            + $signed(src1[111:96]) * $signed(src2[191:176])
                                            + $signed(src1[127:112])* $signed(src2[255:240]);

                            // [2][0]: row2 · col0
                            result[143:128] <= $signed(src1[143:128])* $signed(src2[15:0])
                                            + $signed(src1[159:144])* $signed(src2[79:64])
                                            + $signed(src1[175:160])* $signed(src2[143:128])
                                            + $signed(src1[191:176])* $signed(src2[207:192]);
                            // [2][1]: row2 · col1
                            result[159:144] <= $signed(src1[143:128])* $signed(src2[31:16])
                                            + $signed(src1[159:144])* $signed(src2[95:80])
                                            + $signed(src1[175:160])* $signed(src2[159:144])
                                            + $signed(src1[191:176])* $signed(src2[223:208]);
                            // [2][2]: row2 · col2
                            result[175:160] <= $signed(src1[143:128])* $signed(src2[47:32])
                                            + $signed(src1[159:144])* $signed(src2[111:96])
                                            + $signed(src1[175:160])* $signed(src2[175:160])
                                            + $signed(src1[191:176])* $signed(src2[239:224]);
                            // [2][3]: row2 · col3
                            result[191:176] <= $signed(src1[143:128])* $signed(src2[63:48])
                                            + $signed(src1[159:144])* $signed(src2[127:112])
                                            + $signed(src1[175:160])* $signed(src2[191:176])
                                            + $signed(src1[191:176])* $signed(src2[255:240]);

                            // [3][0]: row3 · col0
                            result[207:192] <= $signed(src1[207:192])* $signed(src2[15:0])
                                            + $signed(src1[223:208])* $signed(src2[79:64])
                                            + $signed(src1[239:224])* $signed(src2[143:128])
                                            + $signed(src1[255:240])* $signed(src2[207:192]);
                            // [3][1]: row3 · col1
                            result[223:208] <= $signed(src1[207:192])* $signed(src2[31:16])
                                            + $signed(src1[223:208])* $signed(src2[95:80])
                                            + $signed(src1[239:224])* $signed(src2[159:144])
                                            + $signed(src1[255:240])* $signed(src2[223:208]);
                            // [3][2]: row3 · col2
                            result[239:224] <= $signed(src1[207:192])* $signed(src2[47:32])
                                            + $signed(src1[223:208])* $signed(src2[111:96])
                                            + $signed(src1[239:224])* $signed(src2[175:160])
                                            + $signed(src1[255:240])* $signed(src2[239:224]);
                            // [3][3]: row3 · col3
                            result[255:240] <= $signed(src1[207:192])* $signed(src2[63:48])
                                            + $signed(src1[223:208])* $signed(src2[127:112])
                                            + $signed(src1[239:224])* $signed(src2[191:176])
                                            + $signed(src1[255:240])* $signed(src2[255:240]);
                        end
                        default: ;
                    endcase
                end
                default: ;
            endcase
        end
    end

    // Tristate Read
    assign Dataout = (AluEn && !nRead) ?
                     (offset == AluStatusOut ? 256'd0 :
                     offset == ALU_Result ? result : 'z)
                     : 'z;
endmodule
`default_nettype wire