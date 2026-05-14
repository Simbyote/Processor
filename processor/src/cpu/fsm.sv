`default_nettype none
`timescale 1ns/1ns
/* fsm.sv
 * Purpose:
 *  Controls the sequencing of instruction execution through fetch, decode,
 *  execute, and write-back phases
 *
 * Functions:
 * - Manage instruction life cycles
 * - Control PC updates, memory accesses, and ALU operations
 * - Stall execution for multi-cycle operations
 * - Halt execution on `STOP` instruction
 *
 * Modules:
 * - Execution: Central execution control module
 *
 *
 * FSM was experiencing bugs so I decided to split work into stages to
 * both reset the FSM status and control what happens downstream as more
 * complexity is added:
 * =========================================================================
 * Stage 0:
 * The Initial Skeleton of the FSM
 * =========================================================================
 * Stage 1:
 * The FSM is expanded into a nested state machine with wait states
 * =========================================================================
 *
 * Notes:
 * - All control decisions originate here.
 * - Datapath modules perform no autonomous control.
 * - Dataout drive (for writes) is deferred to Stage 2; bus is held 'z here.
 */

/* Execution
 * Purpose:
 *  Central execution control module
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
module Execution (
   input logic Clk,
   inout tri [DATA_W-1:0] Dataout,
   output logic [ADDR_W-1:0] address,
   output logic nRead,
   output logic nWrite,
   input logic nReset
);
   // Internal Registers
   // 4 × 256-bit general purpose registers
   logic [DATA_W-1:0] InternalReg [3:0];

   // Bus is unimplemented yet. Holds 'z' here
   assign Dataout = 'z;

   // Program Counter
   logic [ADDR_W-1:0] pc_curr, pc_next, pc_inc;
   logic pc_we;
   PC u_pc (
      .clk (Clk),
      .rst (~nReset),
      .pc_we (pc_we),
      .pc_next(pc_next),
      .pc_curr(pc_curr),
      .pc_inc (pc_inc)
   );

   /* Address Decode
    * rd/wr inputs are active-high inside Decode
    * nRead/nWrite are active-low on the bus
    * Inverted for Decode
    */
   logic hit;
   logic [2:0] did;
   Decode u_dec (
      .rd (~nRead),
      .wr (~nWrite),
      .addr(address),
      .hit (hit),
      .did (did)
   );

   // Fetch
   logic [INSTR_W-1:0] instr;
   logic fetch_valid;
   logic fetch_rd;
   logic [ADDR_W-1:0] fetch_addr;  // Latched from fetch
   Fetch u_fetch (
      .clk (Clk),
      .rst (~nReset),
      .hold (1'b0),
      .flush (1'b0),
      .pc_curr (pc_curr),
      .hit (hit),
      .did (did),
      .drom_data(Dataout[INSTR_W-1:0]),
      .addr (fetch_addr),
      .rd (fetch_rd),
      .instr (instr),
      .valid (fetch_valid)
   );

   /*
    * Encoding: opcode[31:24] | dest[23:16] | src1[15:8] | src2[7:0]
    * MSB of dest/src1/src2: 
    *   1 = InternalReg 
    *   0 = main memory word index
    */
   logic [7:0] opcode, dest, src1, src2;
   assign opcode = instr[31:24];
   assign dest = instr[23:16];
   assign src1 = instr[15:8];
   assign src2 = instr[7:0];

   /* FSM State Encoding
   * RESET: Reset the processor
   * FETCH: Fetch the next instruction
   * DECODE: Decode the instruction
   * EXECUTE: Execute the instruction
   * WRITEBACK: Write the result to the destination register
   * HALT: Halt the processor
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

   /* Sub-states used only while state is in EXECUTE
   *
   * Memory read sequence:
   *   EX_IDLE: Issues address and nRead for src1
   *   EX_WAIT1: Holds MainMemory to latch MemToOutput for src1
   *   EX_READ1: Samples src1 from Dataout, then issues address for src2
   *   EX_WAIT2: Holds MainMemory to latch MemToOutput for src2
   *   EX_READ2: Samples src2 from Dataout
   *   EX_READY: Both operands are in temp1 / temp2
   *
   * Every memory read sequence has a corresponding EX_WAIT state to allow for
   * latching MemToOutput
   */
   typedef enum logic [2:0] {
      EX_IDLE,
      EX_WAIT1,
      EX_READ1,
      EX_WAIT2,
      EX_READ2,
      EX_READY
   } ex_state_t;
   ex_state_t ex_state;

   // Temporary values
   logic [DATA_W-1:0] temp1;
   logic [DATA_W-1:0] temp2;

   // Main sequential block
   always_ff @(posedge Clk or negedge nReset) begin
      if (!nReset) begin
            // Set up initial state
            state <= RESET;
            ex_state <= EX_IDLE;
            nRead <= 1'b1;
            nWrite <= 1'b1;
            pc_we <= 1'b0;
            pc_next <= '0;
            address <= '0;
            temp1 <= '0;
            temp2 <= '0;

            // Zero internal registers
            InternalReg[0] <= '0;
            InternalReg[1] <= '0;
            InternalReg[2] <= '0;
            InternalReg[3] <= '0;
      end else begin
            case (state)
               RESET: begin  // Point the bus at instruction memory
                  state <= FETCH;
                  address <= 16'h1000;  // Instruction memory starts at 0x1000
                  nRead <= 1'b0;
               end
               FETCH: begin  // Hold until Fetch sub-module asserts fetch_valid
                  pc_we <= 1'b0;
                  if (fetch_valid) begin
                        state <= DECODE;
                  end
               end
               DECODE: begin // Decode the instruction
                  nRead <= 1'b1;   // Release bus
                  ex_state <= EX_IDLE;
                  if (opcode == 8'hFF) begin
                        state <= HALT;
                  end else begin
                        state <= EXECUTE;
                  end
               end
               EXECUTE: begin   // Execute the instruction
                     case (ex_state)
                        EX_IDLE: begin
                           if (src1[7]) begin  // If in register: latch immediately and jump to EX_READ1 to start on src2 
                                 temp1 <= InternalReg[src1[1:0]];
                              ex_state <= EX_READ1;
                           end else begin   // If in memory: issue the read and advance to EX_WAIT1
                                 address <= {{(ADDR_W-LOCAL_W){1'b0}}, {(LOCAL_W-7){1'b0}}, src1[6:0]};
                                 nRead <= 1'b0;
                              ex_state <= EX_WAIT1;
                           end
                        end
                        EX_WAIT1: begin   // Hold while MainMemory latches MemToOutput for src1
                           ex_state <= EX_READ1;
                        end
                        EX_READ1: begin   // Samples src1 from Dataout
                           if (!src1[7]) begin  // If src1 is in memory
                              temp1 <= Dataout;
                              nRead <= 1'b1;   // release bus before next read
                           end
                           if (src2[7]) begin   // If in register: begin src2 resolution
                              temp2 <= InternalReg[src2[1:0]];
                              ex_state <= EX_READY;   // Skip wait
                           end else begin   // If in memory: issue the read and advance to EX_WAIT2
                              // address = {4'h0, 12'b word_index}
                              address <= {{(ADDR_W-LOCAL_W){1'b0}}, {(LOCAL_W-7){1'b0}}, src2[6:0]};
                              nRead <= 1'b0;
                              ex_state <= EX_WAIT2;
                           end
                        end
                        EX_WAIT2: begin   // Hold while MainMemory latches MemToOutput for src2
                           ex_state <= EX_READ2;
                        end
                        EX_READ2: begin   // Sample src2 from bus
                           temp2 <= Dataout;
                           nRead <= 1'b1;
                           ex_state <= EX_READY;
                        end
                        EX_READY: begin   // Both operands are in temp1 / temp2
                           state <= WRITEBACK;
                           ex_state <= EX_IDLE;
                        end

                        default: begin
                           ex_state <= EX_IDLE;
                        end
                  endcase
               end
               WRITEBACK: begin  // Write the result to the destination register
                  pc_next <= pc_inc;
                  pc_we <= 1'b1;
                  state <= FETCH;
                  nRead <= 1'b0;
                  // InstrMem = 1, so upper nibble of address = 4'h1
                  address <= {InstrMem[3:0], pc_inc[LOCAL_W-1:0]};
               end
               HALT: begin // Halt the processor
                  nRead <= 1'b1;
                  nWrite <= 1'b1;
               end
               default: begin
                  state <= FETCH;
               end
            endcase
      end
   end
endmodule
`default_nettype wire