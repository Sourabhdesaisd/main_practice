// ==========================================================
// RISC-V Data Memory Unit (Integrated Load + Store + Memory)
// Supports: LB, LBU, LH, LHU, LW, SB, SH, SW
// Clean, minimal, single-cycle design
// ==========================================================

module memory_unit_top (
    input  wire         clk,          // system clock
    input  wire         MemRead,      // read enable
    input  wire         MemWrite,     // write enable
    input  wire [2:0]   funct3,       // instruction funct3 field
    input  wire [31:0]  addr,         // effective address from ALU
    input  wire [31:0]  rs2_data,     // data to be stored (from register file)
    input  wire [31:0]  mem_data_in,  // data read from memory (if external)
    output wire [31:0]  load_data_out // final read data to reg file
);

    // ------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------
    wire [31:0] mem_write_data;   // formatted data for memory write
    wire [3:0]  byte_enable;      // which bytes to enable
    wire [31:0] mem_read_data;    // raw data from memory

    // ------------------------------------------------------
    // STORE DATAPATH : prepares data and enables for write
    // ------------------------------------------------------
    store_datapath u_store (
        .funct3(funct3),
        .rs2_data(rs2_data),
        .addr(addr),
        .mem_write_data(mem_write_data),
        .byte_enable(byte_enable)
    );

    // ------------------------------------------------------
    // DATA MEMORY : main memory array
    // ------------------------------------------------------
    data_memory u_mem (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .addr(addr),
        .write_data(mem_write_data),
        .byte_enable(byte_enable),
        .read_data(mem_read_data)
    );

    // ------------------------------------------------------
    // LOAD DATAPATH : selects byte/halfword and extends
    // ------------------------------------------------------
    load_datapath u_load (
        .funct3(funct3),
        .mem_data_in(mem_read_data),
        .addr(addr),
        .load_data_out(load_data_out)
    );

endmodule




module tb_memory_unit_top;

    // Inputs
    reg         clk;
    reg         MemRead;
    reg         MemWrite;
    reg  [2:0]  funct3;
    reg  [31:0] addr;
    reg  [31:0] rs2_data;

    // Output
    wire [31:0] load_data_out;

    // Instantiate DUT
    memory_unit_top dut (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .funct3(funct3),
        .addr(addr),
        .rs2_data(rs2_data),
        .mem_data_in(32'b0),   // not used, memory internal
        .load_data_out(load_data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end



    // Test sequence
    initial begin
        clk = 0;
        MemRead = 0;
        MemWrite = 0;
        funct3 = 3'b000;
        addr = 0;
        rs2_data = 0;

        $display("\n========== MEMORY UNIT TOP TEST ==========");

        // ------------------------------------------------------
        // 1?? SW - Store Word
        // ------------------------------------------------------
        #10;
        funct3 = 3'b010;           // SW
        addr = 32'h0000_0000;
        rs2_data = 32'hDEADBEEF;
        MemWrite = 1;
        #10; MemWrite = 0;

        // LW - Load Word
        #10;
        MemRead = 1;
        funct3 = 3'b010;           // LW
        #10;
        $display("LW  @0x00 => %h (Expected DEADBEEF)", load_data_out);
        MemRead = 0;

        // ------------------------------------------------------
        // 2?? SH - Store Halfword
        // ------------------------------------------------------
        #10;
        funct3 = 3'b001;           // SH
        addr = 32'h0000_0004;
        rs2_data = 32'h0000_BEEF;
        MemWrite = 1;
        #10; MemWrite = 0;

        // LH - Load Halfword (signed)
        #10;
        MemRead = 1;
        funct3 = 3'b001;           // LH
        #10;
        $display("LH  @0x04 => %h (Expected 0000BEEF)", load_data_out);
        MemRead = 0;

        // LHU - Load Halfword Unsigned
        #10;
        MemRead = 1;
        funct3 = 3'b101;           // LHU
        #10;
        $display("LHU @0x04 => %h (Expected 0000BEEF)", load_data_out);
        MemRead = 0;

        // ------------------------------------------------------
        // 3?? SB - Store Byte
        // ------------------------------------------------------
        #10;
        funct3 = 3'b000;           // SB
        addr = 32'h0000_0008;
        rs2_data = 32'h0000_00AA;
        MemWrite = 1;
        #10; MemWrite = 0;

        // LB - Load Byte (signed)
        #10;
        MemRead = 1;
        funct3 = 3'b000;           // LB
        #10;
        $display("LB  @0x08 => %h (Expected FFFFFFAA)", load_data_out);
        MemRead = 0;

        // LBU - Load Byte Unsigned
        #10;
        MemRead = 1;
        funct3 = 3'b100;           // LBU
        #10;
        $display("LBU @0x08 => %h (Expected 000000AA)", load_data_out);
        MemRead = 0;

        // ------------------------------------------------------
        // 4?? Re-check word alignment (LW again)
        // ------------------------------------------------------
        #10;
        MemRead = 1;
        funct3 = 3'b010;
        addr = 32'h0000_0000;
        #10;
        $display("LW  @0x00 => %h (Expected DEADBEEF)", load_data_out);
        MemRead = 0;

        // ------------------------------------------------------
        $display("========== TEST COMPLETE ==========\n");
        #10;
        $finish;
    end

endmodule
