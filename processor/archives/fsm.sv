`default_nettype none
`timescale 1ns/1ns
/* fsm.sv
 * Purpose:
 *  Controls the sequencing of instruction execution through fetch, decode,
 *  execute, and write-back phases.
 *
 * Functions:
 * - Manage instruction life cycles.
 * - Control PC updates, memory accesses, and ALU operations.
 * - Stall execution for multi-cycle operations.
 * - Halt execution on `STOP` instruction.
 *
 * Modules:
 * - fsm: Central execution control module.
 *
 * Notes:
 * - All control decisions originate here.
 * - Datapath modules perform no autonomous control.
 *
 * Top-Level FSM:
 *
 *        nReset=0
 *           |
 *           v
 *        [RESET] --> [FETCH] --> [DECODE] --> [EXECUTE] --> [WRITEBACK]
 *                       ^                         |               |
 *                       |                         v               |
 *                    [HALT] <-- opcode=FF    (sub-FSM)           |
 *                                                                 |
 *                                             pc++, next instr <-+
 *
 * EXECUTE Sub-States:
 *  Matrix ops (MAdd, MSub, MTranspose, MScale, MScaleImm, MMult1):
 *
 *   EX_IDLE --> EX_RD_SRC1 --> EX_LAT_SRC1 --> EX_RD_SRC2 --> EX_LAT_SRC2
 *                                                                     |
 *               EX_WRITE_DEST <-- EX_RD_RESULT <-- EX_FIRE <-- EX_WR_OPCODE
 *                    |                                               |
 *                    +---> (WRITEBACK)                         EX_WR_SRC1
 *                                                                    |
 *                                                              EX_WR_SRC2
 *                                                                    |
 *                                                               EX_FIRE
 *
 *  Integer ops (IntAdd, IntSub, IntMult, IntDiv):
 *   EX_IDLE --> EX_RD_SRC1 --> EX_LAT_SRC1 --> EX_RD_SRC2 --> EX_LAT_SRC2
 *                                                                     |
 *                                              EX_WRITE_DEST <-- EX_FIRE
 *                                                   |
 *                                              (WRITEBACK)
 *
 *  Branch ops (BEQ, BLT):
 *   EX_IDLE --> EX_FIRE --> (WRITEBACK, PC updated conditionally)
 *
 * Operand Encoding (from instruction word [31:0]):
 *  [31:24] opcode
 *  [23:16] dest   — MSB=1 means InternalReg index, MSB=0 means MainMemory address
 *  [15:8]  src1   — same encoding
 *  [7:0]   src2   — same encoding (or immediate for MScaleImm)
 *
 * Address Formation:
 *  MainMemory  : {4'h0, operand[6:0], 5'b0}  (lower 7 bits not on bus per spec)
 *  MatrixALU   : {4'h2, 8'b0, offset[3:0]}
 *  IntegerALU  : {4'h3, 8'b0, offset[3:0]}
 *
 *    Block Diagram:
 *
 *                        +----------------------------------+
 *    Clk    -----------> |                                  |
 *    nReset -----------> |           Execution              |---> address [15:0]
 *    Dataout <---------> |                                  |---> nRead
 *                        |  +------+  +--------+  +-----+   |---> nWrite
 *                        |  |  PC  |  | Decode |  |Fetch|   |
 *                        |  +------+  +--------+  +-----+   |
 *                        +----------------------------------+
 */

/* Execution
 * Purpose:
 *  Central execution control module.
 */
//`include "params.vh"
module Execution (
    input logic Clk,
    inout tri [DATA_W-1:0] Dataout,
    output logic [ADDR_W-1:0] address,
    output logic nRead, // driven by the main fsm block
    output logic nWrite,
    input logic nReset
);
   // Internal signals
   logic [DATA_W-1:0] InternalReg [3:0];
   logic [ADDR_W-1:0] branch_target;
   logic take;

   // tristate assignment
   logic [DATA_W-1:0] busout;
   logic writeMe;
   assign Dataout = writeMe ? busout : 'z;

   // ======================================
   // Sub-Modules
   // ======================================
   // Program Counter
   logic [ADDR_W-1:0] pc_curr, pc_next, pc_inc;
   logic pc_we;
   PC u_pc (
      .clk(Clk), 
      .rst(~nReset), 
      .pc_we(pc_we),
      .pc_next(pc_next), 
      .pc_curr(pc_curr), 
      .pc_inc(pc_inc));

   // Instruction Decode
   logic hit; 
   logic [2:0] did;
   Decode u_dec (
      .rd(~nRead), 
      .wr(~nWrite), 
      .addr(address), 
      .hit(hit), 
      .did(did)
   );

   // Instruction Fetch
   logic [INSTR_W-1:0] instr;
   logic fetch_valid;
   logic fetch_rd;   // Read coming from fetch stage
   logic [ADDR_W-1:0] fetch_addr;
   Fetch u_fetch (
      .clk(Clk), 
      .rst(~nReset), 
      .hold(1'b0), 
      .flush(1'b0),
      .pc_curr(pc_curr), 
      .hit(hit), 
      .did(did),
      .drom_data(Dataout[INSTR_W-1:0]),
      .addr(fetch_addr), 
      .rd(fetch_rd), 
      .instr(instr), 
      .valid(fetch_valid)
   );

   /* Instruction Field Decode
    * Opcode :: dest :: src1 :: src2 (8 bits each)
    * MSB of dest/scc fields: 0=MainMemory, 1=InternalReg
    */
    logic [7:0] opcode, dest, src1, src2;
    assign opcode = instr[31:24];
    assign dest = instr[23:16];
    assign src1 = instr[15:8];
    assign src2 = instr[7:0];

   // Operand reference
   logic destReg, src1Reg, src2Reg;
   assign destReg = (dest >= 8'h10) && (dest <= 8'h13);
   assign src1Reg = (src1 >= 8'h10) && (src1 <= 8'h13);
   assign src2Reg = (src2 >= 8'h10) && (src2 <= 8'h13);

   /* Execution Engine States
    * RESET: reset the behavior of the CPU
    * FETCH: fetches the next instruction
    * DECODE: decodes said instruction
    * EXECUTE: executes the decoded instruction
    * WRITEBACK: writes back to memory
    */
   typedef enum logic [2:0] {
      RESET, 
      FETCH, 
      DECODE, 
      EXECUTE, 
      WRITEBACK, 
      HALT
   } state_t;
   state_t state;

   /* Execution Sub-Stages
    * IDLE: entry point dispatched by opcode
    * RD_SRC1: asserts nRead for src1
    * LAT_SRC1: latches Databus to temp1
    * RD_SRC2: asserts nRead for src2
    * LAT_SRC2: latches Databus to temp2
    * WR_OP: writes opcode to ALUStatusIn
    * WR_SRC1: writes temp1 to ALU_Source1
    * WR_SRC2: writes temp2 to ALU_Source2
    * START: write to ALU_Result
    * RD_RES: read ALU_Result
    * LAT_RES: latch ALU_Result to temp3
    * WR_DEST: write ALU_Result to dest
    * LAT_DEST: Hold ALU_Result
    */
   typedef enum logic [3:0] {
      IDLE,
      RD_SRC1,
      LAT_SRC1,
      RD_SRC2,
      LAT_SRC2,
      WR_OP,
      WR_SRC1,
      WR_SRC1_HOLD,
      WR_SRC2,
      WR_SRC2_HOLD,
      START,
      RD_RES,
      LAT_RES,
      WR_DEST,
      LAT_DEST
   } ex_state_t;
   ex_state_t ex_state;

   // Temp storage for operands and results
   logic [DATA_W-1:0] temp1, temp2, temp3;

   always_ff @(posedge Clk or negedge nReset) begin
      if (!nReset) begin   // Initialize on reset
         // Execution FSM parameters
         state <= RESET;
         nRead <= 1;
         nWrite <= 1;
         pc_we <= 0;
         pc_next <= '0;
         address <= '0;

         // Sub-FSM parameters
         ex_state <= IDLE;
         writeMe <= 0;
         busout <= '0;
         temp1 <= '0;
         temp2 <= '0;
         temp3 <= '0;
         InternalReg[0] <= '0;
         InternalReg[1] <= '0;
         InternalReg[2] <= '0;
         InternalReg[3] <= '0;
      end else begin
         // Debug ================================
         $display("t=%0t | state=%-10s ex=%-12s | op=%02h d=%02h s1=%02h s2=%02h | PC=%04h",
             $time, state.name(), ex_state.name(),
             opcode, dest, src1, src2, pc_curr);
         // ======================================
         case (state)
            RESET: begin
               state <= FETCH;
               address <= 16'h1000; // Point to InstrMem
               nRead <= 0;
            end   // RESET ================================================
            FETCH: begin
               pc_we <= 0;
               if (fetch_valid) state <= DECODE;
            end   // FETCH ================================================
            DECODE: begin
               nRead <= 1;
               if (opcode == 8'hFF) state <= HALT;
               else begin
                  state <= EXECUTE;
               end
            end   // DECODE ================================================
            EXECUTE: begin
               case (ex_state)
                  // Entry Point
                  IDLE: begin
                     writeMe <= 0;

                     // Branches compares InternalRegs
                     if (opcode == BEQ || opcode == BLT || 
                         opcode == 8'h20 || opcode == 8'h23) begin
                        ex_state <= START; // Start ALU operation
                     end else begin
                        if (src1Reg) begin   // src1 is already in an InternalReg
                           temp1 <= InternalReg[src1[1:0]];
                           nRead <= 1;
                           ex_state <= RD_SRC2; // Read src2
                        end else begin         // src1 is a MainMem address
                           address <= {MainMem[3:0], 8'b0, src1[3:0]};;
                           nRead <= 0;
                           ex_state <= RD_SRC1; // Read src1
                        end
                     end
                  end   // IDLE =============================================================
                  RD_SRC1: begin // Hold nRead so memory can be read
                     ex_state <= LAT_SRC1;
                  end   // RD_SRC1 ===========================================================
                  LAT_SRC1: begin
                     temp1 <= Dataout;
                     nRead <= 1;
                     ex_state <= RD_SRC2;
                  end   // LAT_SRC1 ==========================================================
                  RD_SRC2: begin
                     // Load src 2
                     if (opcode == MScaleImm) begin  
                        temp2 <= {{(DATA_W-8){1'b0}}, src2};
                        ex_state <= WR_OP;
                     end else if (src2Reg) begin   // src2 is already in an InternalReg
                        temp2 <= InternalReg[src2[1:0]];
                        ex_state <= WR_OP;
                     end else begin                // src2 is a MainMem address
                        address <= {MainMem[3:0], 8'b0, src2[3:0]};
                        nRead <= 0;
                        ex_state <= LAT_SRC2;
                     end
                  end   // RD_SRC2 ===========================================================
                  LAT_SRC2: begin   // Hold nRead so memory can be read
                     temp2 <= Dataout;
                     nRead <= 1;
                     ex_state <= WR_OP;
                  end   // LAT_SRC2 ==========================================================
                  WR_OP: begin   // Write the opcode to ALUStatusIn
                  // StatusIn is offset 0: {base, 8'b0, 4'h0}
                     writeMe <= 1;
                     busout <= {{(DATA_W-8){1'b0}}, opcode};
                     case (opcode)
                        MMult1, MAdd, MSub, 
                        MTranspose, MScale, MScaleImm: begin   // Matrix ALU opcode is 2000h
                           address <= {MatrixAlu[3:0], 8'b0, 4'(AluStatusIn)};
                        end
                        default: begin // Integer ALU opcode is 3000h
                           address <= {IntAlu[3:0], 8'b0, 4'(AluStatusIn)};
                        end
                     endcase
                     nWrite <= 0;
                     ex_state <= WR_SRC1;
                  end   // WR_OP ===========================================================
                  WR_SRC1: begin // Write src1 to ALU_Source1
                  // Source1 is offset 2: {base, 8'b0, 4'h2}
                     nWrite <= 1;
                     busout <= temp1;
                     case (opcode)
                        MMult1, MAdd, MSub, 
                        MTranspose, MScale, MScaleImm: begin   // Matrix ALU opcode is 2000h
                           address <= {MatrixAlu[3:0], 8'b0, 4'(ALU_Source1)};
                        end
                        default: begin // Integer ALU opcode is 3000h
                           address <= {IntAlu[3:0], 8'b0, 4'(ALU_Source1)};
                        end
                     endcase
                     ex_state <= WR_SRC1_HOLD;
                  end   // WR_SRC1 ===========================================================
                  WR_SRC1_HOLD: begin
                     nWrite <= 0;
                     ex_state <= WR_SRC2;
                  end
                  WR_SRC2: begin // Write src2 to ALU_Source2
                  // Source2 is offset 3: {base, 8'b0, 4'h3}
                     nWrite <= 1;
                     busout <= temp2;
                     case (opcode)
                        MMult1, MAdd, MSub, 
                        MTranspose, MScale, MScaleImm: begin   // Matrix ALU opcode is 2000h
                           address <= {MatrixAlu[3:0], 8'b0, 4'(ALU_Source2)};
                        end
                        default: begin // Integer ALU opcode is 3000h
                           address <= {IntAlu[3:0], 8'b0, 4'(ALU_Source2)};
                        end
                     endcase
                     ex_state <= WR_SRC2_HOLD;
                  end   // WR_SRC2 ===========================================================
                  WR_SRC2_HOLD: begin
                     nWrite <= 0;
                     ex_state <= START;
                  end
                  START: begin   // Start ALU operation
                     nWrite <= 1;
                     if (opcode == BEQ || opcode == BLT ||
                        opcode == 8'h20 || opcode == 8'h23) begin
                        
                        case (opcode)
                           8'h20: begin
                              take = (InternalReg[src1[1:0]] != InternalReg[src2[1:0]]);   // BNE
                           end
                           BEQ: begin
                              take = (InternalReg[src1[1:0]] == InternalReg[src2[1:0]]); // BEQ
                           end
                           BLT: begin
                              take = ($signed(InternalReg[src1[1:0]][15:0])
                              < $signed(InternalReg[src2[1:0]][15:0])); // BLT
                           end
                           8'h23: begin
                              take = ($signed(InternalReg[src1[1:0]][15:0])
                              > $signed(InternalReg[src2[1:0]][15:0])); // BGE
                           end
                           default: begin
                              take = 0;
                           end
                        endcase

                        // Debug ================================
                        $display("t=%0t | BRANCH op=%02h dest(offset)=%02h | reg[s1]=%0d reg[s2]=%0d | take=%b target=%04h",
                           $time, opcode, dest,
                           InternalReg[src1[1:0]], InternalReg[src2[1:0]],
                           take, branch_target);
                        // ======================================

                        // Advance PC base on branch
                        branch_target = take ? (pc_curr + {{(ADDR_W-8){dest[7]}}, dest}) : pc_inc;
                        pc_next  <= branch_target;
                        pc_we    <= 1;
                        ex_state <= IDLE;
                        state    <= FETCH;
                        nRead    <= 0;
                        address  <= {InstrMem[3:0], branch_target[LOCAL_W-1:0]};
                     end else begin // Write result to ALU_Result
                     // Result is offset 4: {base, 8'b0, 4'h4}
                        writeMe <= 1;
                        busout <= '0;
                        case (opcode)
                           MMult1, MAdd, MSub, 
                           MTranspose, MScale, MScaleImm: begin   // Matrix ALU opcode is 2000h
                              address <= {MatrixAlu[3:0], 8'b0, 4'(ALU_Result)};
                           end
                           default: begin // Integer ALU opcode is 3000h
                              address <= {IntAlu[3:0], 8'b0, 4'(ALU_Result)};
                           end
                        endcase
                        nWrite <= 0;
                        ex_state <= RD_RES;
                     end
                  end   // START ===========================================================
                  RD_RES: begin  // Read result from ALU_Result
                  // Result is offset 4: {base, 8'b0, 4'h4}
                     nWrite <= 1;
                     writeMe <= 0;
                     case (opcode)
                        MMult1, MAdd, MSub, 
                        MTranspose, MScale, MScaleImm: begin   // Matrix ALU opcode is 2000h
                           address <= {MatrixAlu[3:0], 8'b0, 4'(ALU_Result)};
                        end
                        default: begin // Integer ALU opcode is 3000h
                           address <= {IntAlu[3:0], 8'b0, 4'(ALU_Result)};
                        end
                     endcase
                     nRead <= 0;
                     ex_state <= LAT_RES;
                  end   // RD_RES ===========================================================
                  LAT_RES: begin // Wait for result to be ready
                     // Debug ===============================
                     $display("t=%0t | LAT_RES: Dataout=%h (latching to temp3)",
                        $time, Dataout);
                     // =====================================
                     temp3 <= Dataout;
                     nRead <= 1;
                     ex_state <= WR_DEST;
                  end   // LAT_RESULT =======================================================
                  WR_DEST: begin
                     // Debug ===============================
                     $display("t=%0t | WR_DEST: destReg=%b dest=%02h temp3=%h",
                              $time, destReg, dest, temp3);
                     // =====================================
                     if (destReg) begin
                        InternalReg[dest[1:0]] <= temp3;
                        writeMe <= 0;
                        ex_state <= IDLE;
                        state <= WRITEBACK;
                     end else begin
                        writeMe <= 1;
                        busout  <= temp3;
                        address <= {MainMem[3:0], 8'b0, dest[3:0]};
                        nWrite  <= 0;
                        ex_state <= LAT_DEST;
                     end
                  end
                  LAT_DEST: begin
                     $display("t=%0t | LAT_DEST: addr=%04h nWrite=%b bus=%h", 
                              $time, address, nWrite, Dataout);
                     nWrite  <= 1;
                     writeMe <= 0;
                     ex_state <= IDLE;
                     state <= WRITEBACK;
                  end
               endcase
            end   // EXECUTE ================================================
            WRITEBACK: begin
               // Debug ===============================
               $display("t=%0t | WRITEBACK: pc_curr=%04h pc_inc=%04h next_fetch=%04h",
                        $time, pc_curr, pc_inc,
                        {InstrMem[3:0], pc_inc[LOCAL_W-1:0]});
               // =====================================
               // advance PC
               nWrite <= 1;
               writeMe <= 0;
               pc_next <= pc_inc;
               pc_we <= 1;
               state <= FETCH;
               nRead <= 0;
               address <= {InstrMem[3:0], pc_inc[LOCAL_W-1:0]};  // Point to next instruction
            end   // WRITEBACK ===============================================
            HALT: begin
               nRead  <= 1;
               nWrite <= 1;
               writeMe  <= 0;
            end   // HALT ================================================
         endcase
      end
   end
endmodule
`default_nettype wire