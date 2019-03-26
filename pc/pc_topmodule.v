module pc_top (
    input         clk,
    input         reset,

    // -------- Branch Inputs --------
    input  [12:0] imm_raw_branch,
    input         z, n, v, c,
    input  [2:0]  func3_branch,
    input         branch_enable,

    // -------- Jump Inputs --------
    input  [20:0] jal_imm_raw,
    input  [11:0] jalr_imm_raw,
    input  [31:0] rs1_value,
    input         jal_enable,
    input         jalr_enable,

    // -------- Output --------
    output [31:0] pc_current
);

    wire [31:0] pc_next;
    wire [31:0] pc_seq;
    wire [31:0] branch_target;
    wire        branch_taken;
    wire [31:0] jump_target;
    wire        jump_taken;


    // ============================================================
    // 1. PC Register
    // ============================================================
    pc_reg PCREG (
        .clk(clk),
        .reset(reset),
        .pc_next(pc_next),
        .pc_current(pc_current)
    );


    // ============================================================
    // 2. Sequential Unit (PC + 4)
    // ============================================================
    sequential_unit SEQ (
        .pc_current(pc_current),
        .pc_next_seq(pc_seq)
    );


    // ============================================================
    // 3. Branch Unit
    // ============================================================
    branch_unit BR (
        .pc_current(pc_current),
        .imm_raw(imm_raw_branch),
        .z(z), .n(n), .v(v), .c(c),
        .func3(func3_branch),
        .branch_enable(branch_enable),
        .branch_taken(branch_taken),
        .branch_target(branch_target)
    );


    // ============================================================
    // 4. Jump Unit
    // ============================================================
    jump_unit JUMP (
        .pc_current(pc_current),
        .rs1_value(rs1_value),
        .jal_imm_raw(jal_imm_raw),
        .jalr_imm_raw(jalr_imm_raw),
        .jal_enable(jal_enable),
        .jalr_enable(jalr_enable),
        .jump_target(jump_target),
        .jump_taken(jump_taken)
    );


    // ============================================================
    // 5. MUX A ? Branch vs Sequential
    // ============================================================
    wire [31:0] pc_after_branch;
    assign pc_after_branch = (branch_taken) ? branch_target : pc_seq;


    // ============================================================
    // 6. MUX B ? Jump override
    // ============================================================
    assign pc_next = (jump_taken) ? jump_target : pc_after_branch;

endmodule



//`timescale 1ns/1ps

module pc_top_tb;

    reg clk;
    reg reset;

    // -------- Branch Inputs --------
    reg  [12:0] imm_raw_branch;
    reg         z, n, v, c;
    reg  [2:0]  func3_branch;
    reg         branch_enable;

    // -------- Jump Inputs --------
    reg  [20:0] jal_imm_raw;
    reg  [11:0] jalr_imm_raw;
    reg  [31:0] rs1_value;
    reg         jal_enable;
    reg         jalr_enable;

    wire [31:0] pc_current;

    // Instantiate DUT
    pc_top DUT (
        .clk(clk),
        .reset(reset),

        .imm_raw_branch(imm_raw_branch),
        .z(z), .n(n), .v(v), .c(c),
        .func3_branch(func3_branch),
        .branch_enable(branch_enable),

        .jal_imm_raw(jal_imm_raw),
        .jalr_imm_raw(jalr_imm_raw),
        .rs1_value(rs1_value),
        .jal_enable(jal_enable),
        .jalr_enable(jalr_enable),

        .pc_current(pc_current)
    );

initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end


    // ============================================================
    // Clock generation
    // ============================================================
    always #5 clk = ~clk;



    // ============================================================
    // MAIN TEST STIMULUS
    // ============================================================
    initial begin
        
        clk = 0;
        reset = 1;

        // initialize all signals
        imm_raw_branch = 0;
        z = 0; n = 0; v = 0; c = 0;
        func3_branch = 3'b000;
        branch_enable = 0;

        jal_imm_raw = 0;
        jalr_imm_raw = 0;
        rs1_value = 0;
        jal_enable = 0;
        jalr_enable = 0;

        #12 reset = 0;     // RELEASE RESET



        // ------------------------------------------------------------
        // 1. THREE SEQUENTIAL EXECUTIONS
        // ------------------------------------------------------------
        @(posedge clk);
        $display("SEQ1 PC = %0d", pc_current);

        @(posedge clk);
        $display("SEQ2 PC = %0d", pc_current);

        @(posedge clk);
        $display("SEQ3 PC = %0d", pc_current);



        // ============================================================
        // 2. ALL BRANCH EXECUTIONS  (6 TYPES)
        // imm_raw_branch = 4 ? effective offset = +8
        // ============================================================
        imm_raw_branch = 13'd4;
        branch_enable  = 1;

        // BEQ — taken
        func3_branch = 3'b000;  z = 1;
        @(posedge clk);
        $display("BRANCH BEQ TAKEN PC = %0d", pc_current);

        // BNE — taken
        func3_branch = 3'b001; z = 0;
        @(posedge clk);
        $display("BRANCH BNE TAKEN PC = %0d", pc_current);

        // BLT — taken (n ^ v = 1)
        func3_branch = 3'b100; n = 1; v = 0;
        @(posedge clk);
        $display("BRANCH BLT TAKEN PC = %0d", pc_current);

        // BGE — taken (n ^ v = 0)
        func3_branch = 3'b101; n = 0; v = 0;
        @(posedge clk);
        $display("BRANCH BGE TAKEN PC = %0d", pc_current);

        // BLTU — taken (~c = 1)
        func3_branch = 3'b110; c = 0;
        @(posedge clk);
        $display("BRANCH BLTU TAKEN PC = %0d", pc_current);

        // BGEU — taken (c = 1)
        func3_branch = 3'b111; c = 1;
        @(posedge clk);
        $display("BRANCH BGEU TAKEN PC = %0d", pc_current);

        // Disable branch
        branch_enable = 0;
        z = 0; n = 0; v = 0; c = 0;



        // ------------------------------------------------------------
        // 3. TWO MORE SEQUENTIAL EXECUTIONS
        // ------------------------------------------------------------
        @(posedge clk);
        $display("SEQ4 PC = %0d", pc_current);

        @(posedge clk);
        $display("SEQ5 PC = %0d", pc_current);



        // ------------------------------------------------------------
        // 4. JUMP EXECUTIONS (JAL + JALR)
        // ------------------------------------------------------------
        // JAL ? offset = (4 << 1) = 8
        jal_enable  = 1;
        jal_imm_raw = 20'd4;

        @(posedge clk);
        $display("JAL PC = %0d", pc_current);

        jal_enable = 0;


        // JALR ? rs1 + imm = 100 + 4 = 104
        jalr_enable  = 1;
        rs1_value    = 32'd100;
        jalr_imm_raw = 12'd4;

        @(posedge clk);
        $display("JALR PC = %0d", pc_current);

        jalr_enable = 0;



        // ------------------------------------------------------------
        // 5. ONE MORE SEQUENTIAL
        // ------------------------------------------------------------
        @(posedge clk);
        $display("SEQ6 PC = %0d", pc_current);



        // ------------------------------------------------------------
        // 6. TWO BRANCH INSTRUCTIONS
        // ------------------------------------------------------------
        branch_enable = 1;
        imm_raw_branch = 13'd12;     // offset = 4

        // BEQ taken
        func3_branch = 3'b000; z = 1;
        @(posedge clk);
        $display("BRANCH1 BEQ PC = %0d", pc_current);

        // BNE taken
        func3_branch = 3'b001; z = 0;
        @(posedge clk);
        $display("BRANCH2 BNE PC = %0d", pc_current);



        #20;
        $finish;
    end

endmodule

