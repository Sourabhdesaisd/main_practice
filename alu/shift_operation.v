module shifter_unit32 (
    input  [31:0] A,         // rs1
    input  [31:0] B,         // rs2 or imm (already selected outside)
    input  [6:0]  opcode,    // instruction[6:0]
    input  [2:0]  func3,     // instruction[14:12]
    input  [6:0]  func7,     // instruction[31:25] for R-type
    input  [31:0] imm,       // full immediate (for imm[11:5] check)
    output reg [31:0] Y
);

    // R-type and I-type opcodes
    localparam OPCODE_R = 7'b0110011;
    localparam OPCODE_I = 7'b0010011;

    reg [4:0] shamt;

    always @(*) begin

        // Select shamt based on instruction type
        if (opcode == OPCODE_R)
            shamt = B[4:0];        // rs2[4:0]
        else if (opcode == OPCODE_I)
            shamt = imm[4:0];      // imm[4:0]
        else
            shamt = 5'd0;

        case (func3)

            // -------------------------------------------------
            // SLL  (shift left logical)
            // SLLI
            // func3 = 001
            // -------------------------------------------------
            3'b001: begin
                // SLL  ? R-type
                if (opcode == OPCODE_R && func7 == 7'b0000000)
                    Y = A << shamt;

                // SLLI ? I-type (imm[11:5] = 0)
                else if (opcode == OPCODE_I && imm[11:5] == 7'b0000000)
                    Y = A << shamt;

                else
                    Y = 32'b0;
            end

            // -------------------------------------------------
            // SRL, SRLI, SRA, SRAI
            // func3 = 101
            // -------------------------------------------------
            3'b101: begin

                // ---------------------------------------------
                // SRL (logical right shift)
                // SRLI
                // ---------------------------------------------
                if (opcode == OPCODE_R && func7 == 7'b0000000)
                    Y = A >> shamt;

                else if (opcode == OPCODE_I && imm[11:5] == 7'b0000000)
                    Y = A >> shamt;

                // ---------------------------------------------
                // SRA (arithmetic right shift)
                // SRAI
                // ---------------------------------------------
                else if (opcode == OPCODE_R && func7 == 7'b0100000)
                    Y = $signed(A) >>> shamt;

                else if (opcode == OPCODE_I && imm[11:5] == 7'b0100000)
                    Y = $signed(A) >>> shamt;

                else
                    Y = 32'b0;
            end

            default: Y = 32'b0;

        endcase
    end

endmodule





module tb_shifter_unit32;

    reg  [31:0] A;    
    reg  [31:0] B;    
    reg  [6:0]  opcode;
    reg  [2:0]  func3;
    reg  [6:0]  func7;
    reg  [31:0] imm;
    wire [31:0] Y;

    // Instantiate DUT
    shifter_unit32 dut (
        .A(A),
        .B(B),
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .imm(imm),
        .Y(Y)
    );

    // Opcodes
    localparam OPCODE_R = 7'b0110011;
    localparam OPCODE_I = 7'b0010011;

initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end



    initial begin
        $display("\n===== SHIFT OPERATION TEST START =====\n");

        // ------------------------------------------
        // SLL  (A << B[4:0])
        // ------------------------------------------
        A = 32'h0000_0005;   // 5
        B = 32'h0000_0002;   // shift 2
        imm = 32'b0;
        opcode = OPCODE_R;
        func3  = 3'b001;
        func7  = 7'b0000000;
        #10;
        $display("SLL  : A=5, shamt=2, Result=%h  (Expected = 0x00000014)", Y);

        // ------------------------------------------
        // SLLI (A << imm)
        // ------------------------------------------
        A = 32'h0000_0003;  
        B = 32'b0;
        imm = {20'b0, 7'b0000000, 5'd4};  // imm[11:5]=0000000, imm[4:0]=4
        opcode = OPCODE_I;
        func3  = 3'b001;
        func7  = 7'b0000000;
        #10;
        $display("SLLI : A=3, shamt=4, Result=%h  (Expected = 0x00000030)", Y);

        // ------------------------------------------
        // SRL  (A >> B[4:0])
        // ------------------------------------------
        A = 32'h0000_0020;   // 32
        B = 32'h0000_0003;   // shift 3
        imm = 32'b0;
        opcode = OPCODE_R;
        func3  = 3'b101;
        func7  = 7'b0000000; // logical
        #10;
        $display("SRL  : A=32, shamt=3, Result=%h  (Expected = 0x00000004)", Y);

        // ------------------------------------------
        // SRLI (A >> imm)
        // ------------------------------------------
        A = 32'h0000_0040;   
        imm = {20'b0, 7'b0000000, 5'd2};  // imm[11:5]=0, shift=2
        opcode = OPCODE_I;
        func3  = 3'b101;
        func7  = 7'b0000000;
        #10;
        $display("SRLI : A=64, shamt=2, Result=%h  (Expected = 0x00000010)", Y);

        // ------------------------------------------
        // SRA  (signed A >>> B[4:0])
        // ------------------------------------------
        A = 32'hFFFF_FFF0;   // -16
        B = 32'h0000_0002;   // shift 2
        imm = 32'b0;
        opcode = OPCODE_R;
        func3  = 3'b101;
        func7  = 7'b0100000; // arithmetic
        #10;
        $display("SRA  : A=-16, shamt=2, Result=%h  (Expected = 0xFFFFFFFC)", Y);

        // ------------------------------------------
        // SRAI (signed A >>> imm)
        // ------------------------------------------
        A = 32'hFFFF_F000;   // -4096
        imm = {20'b0, 7'b0100000, 5'd4};  // imm[11:5]=0100000 ? arithmetic
        opcode = OPCODE_I;
        func3  = 3'b101;
        func7  = 7'b0100000;
        #10;
        $display("SRAI : A=-4096, shamt=4, Result=%h  (Expected ˜ 0xFFFFFFF0)", Y);

        $display("\n===== SHIFT OPERATION TEST END =====\n");
        $finish;
    end

endmodule
