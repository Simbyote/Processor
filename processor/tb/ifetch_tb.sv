`default_nettype none
`timescale 1ns/1ps
/* ifetch_tb.sv
 * Purpose:
 *  Drives the instruction fetch module and observes its outputs:
 *
 * Drivers:
 * - pc_we: Asserted to update the program counter
 * - pc_next: Program counter value to update
 * - hold: Asserted to hold the program counter
 * - flush: Asserted to flush the program counter
 * - rst: Asserted to reset the program counter
 *
 * Observers:
 * - pc_curr: Current program counter value
 * - addr: Address of instruction memory to request
 * - rd: Asserted to request instruction memory
 * - hit: Asserted if the address is in a valid range
 * - did: Device ID value of the address
 * - instr: Instruction value
 * - valid: Asserted if the instruction is valid
 *
 * Functions:
 * - Produce an address for instruction memory
 * - Use said address to request instruction memory
 * - Classify the address
 * - Verifies and latches the instruction
 *
 * Modules:
 * - ifetch_tb: Testbench for instruction fetch module
 *
 * Notes:
 * 
 */
import params_pkg::*;
module ifetch_tb (
    input wire [ADDR_W-1:0] pc_curr,
    input wire [ADDR_W-1:0] addr,
    input wire rd,
    input wire hit,
    input wire [2:0] did,
    input wire [INSTR_W-1:0] instr,
    input wire valid,

    output logic clk,
    output logic rst,
    output logic pc_we,
    output logic [ADDR_W-1:0] pc_next,
    output logic hold,
    output logic flush
);
    localparam DBASE = 12'h000;   // Base address of instruction ROM
    localparam DINC = 12'h004;    // Increment per instruction (4 bytes)
    localparam DROM = 3'b001;     // Device ID value decode for ROM

    // Local wires
    logic [ADDR_W-1:0] pc_inc;
    logic [2:0] did_rom;

    // Initialize clock and reset signals
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    initial begin
        rst = 1;
        repeat (2) @(posedge clk);
        rst = 0;
    end

    /* Test 1. Constants and Expected Behavior
     * Define:
     * - A start address of instruction ROM region (DBASE)
     * - An increment per instruction (DINC)
     * - The device ID value decode for ROM (DROM)
     * Expected:
     * - `addr == pc_curr`: the address is the same as the program counter
     * `hit == 1`: the address is in a valid range
     * `did == DROM`: the address is in the ROM region
     * `valid == 1`: valid is asserted on the next cycle
     *
     * Notes:
     * - `valid` asserts in the next cycle after `hit`/`did` is verified
     */
     
     /* Test 2: Reset Phase
      * Let:
      * - An existing reset run `rst = 1` for two cycles, then `rst = 0`
      * - After reset drops, wait 1 cycle to avoid sampling
      * Expected:
      * - `pc_curr` is a known value
      * - `addr` is equal to `pc_curr`
      * - `valid` is deasserted on the next cycle
      */

      /* Test 3: Drive First PC Value
       * Stim:
       * - `pc_we = 1`: the program counter is updated
       * - `pc_next = DBASE`: the program counter is updated to DBASE
       * - `hold = 0`: the program counter is not held
       * - `flush = 0`: the program counter is not flushed
       * - In the next cycle: `pc_we = 0`: the program counter is no longer updated
       * Expected:
       * - `rd == 1`: the instruction memory is requested
       * - `pc_curr == DBASE`: the program counter is updated to DBASE
       * - `addr == pc_curr`: the address is the same as the program counter
       * - decode indicates ROM: `hit == 1`, `did == DROM`
       * - `valid == 1`: valid is asserted on the next cycle if ROM is hit
       */

       /* Test 4. Three Sequential Checks
        * Repeat 3 times:
        * - On a clock edge: `pc_we = 1`, `pc_next = pc_curr + DINC`
        * - On next edge: `pc_we = 0`
        * Expected:
        * - `pc_curr` advances exactly by `DINC`
        * - `addr == pc_curr`: the address is the same as the program counter
        * - decode indicates ROM: `hit == 1`, `did == DROM`
        * - `valid == 1`: the instruction is asserted on the next cycle
        */

        /* Test 5. Stop Condition
         * Stim:
         * - Set `pc_we = 0` for two clock cycles
         * Expected:
         * - `pc_curr` stops changing
         * - `addr` stops changing
         * - `valid` is is deasserted (depends on implementation)
         */
    
    initial begin
        // Test 1: Constants and Expected Behavior
        @(posedge clk);
        pc_next = DBASE;
        hold = 0;
        flush = 0;
        @(posedge clk);
        pc_we = 1;
        @(posedge clk);
        pc_we = 0;

        // Test 2: Reset Phase
        rst = 1;
        @(posedge clk);
        rst = 0;

        // Test 3: Drive First PC Value
        @(posedge clk);
        pc_next = DBASE;
        hold = 0;
        flush = 0;
        @(posedge clk);
        pc_we = 1;
        @(posedge clk);
        pc_we = 0;

        // Test 4: Three Sequential Checks
        repeat (3) begin
            @(posedge clk);
            pc_next = pc_curr + DINC;
            hold = 0;
            flush = 0;
            @(posedge clk);
            pc_we = 1;
            @(posedge clk);
            pc_we = 0;
        end

        // Test 5: Stop Condition
        @(posedge clk);
        pc_we = 0;
        repeat (10) @(posedge clk) begin
            pc_next = pc_next + DINC; // Drive pc_next to verify that pc_curr and addr stop changing
        end
        // Drive pc_next to verify that pc_curr and addr stop changing
        pc_we = 1;
        @(posedge clk);
        pc_we = 0;

        // Now the pc should be updated to the current pc_next value
        // addr should be updated to the current pc_next value
        #100;
        $finish;
    end
endmodule
`default_nettype wire