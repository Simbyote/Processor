`default_nettype none
`timescale 1ns/1ps
/* decode_tb.sv
 * Purpose:
 *  Testbench for the decode module. Drives the decode module with
 *  various inputs and checks for correct outputs.
 *
 * Functions:
 * - Tests whether the decode module correctly identifies memory-mapped
 *   components
 *
 * Modules:
 * - decode_tb: Testbench for the decode module
 *
 * Notes:
 * - Uses the `define macro for generic test cases
 * - Features debug outputs using `$fatal` (for fatal errors; ends test upon failure) 
 *   and `$display` (for generic output verification)
 */

module decode_tb (
    input wire hit,
    input wire [2:0] did,

    output logic rd, wr,
    output logic [15:0] addr
);
    localparam BIT_STATE = 2**12;

    // Local wires
    logic [3:0] region;
    logic [11:0] offset;

    logic pin;
    logic [2:0] select;

    // Tests whether the decode module correctly identifies memory-mapped components
    `define GENERIC_DECODE(_rd, _wr, _addr, _hit, _did) \
    begin                                               \
        rd = _rd;                                       \
        wr = _wr;                                       \
        addr = _addr;                                   \
        #1;                                             \
        if (hit !== (_hit)) begin                       \
            $fatal(1,                                   \
                {"FATAL: hit mismatch:\n",              \
                " rd=%0b, wr=%0b, addr=0x%0h\n",        \
                " Got: hit=%0b\n",                      \
                " Expected: hit=%0b\n"},                \
                rd, wr, addr, _hit, hit);               \
        end                                             \
        if (did !== (_did)) begin                       \
            $fatal(1,                                   \
                {"FATAL: did mismatch:\n",              \
                " rd=%0b, wr=%0b, addr=0x%0h\n",        \
                " Got: did=%0d\n" ,                     \
                " Expected: did=%0d\n"},                \
                rd, wr, addr, _did, did);               \
        end                                             \
        #1;                                             \
    end

    /* For testing, each case must be handled such like:
     * - `rd = 0` and `wr = 0`: Idle state `hit = 0` and `did = DNONE`
     * - `rd = 1` and `wr = 0`: Read state `hit = 1` and `did` is appropriate memory-mapped component
     * - `rd = 0` and `wr = 1`: Write state `hit = 1` and `did` is appropriate memory-mapped component
     * - `rd = 1` and `wr = 1`: Concurrent state `hit = 1` and `did` is appropriate memory-mapped component
     */
    initial begin
        // Initialize signals
        rd = '0; wr = '0; addr = '0; pin = 0; select = 3'd7; 
        offset = '0; region = '0;

        // Test 1: Idle state across all possible states
        for(int i = 0; i < 16; i = i + 1) begin
            offset = '0;
            repeat (BIT_STATE) begin
                addr = {region, offset};
                `GENERIC_DECODE(rd, wr, addr, pin, select);
                offset = offset + 1;
            end
            region = region + 1;
        end

        // Test 2: Read across all possible states
        rd = 1'b1; offset = '0; select = 3'd0; pin = 1'b1;
        for(int i = 0; i < 16; i = i + 1) begin
            repeat (BIT_STATE) begin
                addr = {region, offset};
                `GENERIC_DECODE(rd, wr, addr, pin, select);
                offset = offset + 1;
            end
            region = region + 1;

            // Drive the pin to 0 if the region is outside of the map range
            if (region > 6) begin
                pin = 0;
                select = 3'd7;
            end
            else begin 
                select = select + 1; 
            end
        end

        // Test 3: Write across all possible states
        rd = 0; wr = 1'b1; offset = '0; select = 3'd0; pin = 1'b1;
        for(int i = 0; i < 16; i = i + 1) begin
            repeat (BIT_STATE) begin
                addr = {region, offset};
                `GENERIC_DECODE(rd, wr, addr, pin, select);
                offset = offset + 1;
            end
            region = region + 1;

            // Drive the pin to 0 if the region is outside of the map range
            if (region > 6) begin
                pin = 0;
                select = 3'd7;
            end
            else begin 
                select = select + 1; 
            end
        end

        // Test 4: Concurrent across all possible states
        rd = 1'b1; offset = '0; select = 3'd0; pin = 1'b1;
        for(int i = 0; i < 16; i = i + 1) begin
            repeat (BIT_STATE) begin
                addr = {region, offset};
                `GENERIC_DECODE(rd, wr, addr, pin, select);
                offset = offset + 1;
            end
            region = region + 1;

            // Drive the pin to 0 if the region is outside of the map range
            if (region > 6) begin
                pin = 0;
                select = 3'd7;
            end
            else begin 
                select = select + 1; 
            end
        end

        $finish;
    end
endmodule
`default_nettype wire
// Testing section of the decoder may have to change to be more generic and
// modular. As it stands, it works but it is very specific.