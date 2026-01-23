`timescale 1ns/1ps
`default_nettype none

/*
 *
 */
module decode_tb;
    // Internal wires
    logic rd, wr;
    logic [15:0] addr;
    wire hit;
    wire [2:0] did;

    // Instantiate the decode module
    decode decode_test (
        .rd(rd),
        .wr(wr),
        .addr(addr),
        .hit(hit),
        .did(did)
    );

    // Tests whether the decode module correctly identifies memory-mapped components
    `define GENERIC_DECODE(_rd, _wr, _addr, _hit, _did) \
    begin                                               \
        rd = (_rd);                                     \
        wr = (_wr);                                     \
        addr = (_addr);                                 \
        #0                                              \
        if (hit !== (_hit)) begin                       \
            $fatal(1,                                   \
                {"FATAL: hit mismatch:\n",              \
                " rd=%0b, wr=%0b, addr=0x%0h\n",        \
                " Expected: hit=%0b\n",                 \
                " Got: hit=%0b\n"},                     \
                rd, wr, addr, _hit, hit);               \
        end                                             \
        if (did !== (_did)) begin                       \
            $fatal(1,                                   \
                {"FATAL: did mismatch:\n",              \
                " rd=%0b, wr=%0b, addr=0x%0h\n",        \
                " Expected: did=%0b\n" ,                \
                " Got: did=%0b\n"},                     \
                rd, wr, addr, _did, did);               \
        end                                             \
        $display({                                      \
            "PASS: rd=%0b wr=%0b addr=0x%0h\n",         \ 
            " hit=%0b did=%0d\n"},                      \
         rd, wr, addr, hit, did);                       \
    end

    initial begin
        $dumpfile( "decode.vcd" );
        $dumpvars( 0, decode_tb );

        // Initialize signals
        rd = 1'b0; wr = 1'b0; addr = '0;

        // Test for no read or write
        `GENERIC_DECODE(1'b0, 1'b0, 16'h0000, 1'b0, 3'd0);

        // Test various address ranges
        `GENERIC_DECODE(1'b1, 1'b0, 16'h0000, 1'b1, 3'd0); // DRAM read
        `GENERIC_DECODE(1'b0, 1'b1, 16'h0000, 1'b1, 3'd0); // DRAM write

        `GENERIC_DECODE(1'b1, 1'b0, 16'h1000, 1'b1, 3'd1); // DROM read
        `GENERIC_DECODE(1'b0, 1'b1, 16'h1000, 1'b1, 3'd1); // DROM write

        `GENERIC_DECODE(1'b1, 1'b0, 16'h2000, 1'b1, 3'd2); // DMAT read
        `GENERIC_DECODE(1'b0, 1'b1, 16'h2000, 1'b1, 3'd2); // DMAT write

        `GENERIC_DECODE(1'b1, 1'b0, 16'h3000, 1'b1, 3'd3); // DINT read
        `GENERIC_DECODE(1'b0, 1'b1, 16'h3000, 1'b1, 3'd3); // DINT write

        `GENERIC_DECODE(1'b1, 1'b0, 16'h4000, 1'b1, 3'd4); // DREG read
        `GENERIC_DECODE(1'b0, 1'b1, 16'h4000, 1'b1, 3'd4); // DREG write

        `GENERIC_DECODE(1'b1, 1'b0, 16'h5000, 1'b1, 3'd5); // DEXEC read
        `GENERIC_DECODE(1'b0, 1'b1, 16'h5000, 1'b1, 3'd5); // DEXEC write

        `GENERIC_DECODE(1'b1, 1'b0, 16'h6000, 1'b1, 3'd6); // DSPI read
        `GENERIC_DECODE(1'b0, 1'b1, 16'h6000, 1'b1, 3'd6); // DSPI write

        // Test for invalid address
        `GENERIC_DECODE(1'b0, 1'b1, 16'h7000, 1'b0, 3'b000); // Invalid write

        // Test address specificity
        `GENERIC_DECODE(1'b1, 1'b0, 16'h1ABC, 1'b1, 3'd1);
        `GENERIC_DECODE(1'b1, 1'b0, 16'h6FFF, 1'b1, 3'd6);
        `GENERIC_DECODE(1'b1, 1'b0, 16'hF000, 1'b0, 3'd0);
        $finish;
    end
endmodule
`default_nettype wire