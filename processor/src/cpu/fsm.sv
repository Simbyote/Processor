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
 */

/* Execution
 * Purpose:
 *  Central execution control module.
 */
module Execution (
    input  logic Clk,
    inout  tri [DATA_W-1:0] Dataout,
    output logic [ADDR_W-1:0] address,
    output logic nRead, // driven by the main fsm block
    output logic nWrite,
    input  logic nReset
);
   logic [DATA_W-1:0] InternalReg [3:0];

   // Temp assignment   -- DELETE ME --
   assign Dataout = 'z;

   // Internal signals
   logic fetch_rd;   // Read coming from fetch stage
   logic [ADDR_W-1:0] fetch_addr;

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

   // Execution Engine States
   typedef enum logic [2:0] {
      RESET, 
      FETCH, 
      DECODE, 
      EXECUTE, 
      WRITEBACK, 
      HALT
   } state_t;
   state_t state;

   // Signal Composition
   // OPcode :: dest :: src1 :: src2
   logic [7:0]  opcode;
   logic [7:0]  dest, src1, src2;
   assign opcode = instr[31:24];
   assign dest   = instr[23:16];
   assign src1   = instr[15:8];
   assign src2   = instr[7:0];

   always_ff @(posedge Clk or negedge nReset) begin
      if (!nReset) begin
         state   <= RESET;
         nRead   <= 1;
         nWrite  <= 1;
         pc_we   <= 0;
         pc_next <= '0;
      end else begin
         case (state)
               RESET: begin
                  state <= FETCH;
                  nRead <= 0;
               end
               FETCH: begin
                  if (fetch_valid) state <= DECODE;
               end
               DECODE: begin
                  nRead <= 1;
                  if (opcode == 8'hFF) state <= HALT;
                  else begin
                     state <= EXECUTE;
                  end
               end
               EXECUTE: begin
                  state <= WRITEBACK;
               end
               WRITEBACK: begin
                  // advance PC
                  pc_next <= pc_inc;
                  pc_we   <= 1;
                  state   <= FETCH;
                  nRead   <= 0;
               end
               HALT: begin
                  nRead  <= 1;
                  nWrite <= 1;
               end
         endcase
      end
   end
endmodule
`default_nettype wire