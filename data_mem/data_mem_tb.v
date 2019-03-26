// ==========================================================
// Testbench for data_memory.v
// Verifies LB/LBU/LH/LHU/LW/SB/SH/SW operations
// ==========================================================

//`timescale 1ns/1ps

module tb_data_memory;

    // Inputs
    reg clk;
    reg MemRead;
    reg MemWrite;
    reg [2:0] funct3;
    reg [31:0] address;
    reg [31:0] WriteData;

    // Outputs
    wire [31:0] ReadData;
    wire misaligned;

    // DUT (Device Under Test)
    data_memory uut (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .funct3(funct3),
        .address(address),
        .WriteData(WriteData),
        .ReadData(ReadData),
        .misaligned(misaligned)
    );

initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end

    // Clock generation
    always #5 clk = ~clk; // 10ns clock period

    // Test procedure
    initial begin
        // Initialize
        clk = 0;
        MemRead = 0;
        MemWrite = 0;
        funct3 = 3'b000;
        address = 0;
        WriteData = 0;

        $display("===== DATA MEMORY UNIT TEST START =====");

        // ------------------------------------------------------
        // Test 1: Store Word (SW)
        // ------------------------------------------------------
        #10;
        MemWrite = 1;
        funct3 = 3'b010;        // SW
        address = 32'h00000010; // word-aligned
        WriteData = 32'hAABBCCDD;
        #10;                    // 1 clock cycle
        MemWrite = 0;
        $display("SW: Stored 0x%h at address 0x%h", WriteData, address);

        // ------------------------------------------------------
        // Test 2: Load Word (LW)
        // ------------------------------------------------------
        #10;
        MemRead = 1;
        funct3 = 3'b010;        // LW
        address = 32'h00000010;
        #5;
        $display("LW: ReadData = 0x%h (expected 0xAABBCCDD)", ReadData);
        MemRead = 0;

        // ------------------------------------------------------
        // Test 3: Load Byte (LB) from address 0x10 (should be DD)
        // ------------------------------------------------------
        #10;
        MemRead = 1;
        funct3 = 3'b000;        // LB
        address = 32'h00000010;
        #5;
        $display("LB: ReadData = 0x%h (expected 0xFFFFFFDD for signed DD)", ReadData);
        MemRead = 0;

        // ------------------------------------------------------
        // Test 4: Load Byte Unsigned (LBU)
        // ------------------------------------------------------
        #10;
        MemRead = 1;
        funct3 = 3'b100;        // LBU
        address = 32'h00000010;
        #5;
        $display("LBU: ReadData = 0x%h (expected 0x000000DD)", ReadData);
        MemRead = 0;

        // ------------------------------------------------------
        // Test 5: Store Halfword (SH)
        // ------------------------------------------------------
        #10;
        MemWrite = 1;
        funct3 = 3'b001;        // SH
        address = 32'h00000020;
        WriteData = 32'h0000BEEF;
        #10;
        MemWrite = 0;
        $display("SH: Stored halfword 0xBEEF at address 0x%h", address);

        // ------------------------------------------------------
        // Test 6: Load Halfword (LH)
        // ------------------------------------------------------
        #10;
        MemRead = 1;
        funct3 = 3'b001;        // LH
        address = 32'h00000020;
        #5;
        $display("LH: ReadData = 0x%h (expected 0xFFFFBEEF)", ReadData);
        MemRead = 0;

        // ------------------------------------------------------
        // Test 7: Load Halfword Unsigned (LHU)
        // ------------------------------------------------------
        #10;
        MemRead = 1;
        funct3 = 3'b101;        // LHU
        address = 32'h00000020;
        #5;
        $display("LHU: ReadData = 0x%h (expected 0x0000BEEF)", ReadData);
        MemRead = 0;

        // ------------------------------------------------------
        // Test 8: Misaligned SW (address not multiple of 4)
        // ------------------------------------------------------
        #10;
        MemWrite = 1;
        funct3 = 3'b010;        // SW
        address = 32'h00000013; // not aligned
        WriteData = 32'hDEADBEEF;
        #10;
        MemWrite = 0;
        $display("SW misaligned test: misaligned = %b (expected 1)", misaligned);

        // ------------------------------------------------------
        // End
        #10;
        $display("===== DATA MEMORY UNIT TEST END =====");
        $finish();
    end

endmodule

