
// Mike Orduna -- Top Provided by Mark W Welker
// HDL 4321 Spring 2026
// Final Project - Simplistic Processing Engine
//
// Main memory MUST be allocated in the MainMemory module as per the next line.
//  logic [255:0]MainMemory[12]; // this is the physical memory
module top ();
    wire [255:0] DataBus;
    logic nRead,nWrite,nReset,Clk;
    logic [15:0] address;

    logic Fail;

    InstructionMemory U1(
        .Clk(Clk),
        .DataBus(DataBus),
        .address(address),
        .nRead(nRead),
        .nReset(nReset)
    );

    MainMemory U2(
        .Clk(Clk),
        .DataBus(DataBus),
        .address(address),
        .nRead(nRead),
        .nWrite(nWrite),
        .nReset(nReset)
    );

    Execution U3(
        .Clk(Clk),
        .DataBus(DataBus),
        .address(address),
        .nRead(nRead),
        .nWrite(nWrite),
        .nReset(nReset)
    );

    MatrixAlu U4(
        .Clk(Clk),
        .DataBus(DataBus),
        .address(address),
        .nRead(nRead),
        .nWrite(nWrite),
        .nReset(nReset)
    );

    IntegerAlu U5(
        .Clk(Clk),
        .DataBus(DataBus),
        .address(address),
        .nRead(nRead),
        .nWrite(nWrite),
        .nReset(nReset)
    );

    TestMatrix UTest(
        .Clk(Clk),
        .nReset(nReset)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(1);
        Fail = 0;
    end

    always @(DataBus) begin // this block checks to make certain the proper data is in the memory
        if (DataBus[31:0] == 32'hff000000)
        // Stop instruction is being read
        begin 
        // Print out the entire contents of main memory (preparing for copy-paste)
            // Memory Locations 0-13
            $display ( "memory location 0 = %h", U2.MainMemory[0]);
            $display ( "memory location 1 = %h", U2.MainMemory[1]);
            $display ( "memory location 2 = %h", U2.MainMemory[2]);
            $display ( "memory location 3 = %h", U2.MainMemory[3]);
            $display ( "memory location 4 = %h", U2.MainMemory[4]);
            $display ( "memory location 5 = %h", U2.MainMemory[5]);
            $display ( "memory location 6 = %h", U2.MainMemory[6]);
            $display ( "memory location 7 = %h", U2.MainMemory[7]);
            $display ( "memory location 8 = %h", U2.MainMemory[8]);
            $display ( "memory location 9 = %h", U2.MainMemory[9]);
            $display ( "memory location 10 = %h", U2.MainMemory[10]);
            $display ( "memory location 11 = %h", U2.MainMemory[11]);
            $display ( "memory location 12 = %h", U2.MainMemory[12]);
            $display ( "memory location 13 = %h", U2.MainMemory[13]);
            // Internal Registers 0-3
            $display ( "Internal Reg location 0 = %h", U3.InternalReg[0]);
            $display ( "Internal reg location 1 = %h", U3.InternalReg[1]);
            $display ( "Internal reg location 2 = %h", U3.InternalReg[2]);
            $display ( "Internal reg location 3 = %h", U3.InternalReg[3]);
                
            // Checks main memory and internal registers for the expected values
            if (U2.MainMemory[0] == 256'h000e000c0008000d00080010000f0009000b000800060007000c0005000c0008)
                $display("memory location 0 is Correct");
            else begin Fail = 1; $display("memory location 0 is Wrong"); end
            if (U2.MainMemory[1] == 256'h000a000500070009000c0004000e00020007000600070008000c000700040009)
                $display("memory location 1 is Correct");
            else begin Fail = 1;$display("memory location 1 is Wrong"); end
            if (U2.MainMemory[2] == 256'h00180011000f001600140014001d000b0012000e000d000f0018000c00100011)
                $display("memory location 2 is Correct");
            else begin Fail = 1;$display("memory location 2 is Wrong"); end
            if (U2.MainMemory[3] == 256'h002a00240018002700180030002d001b00210018001200150024000f00240018)
                $display("memory location 3 is Correct");
            else begin Fail = 1;$display("memory location 3 is Wrong"); end
            if (U2.MainMemory[4] == 256'h001c00180010001a00100020001e001200160010000c000e0018000a00180010)
                $display("memory location 4 is Correct");
            else begin Fail = 1;$display("memory location 4 is Wrong"); end
            if (U2.MainMemory[5] == 256'h001800140012001800110014000e000c000f001d000d00100016000b000f0011)
                $display("memory location 5 is Correct");
            else begin Fail = 1;$display("memory location 5 is Wrong"); end
            if (U2.MainMemory[6] == 256'h076406fe059e067a06ee07ec05740612050804ee03da047e05b2061004640548)
                $display("memory location 6 is Correct");
            else begin Fail = 1;$display("memory location 6 is Wrong"); end
            if (U2.MainMemory[7] == 256'h0000000000000000000000000000000000000000000000000000000000000000)
                $display("memory location 7 is Correct");
            else begin Fail = 1;$display("memory location 7 is Wrong"); end
            if (U2.MainMemory[8] == 256'h0000000000000000000000000000000000000000000000000000000000000000)
                $display("memory location 8 is Correct");
            else begin Fail = 1;$display("memory location 8 is Wrong"); end
            if (U2.MainMemory[9] == 256'h0000000000000000000000000000000000000000000000000000000000000000)
                $display("memory location 9 is Correct");
            else begin Fail = 1;$display("memory location 9 is Wrong"); end
            if (U2.MainMemory[10][15:0] == 16'h0048)
                $display("memory location 10 is Correct");
            else begin Fail = 1;$display("memory location 10 is Wrong"); end
            if (U2.MainMemory[11][15:0] == 16'h000c)
                $display("memory location 11 is Correct");
            else begin Fail = 1;$display("memory location 11 is Wrong"); end
            if (U2.MainMemory[12][15:0] == 16'h0000)
                $display("memory location 12 is Correct");
            else begin Fail = 1;$display("memory location 12 is Wrong"); end
            if (U3.InternalReg[0][15:0] == 16'h000f)
                $display("Internal reg location 0 is Correct");
            else begin Fail = 1; $display("Internal Register 0 is Wrong"); end
            if (U3.InternalReg[1] == 256'h0150012000c0013800c00180016800d8010800c0009000a801200078012000c0)
                $display ( "Internal Reg location 1 is Correct");
            else begin Fail = 1; $display("Internal Register 1 is Wrong"); end
            if (U3.InternalReg[2][15:0] == 16'h003f)
                $display("Internal Reg location 2 is Correct");
            else begin Fail = 1; $display("Internal Register 2 is Wrong"); end

            // Final verdict of the project
            if (Fail) begin
                $display("********************************************");
                $display(" Project did not return the proper values");
                $display("********************************************");
            end
            else begin
                $display("********************************************");
                $display(" Project PASSED memory check");
                $display("********************************************");
            end
        end
    end
endmodule