module logical_unit32 (
    input  [31:0] A,         // rs1 value
    input  [31:0] B,         // rs2 or immediate (selected by ALUSrc)
    input  [6:0]  opcode,    // instruction[6:0]
    input  [2:0]  func3,     // instruction[14:12]
    output reg [31:0] Y
);

// R-type opcode and I-type opcode
localparam OPCODE_R = 7'b0110011;
localparam OPCODE_I = 7'b0010011;

always @(*) begin
    case (func3)

        // XOR / XORI
        3'b100: begin
            if (opcode == OPCODE_R || opcode == OPCODE_I)
                Y = A ^ B;
            else
                Y = 32'b0;
        end

        // OR / ORI
        3'b110: begin
            if (opcode == OPCODE_R || opcode == OPCODE_I)
                Y = A | B;
            else
                Y = 32'b0;
        end

        // AND / ANDI
        3'b111: begin
            if (opcode == OPCODE_R || opcode == OPCODE_I)
                Y = A & B;
            else
                Y = 32'b0;
        end

        default: Y = 32'b0;

    endcase
end

endmodule



//`timescale 1ns/1ps

module tb_logical_unit32;

    reg  [31:0] A;
    reg  [31:0] B;
    reg  [6:0]  opcode;
    reg  [2:0]  func3;
    wire [31:0] Y;

    // Instantiate the DUT
    logical_unit32 dut (
        .A(A),
        .B(B),
        .opcode(opcode),
        .func3(func3),
        .Y(Y)
    );
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end

    // R-type and I-type opcodes
    localparam OPCODE_R = 7'b0110011;
    localparam OPCODE_I = 7'b0010011;

    initial begin
        $display("==== LOGICAL UNIT TEST STARTED ====");
        $display("Time   Opcode    Func3    A        B         | Output (Y)");

        // --------------------------------------------------------------------
        // R-TYPE TESTS (rs1 OP rs2)
        // --------------------------------------------------------------------

        A = 32'hAAAA_FFFF;
        B = 32'h0F0F_0F0F;

        // AND
        opcode = OPCODE_R; func3 = 3'b111;
        #10 $display("R-AND:  %b   %b   %h   %h  |  %h", opcode, func3, A, B, Y);

        // OR
        opcode = OPCODE_R; func3 = 3'b110;
        #10 $display("R-OR :  %b   %b   %h   %h  |  %h", opcode, func3, A, B, Y);

        // XOR
        opcode = OPCODE_R; func3 = 3'b100;
        #10 $display("R-XOR:  %b   %b   %h   %h  |  %h", opcode, func3, A, B, Y);


        // --------------------------------------------------------------------
        // I-TYPE TESTS (rs1 OP immediate)
        // --------------------------------------------------------------------

        A = 32'h1234_5678;
        B = 32'h0000_00FF;   // immediate value after sign-extend

        // ANDI
        opcode = OPCODE_I; func3 = 3'b111;
        #10 $display("I-ANDI: %b   %b   %h   %h  |  %h", opcode, func3, A, B, Y);

        // ORI
        opcode = OPCODE_I; func3 = 3'b110;
        #10 $display("I-ORI : %b   %b   %h   %h  |  %h", opcode, func3, A, B, Y);

        // XORI
        opcode = OPCODE_I; func3 = 3'b100;
        #10 $display("I-XORI: %b   %b   %h   %h  |  %h", opcode, func3, A, B, Y);

        $display("==== TEST COMPLETE ====");
        $finish;
    end

endmodule


