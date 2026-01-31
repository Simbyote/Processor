`default_nettype none
`timescale 1ns/1ps
/* top.sv
 * Purpose:
 *  Integrates all processor sub-modules and connects them according to
 *  the system architecture. 
 *
 * Functions:
 * - Instantiate and interconnect CPU, memory, ALUs, and IO
 * - Comply with a top module interface
 *
 * Modules:
 * - top: Top-level module integrating all components
 * - decode_dut: Initializes decode logic 
 * - ifetch_dut: Initializes frontend pc-fetch-decode logic
 *
 * Notes:
 * - Contains no behavioral logic; purely structural design.
 *
 */
import params_pkg::*;
module top;
    // Instantiate the `.top` to be tested
    ifetch_top root();
endmodule

/* ifetch_top
 * Purpose:
 *  Top-level testbench for the instruction fetch module.
 */
module ifetch_top;
    // Clock and reset signals
    logic clk, rst;

    // Top level interface
    logic pc_we, hold, flush;
    logic [ADDR_W-1:0] pc_next, pc_curr;
    logic [INSTR_W-1:0] instr;
    logic valid;

    // Testing interface
    logic [ADDR_W-1:0] addr;
    logic rd;
    logic hit;
    logic [2:0] did;

    // Initialize DUT
    ifetch_dut dut (
        .clk(clk),
        .rst(rst),
        .pc_we(pc_we),
        .hold(hold),
        .flush(flush),
        .pc_next(pc_next),
        //===============
        .pc_curr(pc_curr),
        .instr(instr),
        .valid(valid),
        //===============
        .addr(addr),
        .rd(rd),
        .hit(hit),
        .did(did)
    );

    // Register clock and reset signals and initialize tests
    ifetch_tb stim (
        .pc_curr(pc_curr),
        .addr(addr),  
        .rd(rd),
        .hit(hit),
        .did(did),
        .instr(instr),
        .valid(valid),
        //===============
        .clk(clk),
        .rst(rst),
        .pc_we(pc_we),
        .pc_next(pc_next),
        .hold(hold),
        .flush(flush)
    );

    initial begin
        $dumpfile("ifetch.vcd");
        $dumpvars(0, ifetch_top);
    end
endmodule

/* decode_top
 * Purpose:
 *  Initializes dut for testing decode logic
 *
 * Inputs:
 * - rd: Read signal
 * - wr: Write signal
 * - addr: Address bus
 *
 * Outputs:
 * - hit: Decode hit signal
 * - did: Decode did signal
 */
module decode_top;
    // Signal wires
    logic rd, wr;
    logic [ADDR_W-1:0] addr;
    logic hit;
    logic [2:0] did;

    // Instantiate sub-modules
    decode dut (
        .rd(rd),
        .wr(wr),
        .addr(addr),
        //===============
        .hit(hit),
        .did(did)
    );

    // Instantiate testing module
    decode_tb stim (
        .hit(hit),
        .did(did),
        //===============
        .rd(rd),
        .wr(wr),
        .addr(addr)
    );

    initial begin
        $dumpfile("decode.vcd");
        $dumpvars(0, decode_top);
    end
endmodule


/* ifetch_dut
 * Purpose:
 *  Initializes dut for testing pc-fetch-decode logic
 *
 * Inputs:
 * - clk: Clock signal
 * - rst: Reset signal
 * - pc_we: PC write enable signal
 * - hold: Hold signal
 * - flush: Flush signal
 * - pc_next: Next PC value
 *
 * Outputs:
 * - pc_curr: Current PC value
 * - instr: Instruction value
 * - valid: Valid signal
 *
 * Wiring Diagram:
 * Overall architecture:

            +-----+
           | top |
           +-----+
            / |  \
           /  |   \
         PC  FETCH  DECODE


 * Internal architecture:

              +-------+
             |  PC   |
             +-------+
                 |
                 v
             pc_curr
                 |
                 v
           +------------+
           |   FETCH    |
           +------------+
             |        |
             |        v
             |      addr ----+
             |               |
             v               v
           instr          +--------+
           valid <--------| DECODE |
                          +--------+
                            |   |
                            |   +--> did
                            +------> hit

*/
// "params_pkg::ADDR_W" instead of "ADDR_W"
// "params_pkg::INSTR_W" instead of "INSTR_W"
module ifetch_dut (
    input wire clk,
    input wire rst,
    input wire pc_we,
    input wire hold,
    input wire flush,
    input wire [ADDR_W-1:0] pc_next,

    output logic [ADDR_W-1:0] pc_curr,
    output logic [INSTR_W-1:0] instr,
    output logic valid,

    output logic [ADDR_W-1:0] addr,
    output logic rd,
    output logic hit,
    output logic [2:0] did
);
    //===================
    // PC module
    //===================
    logic [ADDR_W-1:0] pc_inc;
    pc u_pc (
        .clk(clk),
        .rst(rst),
        .pc_we(pc_we),
        .pc_next(pc_next),
        //===============
        .pc_curr(pc_curr),
        .pc_inc(pc_inc)
    );

    //===================
    // Decode module
    //===================
    logic wr;
    assign wr = 1'b0; // Testing `rd` mode only
    decode u_decode (
        .rd(rd),
        .wr(wr),
        .addr(addr),
        //===============
        .hit(hit),
        .did(did)
    );

    //===================
    // Fetch module
    //===================
    logic [INSTR_W-1:0] drom_data;
    assign drom_data = '0;  // Temporary tie
    fetch u_fetch (
        .clk(clk),
        .rst(rst),
        .hold(hold),
        .flush(flush),
        .pc_curr(pc_curr),
        .hit(hit),
        .did(did),
        .drom_data(drom_data),
        //===============
        .addr(addr),
        .rd(rd),
        .instr(instr),
        .valid(valid)
    );
endmodule
`default_nettype wire