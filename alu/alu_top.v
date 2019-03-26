// alu32_top.v
module alu32_top (
    input  [31:0] A,         // rs1
    input  [31:0] B,         // rs2 or imm (selected outside)
    input  [6:0]  opcode,    // instruction[6:0]
    input  [2:0]  func3,     // instruction[14:12]
    input  [6:0]  func7,     // instruction[31:25]
    input  [31:0] imm,       // full immediate (used by shifter checks)
    output reg [31:0] Y,     // ALU result
    output       carry_flag, // meaningful for arithmetic ops
    output       zero_flag,  // result == 0
    output       negative_flag, // MSB of result
    output       overflow_flag  // meaningful for arithmetic ops
);

    // Opcodes used across your submodules
    localparam OPCODE_R = 7'b0110011;
    localparam OPCODE_I = 7'b0010011;

    // Internal wires from submodules
    wire [31:0] adder_sum;
    wire        adder_carry;
    wire        adder_zero;
    wire        adder_negative;
    wire        adder_overflow;

    wire [31:0] shifter_y;
    wire [31:0] logical_y;
    wire [31:0] cmp_y;

    // Determine whether current instruction is arithmetic (ADD/SUB/ADDI)
    wire is_add_sub_op = (opcode == OPCODE_R && func3 == 3'b000) ||
                         (opcode == OPCODE_I && func3 == 3'b000);

    // Determine SUB: R-type, func3==000 and func7==0100000
    wire is_sub = (opcode == OPCODE_R) && (func3 == 3'b000) && (func7 == 7'b0100000);

    // For ADD/SUB using ripple adder with cin convention:
    // - For ADD/ADDI: cin = 0, b_in = B
    // - For SUB     : cin = 1, b_in = ~B  (two's complement subtraction)
    wire [31:0] b_for_adder = is_sub ? ~B : B;
    wire        cin_for_adder = is_sub ? 1'b1 : 1'b0;

    // Instantiate ripple_carry_adder32
    ripple_carry_adder32 U_ADDER (
        .a(A),
        .b(b_for_adder),
        .cin(cin_for_adder),
        .sum(adder_sum),
        .carry_flag(adder_carry),
        .zero_flag(adder_zero),
        .negative_flag(adder_negative),
        .overflow_flag(adder_overflow)
    );

    // Instantiate shifter_unit32
    shifter_unit32 U_SHIFTER (
        .A(A),
        .B(B),
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .imm(imm),
        .Y(shifter_y)
    );

    // Instantiate logical_unit32
    logical_unit32 U_LOGICAL (
        .A(A),
        .B(B),
        .opcode(opcode),
        .func3(func3),
        .Y(logical_y)
    );

    // Instantiate comparator_unit32
    comparator_unit32 U_CMP (
        .A(A),
        .B(B),
        .opcode(opcode),
        .func3(func3),
        .Y(cmp_y)
    );

    // ALU result multiplexer (simple prioritized selection)
    // Priority:
    //  - Arithmetic (ADD/SUB/ADDI) when is_add_sub_op
    //  - Comparisons (SLT/SLTU) when func3==010 or 011 (and opcode matches)
    //  - Shifter when func3==001 or 101
    //  - Logical when func3 in {100,110,111}
    //  - Default 0
    always @(*) begin
        // Default
        Y = 32'd0;

        // Arithmetic ADD / SUB / ADDI
        if (is_add_sub_op) begin
            Y = adder_sum;
        end
        // Comparators SLT/SLTU (func3 010/011) - comparator_unit32 already checks opcode
        else if (func3 == 3'b010 || func3 == 3'b011) begin
            Y = cmp_y;
        end
        // Shifters SLL/SR* (func3 001, 101)
        else if (func3 == 3'b001 || func3 == 3'b101) begin
            Y = shifter_y;
        end
        // Logical ops XOR/OR/AND (func3 100/110/111)
        else if (func3 == 3'b100 || func3 == 3'b110 || func3 == 3'b111) begin
            Y = logical_y;
        end
        else begin
            Y = 32'd0;
        end
    end

    // Flags:
    // zero, negative computed from final result Y
    assign zero_flag     = (Y == 32'd0);
    assign negative_flag = Y[31];

    // carry & overflow meaningful only for arithmetic ops
    assign carry_flag    = is_add_sub_op ? adder_carry : 1'b0;
    assign overflow_flag = is_add_sub_op ? adder_overflow : 1'b0;

endmodule




// alu32_top_tb.v
//`timescale 1ns/1ps
module alu32_top_tb;

    reg  [31:0] A, B, imm;
    reg  [6:0]  opcode;
    reg  [2:0]  func3;
    reg  [6:0]  func7;

    wire [31:0] Y;
    wire        carry_flag, zero_flag, negative_flag, overflow_flag;

    alu32_top DUT (
        .A(A),
        .B(B),
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .imm(imm),
        .Y(Y),
        .carry_flag(carry_flag),
        .zero_flag(zero_flag),
        .negative_flag(negative_flag),
        .overflow_flag(overflow_flag)
    );

    // Opcodes same as modules
    localparam OPCODE_R = 7'b0110011;
    localparam OPCODE_I = 7'b0010011;
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end



    initial begin
        $display("time\tinstr\t\tA\t\tB/imm\t\tY\t\tC Z N V\t// expected");

        // ---------------------------
        // 1) ADD (R-type) : A + B
        // ---------------------------
        #5;
        A = 32'd10; B = 32'd20;
        opcode = OPCODE_R; func3 = 3'b000; func7 = 7'b0000000; imm = 32'd0;
        #5;
        $display("%0t\tADD\t\t%0d\t%0d\t%0d\t%b %b %b %b\t// 30", $time, A, B, Y, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ---------------------------
        // 2) SUB (R-type) : A - B
        // ---------------------------
        #5;
        A = 32'd50; B = 32'd20;
        opcode = OPCODE_R; func3 = 3'b000; func7 = 7'b0100000; // SUB
        #5;
        $display("%0t\tSUB\t\t%0d\t%0d\t%0d\t%b %b %b %b\t// 30", $time, A, B, Y, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ---------------------------
        // 3) ADDI (I-type) : A + imm
        // ---------------------------
        #5;
        A = 32'd7; imm = 32'd3; B = imm; // you said B selected outside; we put imm in B for adder
        opcode = OPCODE_I; func3 = 3'b000; func7 = 7'b0000000;
        #5;
        $display("%0t\tADDI\t\t%0d\t%0d\t%0d\t%b %b %b %b\t// 10", $time, A, B, Y, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ---------------------------
        // 4) AND (R-type)
        // ---------------------------
        #5;
        A = 32'hF0F0_F0F0; B = 32'h0FF0_0FF0;
        opcode = OPCODE_R; func3 = 3'b111; func7 = 7'b0000000;
        #5;
        $display("%0t\tAND\t\t0x%h\t0x%h\t0x%h\t%b %b %b %b\t// 0x00f0_00f0", $time, A, B, Y, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ---------------------------
        // 5) OR (R-type)
        // ---------------------------
        #5;
        opcode = OPCODE_R; func3 = 3'b110;
        #5;
        $display("%0t\tOR\t\t0x%h\t0x%h\t0x%h\t%b %b %b %b\t// 0xfff0_fff0", $time, A, B, Y, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ---------------------------
        // 6) XOR (R-type)
        // ---------------------------
        #5;
        opcode = OPCODE_R; func3 = 3'b100;
        #5;
        $display("%0t\tXOR\t\t0x%h\t0x%h\t0x%h\t%b %b %b %b\t// 0xff00_ff00", $time, A, B, Y, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ---------------------------
        // 7) SLL (R-type) : shift left by B[4:0]
        // ---------------------------
        #5;
        A = 32'h0000_0001; B = 32'd4; // shift left by 4 -> 16
        opcode = OPCODE_R; func3 = 3'b001; func7 = 7'b0000000;
        #5;
        $display("%0t\tSLL\t\t0x%h\t%0d\t0x%h\t%b %b %b %b\t// 0x10", $time, A, B[4:0], Y, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ---------------------------
        // 8) SRL (R-type)
        // ---------------------------
        #5;
        A = 32'h8000_0000; B = 32'd1; // logical right by 1 -> 0x4000_0000
        opcode = OPCODE_R; func3 = 3'b101; func7 = 7'b0000000; // SRL
        #5;
        $display("%0t\tSRL\t\t0x%h\t%0d\t0x%h\t%b %b %b %b\t// logical", $time, A, B[4:0], Y, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ---------------------------
        // 9) SRA (R-type)
        // ---------------------------
        #5;
        A = 32'h8000_0000; B = 32'd1; // arithmetic right by 1 -> sign-extend -> 0xC000_0000
        opcode = OPCODE_R; func3 = 3'b101; func7 = 7'b0100000; // SRA
        #5;
        $display("%0t\tSRA\t\t0x%h\t%0d\t0x%h\t%b %b %b %b\t// arithmetic", $time, A, B[4:0], Y, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ---------------------------
        // 10) SLT (signed)
        // ---------------------------
        #5;
        A = -32'sd5; B = 32'sd3;
        opcode = OPCODE_R; func3 = 3'b010; func7 = 7'b0000000; // SLT
        #5;
        $display("%0t\tSLT\t\t%0d\t%0d\t%0d\t%b %b %b %b\t// 1", $time, $signed(A), $signed(B), Y, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ---------------------------
        // 11) SLTU (unsigned)
        // ---------------------------
        #5;
        A = 32'hFFFF_FFFF; B = 32'h0000_0001;
        opcode = OPCODE_R; func3 = 3'b011; func7 = 7'b0000000; // SLTU
        #5;
        $display("%0t\tSLTU\t\t0x%h\t0x%h\t%0d\t%b %b %b %b\t// 0 (unsigned)", $time, A, B, Y, carry_flag, zero_flag, negative_flag, overflow_flag);

        // Finish
        #10;
        $finish;
    end

endmodule

