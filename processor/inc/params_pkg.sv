// inc/params_pkg.sv
`timescale 1ns/1ps
package params_pkg;
    // Global widths
    parameter int ADDR_W  = 16;
    parameter int DATA_W  = 256;
    parameter int INSTR_W = 32;
    // Adding regions for decode module? We currently want:
    // 4 for MSB
    // 12 for LSB
    // parameter int MOD_ADDR = ADDR_W - 12;
    // parameter int MOD_OFF = ADDR_W - 4;

    // Device IDs
    typedef enum logic [2:0] {
        DRAM = 3'd0,
        DROM = 3'd1,
        DMAT = 3'd2,
        DINT = 3'd3,
        DREG = 3'd4,
        DEXE = 3'd5,
        DSPI = 3'd6,
        DNON = 3'd7
    } did_t;

    // Memory Map?
endpackage
