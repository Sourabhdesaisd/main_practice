module branch_unit (
    input  [31:0] pc_current,   // current PC
    input  [12:0] imm_raw,      // already extracted B-type immediate
    input         z,            // zero flag
    input         n,            // negative flag
    input         v,            // overflow flag
    input         c,            // carry flag
    input  [2:0]  func3,        // branch type (BEQ/BNE/BLT/BGE/BLTU/BGEU)
    input         branch_enable,

    output        branch_taken,
    output [31:0] branch_target
);

    // ------------------------------
    // 1. Sign-extend immediate
    // ------------------------------
    wire [31:0] imm_ext;
    assign imm_ext = {{19{imm_raw[12]}}, imm_raw};    // 13-bit ? 32-bit


    // ------------------------------
    // 2. Shift left by 1 (B-type)
    // ------------------------------
    wire [31:0] imm_shifted;
    assign imm_shifted = imm_ext << 1;


    // ------------------------------
    // 3. Branch conditions
    // ------------------------------
    wire beq  = z;
    wire bne  = ~z;
    wire blt  = n ^ v;
    wire bge  = ~(n ^ v);
    wire bltu = ~c;
    wire bgeu = c;

    reg cond;
    always @(*) begin
        case (func3)
            3'b000: cond = beq;      // BEQ
            3'b001: cond = bne;      // BNE
            3'b100: cond = blt;      // BLT
            3'b101: cond = bge;      // BGE
            3'b110: cond = bltu;     // BLTU
            3'b111: cond = bgeu;     // BGEU
            default: cond = 1'b0;
        endcase
    end


    // ------------------------------
    // 4. Final results
    // ------------------------------
    assign branch_taken  = branch_enable & cond;
    assign branch_target = pc_current + imm_shifted;

endmodule


/*
module tb_branch_unit_no_loop;

    reg  [31:0] pc_current;
    reg  [12:0] imm_raw;
    reg         z, n, v, c;
    reg  [2:0]  func3;
    reg         branch_enable;

    wire        branch_taken;
    wire [31:0] branch_target;

    // DUT (assumes branch_unit uses imm_raw and shifts left by 1 internally)
    branch_unit uut (
        .pc_current  (pc_current),
        .imm_raw     (imm_raw),
        .z           (z),
        .n           (n),
        .v           (v),
        .c           (c),
        .func3       (func3),
        .branch_enable(branch_enable),
        .branch_taken(branch_taken),
        .branch_target(branch_target)
    );

initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end

    initial begin
        $display("\n===== STEP-BY-STEP BRANCH UNIT TEST (no loop) =====\n");
        branch_enable = 1'b1;

        // -------------------------
        // STEP 1 : BEQ (func3 = 000)
        // pc = 100, imm = 2  -> target = 100 + (2<<1) = 104
        // expect taken because z=1
        // -------------------------
        pc_current = 32'd100;
        imm_raw    = 13'd2;
        func3      = 3'b000; // BEQ
        z = 1; n = 0; v = 0; c = 1;
        #10; // wait for DUT to settle
        $display("STEP1 BEQ : PC=%0d IMM=%0d -> taken=%b target=%0d (expected=%0d)",
                 pc_current, imm_raw, branch_taken, branch_target,
                 pc_current + (imm_raw << 1));

        // -------------------------
        // STEP 2 : BNE (func3 = 001)
        // pc = 101, imm = 3  -> target = 101 + (3<<1) = 107
        // expect taken because z=0
        // -------------------------
        #10;
        pc_current = 32'd101;
        imm_raw    = 13'd3;
        func3      = 3'b001; // BNE
        z = 0; n = 0; v = 0; c = 1;
        #10;
        $display("STEP2 BNE : PC=%0d IMM=%0d -> taken=%b target=%0d (expected=%0d)",
                 pc_current, imm_raw, branch_taken, branch_target,
                 pc_current + (imm_raw << 1));

        // -------------------------
        // STEP 3 : BLT (func3 = 100)
        // pc = 102, imm = 4 -> target = 102 + (4<<1) = 110
        // BLT uses (n ^ v). Set n=1, v=0 => taken.
        // -------------------------
        #10;
        pc_current = 32'd102;
        imm_raw    = 13'd4;
        func3      = 3'b100; // BLT
        z = 0; n = 1; v = 0; c = 1;
        #10;
        $display("STEP3 BLT : PC=%0d IMM=%0d -> taken=%b target=%0d (expected=%0d)",
                 pc_current, imm_raw, branch_taken, branch_target,
                 pc_current + (imm_raw << 1));

        // -------------------------
        // STEP 4 : BGE (func3 = 101)
        // pc = 103, imm = 5 -> target = 103 + (5<<1) = 113
        // BGE uses ~(n ^ v). Set n=0,v=0 => taken.
        // -------------------------
        #10;
        pc_current = 32'd103;
        imm_raw    = 13'd5;
        func3      = 3'b101; // BGE
        z = 0; n = 0; v = 0; c = 1;
        #10;
        $display("STEP4 BGE : PC=%0d IMM=%0d -> taken=%b target=%0d (expected=%0d)",
                 pc_current, imm_raw, branch_taken, branch_target,
                 pc_current + (imm_raw << 1));

        // -------------------------
        // STEP 5 : BLTU (func3 = 110)
        // pc = 104, imm = 6 -> target = 104 + (6<<1) = 116
        // BLTU uses ~c. Set c=0 => taken.
        // -------------------------
        #10;
        pc_current = 32'd104;
        imm_raw    = 13'd6;
        func3      = 3'b110; // BLTU
        z = 0; n = 0; v = 0; c = 0;
        #10;
        $display("STEP5 BLTU: PC=%0d IMM=%0d -> taken=%b target=%0d (expected=%0d)",
                 pc_current, imm_raw, branch_taken, branch_target,
                 pc_current + (imm_raw << 1));

        // -------------------------
        // STEP 6 : BGEU (func3 = 111)
        // pc = 105, imm = 7 -> target = 105 + (7<<1) = 119
        // BGEU uses c. Set c=1 => taken.
        // -------------------------
        #10;
        pc_current = 32'd105;
        imm_raw    = 13'd7;
        func3      = 3'b111; // BGEU
        z = 0; n = 0; v = 0; c = 1;
        #10;
        $display("STEP6 BGEU: PC=%0d IMM=%0d -> taken=%b target=%0d (expected=%0d)",
                 pc_current, imm_raw, branch_taken, branch_target,
                 pc_current + (imm_raw << 1));

        $display("\n===== TEST COMPLETE =====\n");
        #10 $finish;
    end

endmodule

*/





