module jump_unit (
    input  [31:0] pc_current,   // current PC
    input  [31:0] rs1_value,    // rs1 for JALR
    input  [20:0] jal_imm_raw,  // UJ immediate (already extracted & aligned)
    input  [11:0] jalr_imm_raw, // I immediate (already extracted)

    input        jal_enable,    // control signal
    input        jalr_enable,

    output [31:0] jump_target,
    output        jump_taken
);

    // ----------------------------------------------------
    // 1. Sign extend immediates
    // ----------------------------------------------------
    wire [31:0] jal_imm_ext  = {{11{jal_imm_raw[20]}}, jal_imm_raw}; // 21-bit ? 32-bit
    wire [31:0] jalr_imm_ext = {{20{jalr_imm_raw[11]}}, jalr_imm_raw};

    // ----------------------------------------------------
    // 2. Form targets
    // ----------------------------------------------------
    wire [31:0] jal_target;
    wire [31:0] jalr_target;

    assign jal_target  = pc_current + (jal_imm_ext << 1); 
    assign jalr_target = (rs1_value + jalr_imm_ext) & 32'hFFFFFFFE; // clear LSB

    // ----------------------------------------------------
    // 3. Select jump
    // ----------------------------------------------------
    assign jump_taken  = jal_enable | jalr_enable;

    assign jump_target = (jal_enable)  ? jal_target  :
                         (jalr_enable) ? jalr_target :
                         32'b0;

endmodule


/*
//`timescale 1ns/1ps

module jump_unit_tb;

    reg  [31:0] pc_current;
    reg  [31:0] rs1_value;
    reg  [20:0] jal_imm_raw;     // UJ immediate
    reg  [11:0] jalr_imm_raw;    // I immediate

    reg         jal_enable;
    reg         jalr_enable;

    wire [31:0] jump_target;
    wire        jump_taken;

    // --------------------------------------------------------
    // Instantiate DUT
    // --------------------------------------------------------
    jump_unit DUT (
        .pc_current(pc_current),
        .rs1_value(rs1_value),
        .jal_imm_raw(jal_imm_raw),
        .jalr_imm_raw(jalr_imm_raw),
        .jal_enable(jal_enable),
        .jalr_enable(jalr_enable),
        .jump_target(jump_target),
        .jump_taken(jump_taken)
    );

initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end


    initial begin
        $display("\n--- JUMP UNIT TEST START ---\n");

        // ---------------------------------------------
        // TEST 1 : JAL
        // ---------------------------------------------
        pc_current   = 32'h00000010;  // 16 decimal
        jal_imm_raw  = 21'b000000000000000001010; // imm = 10 decimal
        jal_enable   = 1;
        jalr_enable  = 0;
        rs1_value    = 0;
        jalr_imm_raw = 0;

        #5;
        $display("TEST1: JAL");
        $display("jump_taken  = %b", jump_taken);
        $display("jump_target = %h\n", jump_target);

        // ---------------------------------------------
        // TEST 2 : JALR
        // ---------------------------------------------
        pc_current   = 32'h00000020;  // 32 decimal
        rs1_value    = 32'h00000050;  // 80 decimal
        jalr_imm_raw = 12'd4;         // imm = 4
        jal_enable   = 0;
        jalr_enable  = 1;

        #5;
        $display("TEST2: JALR");
        $display("jump_taken  = %b", jump_taken);
        $display("jump_target = %h\n", jump_target);

        // ---------------------------------------------
        // TEST 3 : No Jump
        // ---------------------------------------------
        pc_current   = 32'h10000000;
        jal_enable   = 0;
        jalr_enable  = 0;
        rs1_value    = 0;
        jal_imm_raw  = 0;
        jalr_imm_raw = 0;

        #5;
        $display("TEST3: NO JUMP");
        $display("jump_taken  = %b", jump_taken);
        $display("jump_target = %h\n", jump_target);

        $display("\n--- JUMP UNIT TEST END ---\n");
        $finish;
    end

endmodule*/

