module comparator_unit32 (
    input  [31:0] A,         // rs1
    input  [31:0] B,         // rs2 or immediate (selected outside)
    input  [6:0]  opcode,    // instruction[6:0]
    input  [2:0]  func3,     // instruction[14:12]
    output reg [31:0] Y
);

    // Opcodes
    localparam OPCODE_R = 7'b0110011;
    localparam OPCODE_I = 7'b0010011;

    always @(*) begin
        case (func3)

            // -------------------------------------------------
            // SLT, SLTI  (signed comparison)
            // func3 = 010
            // -------------------------------------------------
            3'b010: begin
                if (opcode == OPCODE_R)      // SLT
                    Y = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;

                else if (opcode == OPCODE_I) // SLTI
                    Y = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;

                else
                    Y = 32'd0;
            end

            // -------------------------------------------------
            // SLTU, SLTIU (unsigned comparison)
            // func3 = 011
            // -------------------------------------------------
            3'b011: begin
                if (opcode == OPCODE_R)      // SLTU
                    Y = (A < B) ? 32'd1 : 32'd0;

                else if (opcode == OPCODE_I) // SLTIU
                    Y = (A < B) ? 32'd1 : 32'd0;

                else
                    Y = 32'd0;
            end

            default: Y = 32'd0;

        endcase
    end

endmodule





//`timescale 1ns/1ps

module comparator_unit32_tb;

    reg  [31:0] A, B;
    reg  [6:0]  opcode;
    reg  [2:0]  func3;
    wire [31:0] Y;

    // Instantiate DUT
    comparator_unit32 dut (
        .A(A),
        .B(B),
        .opcode(opcode),
        .func3(func3),
        .Y(Y)
    );

    // R-type and I-type opcodes
    localparam OPCODE_R = 7'b0110011;
    localparam OPCODE_I = 7'b0010011;

initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end



    initial begin
        $display("===== COMPARATOR UNIT TEST START =====");

        // ------------------------------------
        // SLT (signed)
        // ------------------------------------
        A = -5;  B = 10; opcode = OPCODE_R; func3 = 3'b010;
        #5 $display("SLT  : A=%0d, B=%0d -> Y=%0d (expected 1)", A, B, Y);

        A = 15; B = -3; opcode = OPCODE_R; func3 = 3'b010;
        #5 $display("SLT  : A=%0d, B=%0d -> Y=%0d (expected 0)", A, B, Y);

        A = -4; B = -4; opcode = OPCODE_R; func3 = 3'b010;
        #5 $display("SLT  : A=%0d, B=%0d -> Y=%0d (expected 0)", A, B, Y);

        // ------------------------------------
        // SLTU (unsigned)
        // ------------------------------------
        A = 32'hFFFFFFFF; B = 10; opcode = OPCODE_R; func3 = 3'b011;
        #5 $display("SLTU : A=%0h, B=%0h -> Y=%0d (expected 0)", A, B, Y);

        A = 5; B = 10; opcode = OPCODE_R; func3 = 3'b011;
        #5 $display("SLTU : A=%0d, B=%0d -> Y=%0d (expected 1)", A, B, Y);

        // ------------------------------------
        // SLTI (signed immediate)
        // B is already immediate outside
        // ------------------------------------
        A = -8; B = 5; opcode = OPCODE_I; func3 = 3'b010;
        #5 $display("SLTI : A=%0d, imm=%0d -> Y=%0d (expected 1)", A, B, Y);

        A = 20; B = -1; opcode = OPCODE_I; func3 = 3'b010;
        #5 $display("SLTI : A=%0d, imm=%0d -> Y=%0d (expected 0)", A, B, Y);

        // ------------------------------------
        // SLTIU (unsigned immediate)
        // ------------------------------------
        A = 2; B = 10; opcode = OPCODE_I; func3 = 3'b011;
        #5 $display("SLTIU: A=%0d, imm=%0d -> Y=%0d (expected 1)", A, B, Y);

        A = 50; B = 5; opcode = OPCODE_I; func3 = 3'b011;
        #5 $display("SLTIU: A=%0d, imm=%0d -> Y=%0d (expected 0)", A, B, Y);

        $display("===== COMPARATOR UNIT TEST END =====");
        $finish;
    end

endmodule

