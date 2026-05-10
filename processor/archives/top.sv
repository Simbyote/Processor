`default_nettype none
`timescale 1ns/1ns
/* top.sv
 *  Instantiates the execution module, memory modules, and its testbench.
 *  Tristate assignments are used for the `inout` DataBus
 *
 * Notes:
 * - A `$dumpfile` is created that saves the waveform, named `dump.vcd`. A
 *   Makefile moves this file to a built directory: `build/sim`.
 */
module top ();
    tri [255:0] DataBus;
    logic nRead, nWrite, nReset, Clk;
    logic [15:0] address;

    // Internal signals 
    logic [31:0]  InstrDataout;
    logic [255:0] MainDataout;

    // Tristate assignments for DataBus
    assign DataBus = (address[15:12] == InstrMemEn && !nRead)
                     ? {224'b0, InstrDataout}
                     : 'z;
    assign DataBus = (address[15:12] == MainMemEn && !nRead)
                     ? MainDataout
                     : 'z;

    // Instantiate modules
    InstructionMemory U1 (
        .Clk(Clk),
        .address(address),
        .nRead(nRead),
        .nReset(nReset),
        .Dataout(InstrDataout)
    );

    MainMemory U2 (
        .Clk(Clk),
        .DataIn(DataBus),
        .address(address),
        .nRead(nRead),
        .nWrite(nWrite),
        .nReset(nReset),
        .Dataout(MainDataout)
    );

    TestExecute UTest (
        .nWrite(nWrite),
        .nReset(nReset),
        .address(address),
        .DataBus(DataBus),
        .Clk(Clk),
        .nRead(nRead)
    );

    Execution U3 (
        .Clk(Clk),
        .address(address),
        .nRead(nRead),
        .nWrite(nWrite),
        .nReset(nReset),
        .DataBus(DataBus)
    );

    // Dump waveform
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top);
    end
endmodule
`default_nettype wire