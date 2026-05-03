// Mike Orduna -- Testbench Provided by Mark W Welker
// HDL 4321 Spring 2026
module TestMatrix  (
    output logic Clk,
    output logic nReset
);
    // Initializes clock and reset signals
	initial begin
		Clk = 0;
		nReset = 1;
        #5 nReset = 0;
        #5 nReset = 1;
	end
	
    // Drives the clock
	always  #5 Clk = ~Clk;
endmodule