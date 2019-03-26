
module data_memory (
    input  wire        clk,          // clock
    input  wire        MemRead,      // Memory read enable
    input  wire        MemWrite,     // Memory write enable
    input  wire [31:0] addr,         // Byte address from ALU
    input  wire [31:0] write_data,   // Data from store_datapath
    input  wire [3:0]  byte_enable,  // Byte enables from store_datapath
    output reg  [31:0] read_data     // Data to load_datapath
);

   
    // Memory array: 4KB = 4096 bytes
   
    reg [7:0] memory [0:4095];

    integer i;

   
    // Initialization (optional) - set all memory to 0

    initial begin
        for (i = 0; i < 4096; i = i + 1)
            memory[i] = 8'b0;
    end

    // ------------------------------------------------------
    // READ Logic (Combinational)
    // ------------------------------------------------------
    always @(*) begin
        if (MemRead) begin
            // Little-endian: lowest address = least significant byte
            read_data = { memory[addr + 3],
                          memory[addr + 2],
                          memory[addr + 1],
                          memory[addr + 0] };
        end else begin
            read_data = 32'b0;
        end
    end

    // ------------------------------------------------------
    // WRITE Logic (Synchronous)
    // ------------------------------------------------------
    always @(posedge clk) begin
        if (MemWrite) begin
            if (byte_enable[0]) memory[addr + 0] <= write_data[7:0];
            if (byte_enable[1]) memory[addr + 1] <= write_data[15:8];
            if (byte_enable[2]) memory[addr + 2] <= write_data[23:16];
            if (byte_enable[3]) memory[addr + 3] <= write_data[31:24];
        end
    end

endmodule



/*
// ==========================================================
// Simple Testbench for data_memory
// ==========================================================
//`timescale 1ns / 1ps

module tb_data_memory;

    // Inputs
    reg         clk;
    reg         MemRead;
    reg         MemWrite;
    reg  [31:0] addr;
    reg  [31:0] write_data;
    reg  [3:0]  byte_enable;

    // Output
    wire [31:0] read_data;

    // Instantiate DUT (Device Under Test)
    data_memory dut (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .addr(addr),
        .write_data(write_data),
        .byte_enable(byte_enable),
        .read_data(read_data)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 10ns period
    end
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end


    // Test sequence
    initial begin
        $display("===== DATA MEMORY TEST START =====");
        MemRead = 0;
        MemWrite = 0;
        addr = 0;
        write_data = 0;
        byte_enable = 4'b0000;
        #10;

        // ------------------------------------------------
        // 1?? Write a word (SW) at address 0x00000000
        // ------------------------------------------------
        addr = 32'h00000000;
        write_data = 32'hDEADBEEF;
        byte_enable = 4'b1111;   // SW (write all bytes)
        MemWrite = 1;
        #10;                     // Wait one clock cycle
        MemWrite = 0;

        // ------------------------------------------------
        // 2?? Read back the word (LW)
        // ------------------------------------------------
        MemRead = 1;
        #10;
        $display("Read Data = %h (expected DEADBEEF)", read_data);
        MemRead = 0;

        // ------------------------------------------------
        // 3?? Write halfword (SH) at address 0x00000004
        // ------------------------------------------------
        addr = 32'h00000004;
        write_data = 32'h0000BEEF;
        byte_enable = 4'b0011;   // SH (write lower half)
        MemWrite = 1;
        #10;
        MemWrite = 0;

        // ------------------------------------------------
        // 4?? Read back the word containing the halfword
        // ------------------------------------------------
        MemRead = 1;
        #10;
        $display("Read Data = %h (expected 0000BEEF)", read_data);
        MemRead = 0;

        // ------------------------------------------------
        // 5?? End simulation
        // ------------------------------------------------
        #10;
        $display("===== DATA MEMORY TEST END =====");
        $finish;
    end

endmodule
*/




//`timescale 1ns / 1ps
// ==========================================================
// Testbench for data_memory (standalone verification)
// ==========================================================
module tb_data_memory;

    reg         clk;
    reg         MemRead;
    reg         MemWrite;
    reg  [31:0] addr;
    reg  [31:0] write_data;
    reg  [3:0]  byte_enable;
    wire [31:0] read_data;

    // DUT instance
    data_memory dut (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .addr(addr),
        .write_data(write_data),
        .byte_enable(byte_enable),
        .read_data(read_data)
    );
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end


    // Clock generation
    always #5 clk = ~clk;  // 10ns period

    initial begin
        clk = 0;
        MemRead = 0;
        MemWrite = 0;
        addr = 0;
        write_data = 0;
        byte_enable = 4'b0000;

        $display("===== MEMORY BLOCK TEST START =====");

        // ------------------------------------------------
        // Write full word
        // ------------------------------------------------
        #10;
        addr = 32'h0000_0000;
        write_data = 32'hDEADBEEF;
        byte_enable = 4'b1111;
        MemWrite = 1;
        #10; MemWrite = 0;

        // Read back full word
        MemRead = 1;
        #10;
        $display("Read Data @0x00 = %h (expected DEADBEEF)", read_data);
        MemRead = 0;

        // ------------------------------------------------
        // Write lower halfword (0xBEEF)
        // ------------------------------------------------
        #10;
        addr = 32'h0000_0004;
        write_data = 32'h0000_BEEF;
        byte_enable = 4'b0011;
        MemWrite = 1;
        #10; MemWrite = 0;

        // Read back the halfword area
        MemRead = 1;
        #10;
        $display("Read Data @0x04 = %h (expected 0000BEEF)", read_data);
        MemRead = 0;

        // ------------------------------------------------
        // Write one byte (0xAA)
        // ------------------------------------------------
        #10;
        addr = 32'h0000_0008;
        write_data = 32'h0000_00AA;
        byte_enable = 4'b0001;
        MemWrite = 1;
        #10; MemWrite = 0;

        // Read back byte region
        MemRead = 1;
        #10;
        $display("Read Data @0x08 = %h (expected 000000AA)", read_data);
        MemRead = 0;

        $display("===== MEMORY BLOCK TEST END =====");
        #10;
        $finish;
    end

endmodule


