`default_nettype none
`timescale 1ns/1ns
/* execution.sv
 * Purpose:
 *  Implements the Execution module, which is the core FSM that fetches, decodes, and executes instructions.
 *
 * Inputs:
 *  - Clk: Clock signal
 *
 * Outputs:
 *  - address: 16-bit address bus for memory access
 *  - nRead: active-low read enable for MainMemory and InstructionMemory
 *  - nWrite: active-low write enable for MainMemory
 *  - nReset: reset signal for initializing the FSM and registers
 *
 * Tristate Inout:
 *  - DataBus: 256-bit tri-state data bus for memory read/write
 */
module Execution (
    input  logic          Clk,
    inout  tri  [255:0]   DataBus,
    output logic [15:0]   address,
    output logic          nRead,
    output logic          nWrite,
    input  logic          nReset
);

    /* FSM States
     *  - ST_RESET: Initial state after reset
     *  - ST_FETCH: Fetches instruction from memory
     *  - ST_FHOLD: Instruction fetch hold state
     *  - ST_LATCH_I: Latches instruction into register
     *  - ST_DECODE: Decodes instruction
     *  - ST_RD1: Reads source operand 1
     *  - ST_RHOLD1: Read hold for source operand 1
     *  - ST_LAT1: Latches source operand 1 into reg0
     *  - ST_RD2: Reads source operand 2
     *  - ST_RHOLD2: Read hold for source operand 2
     *  - ST_LAT2: Latches source operand 2 into reg1
     *  - ST_EXEC: Executes the instruction
     *  - ST_WB: Writes back result to memory
     *  - ST_INCR: Increments instruction pointer
     *  - ST_STOP: Halts execution
     */
    typedef enum logic [3:0] {
        ST_RESET   = 4'd0,
        ST_FETCH   = 4'd1,
        ST_FHOLD   = 4'd2,
        ST_LATCH_I = 4'd3,
        ST_DECODE  = 4'd4,
        ST_RD1     = 4'd5,
        ST_RHOLD1  = 4'd6,
        ST_LAT1    = 4'd7,
        ST_RD2     = 4'd8,
        ST_RHOLD2  = 4'd9,
        ST_LAT2    = 4'd10,
        ST_EXEC    = 4'd11,
        ST_WB      = 4'd12,
        ST_INCR    = 4'd13,
        ST_STOP    = 4'd14
    } state_t;

    // FSM instance
    state_t state;

    // Internal wires
    logic [255:0] reg0, reg1, reg2;
    logic [31:0]  instruction_reg;
    logic [7:0]   opcode, destination, src1, src2;
    logic [11:0]  iptr;
    logic         bus_oe;
    logic [255:0] bus_out;

    // Tri-state data bus logic:
    assign DataBus = bus_oe ? bus_out : 'z;

    // Main state machine logic
    always_ff @(negedge Clk or negedge nReset) begin
        if (!nReset) begin      // Initialization on reset
            state    <= ST_RESET;
            address  <= '0;
            nRead    <= 1'b1;
            nWrite   <= 1'b1;
            bus_oe   <= 1'b0;
            bus_out  <= '0;
            iptr     <= '0;
            instruction_reg<= '0;
            opcode <= '0; destination <= '0; src1 <= '0; src2 <= '0;
            reg0 <= '0; reg1 <= '0; reg2 <= '0;
        end else begin           // Normal operation
            nRead  <= 1'b1;
            nWrite <= 1'b1;
            bus_oe <= 1'b0;

            // FSM transitions and actions
            case (state)
                ST_RESET: begin
                    state <= ST_FETCH;
                end
                ST_FETCH: begin
                    address <= {4'd2, iptr};
                    nRead   <= 1'b0;
                    state   <= ST_FHOLD;
                end
                ST_FHOLD: begin
                    address <= {4'd2, iptr};
                    nRead   <= 1'b0;
                    state   <= ST_LATCH_I;
                end
                ST_LATCH_I: begin
                    address   <= {4'd2, iptr};
                    nRead     <= 1'b0;
                    instruction_reg <= DataBus[31:0];
                    state     <= ST_DECODE;
                end
                ST_DECODE: begin
                    opcode <= instruction_reg[31:24];
                    destination <= instruction_reg[23:16];
                    src1   <= instruction_reg[15:8];
                    src2   <= instruction_reg[7:0];
                    state  <= ST_RD1;
                end
                ST_RD1: begin
                    if (opcode == 8'hFF) begin
                        state <= ST_STOP;
                    end else begin
                        address <= {4'h0, 4'h0, src1};
                        nRead   <= 1'b0;
                        state   <= ST_RHOLD1;
                    end
                end
                ST_RHOLD1: begin
                    address <= {4'h0, 4'h0, src1};
                    nRead   <= 1'b0;
                    state   <= ST_LAT1;
                end
                ST_LAT1: begin
                    address <= {4'h0, 4'h0, src1};
                    nRead   <= 1'b0;
                    reg0    <= DataBus;
                    state   <= ST_RD2;
                end
                ST_RD2: begin
                    address <= {4'h0, 4'h0, src2};
                    nRead   <= 1'b0;
                    state   <= ST_RHOLD2;
                end
                ST_RHOLD2: begin
                    address <= {4'h0, 4'h0, src2};
                    nRead   <= 1'b0;
                    state   <= ST_LAT2;
                end
                ST_LAT2: begin
                    address <= {4'h0, 4'h0, src2};
                    nRead   <= 1'b0;
                    reg1    <= DataBus;
                    state   <= ST_EXEC;
                end
                ST_EXEC: begin
                    // Specify which operation 
                    case(opcode)
                        8'h00: reg2 <= reg0 + reg1;     // Addition
                        8'h01: reg2 <= reg0 - reg1;     // Subtraction
                        8'h02: reg2 <= reg0 & reg1;     // Logical AND
                        8'h03: reg2 <= reg0 | reg1;     // Logical OR
                        8'h04: reg2 <= reg0 ^ reg1;     // Logical XOR
                        8'h05: reg2 <= reg0 << reg1;    // Logical Left Shift
                        8'h06: reg2 <= reg0 >> reg1;    // Logical Right Shift
                        8'h07: reg2 <= reg0 * reg1;     // Multiplication
                        default: reg2 <= reg0 + reg1;   // Default to addition
                    endcase
                    state <= ST_WB;
                end
                ST_WB: begin
                    address <= {4'h0, 4'h0, destination};
                    bus_out <= reg2;
                    bus_oe  <= 1'b1;
                    nWrite  <= 1'b0;
                    state   <= ST_INCR;
                end
                ST_INCR: begin
                    iptr  <= iptr + 12'h1;
                    state <= ST_FETCH;
                end
                ST_STOP: begin
                    address <= '0;
                    state   <= ST_STOP;
                end
                default: state <= ST_RESET; // If no recognized state, reset FSM
            endcase
        end
    end
endmodule
`default_nettype wire