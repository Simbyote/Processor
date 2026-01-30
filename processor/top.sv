`timescale 1ns/1ps
`default_nettype none
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
 * - (possible instantiator module for CPU, memory, etc.):
 *   if main top module becomes too dense, consider breaking it down.
 *
 * Notes:
 * - Contains no behavioral logic; purely structural design.
 */
module top;
    // Signal wires
    logic rd, wr;
    logic [15:0] addr;
    logic hit;
    logic [2:0] did;

    // Instantiate sub-modules
    decode dut (
        .rd(rd),
        .wr(wr),
        .addr(addr),
        .hit(hit),
        .did(did)
    );

    // Instantiate testing module
    decode_tb stim (
        .hit(hit),
        .did(did),
        .rd(rd),
        .wr(wr),
        .addr(addr)
    );

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, top);
    end

endmodule
`default_nettype wire