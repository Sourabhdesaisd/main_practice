// ==========================================================
// RISC-V Memory Stage (Single Cycle)
// Combines load_datapath + store_datapath + data_memory
// ==========================================================

module memory_stage (
    input  wire        clk,           // for memory write
    input  wire        MemRead,       // control signal from control unit
    input  wire        MemWrite,      // control signal from control unit
    input  wire [2:0]  funct3,        // to identify load/store type
    input  wire [31:0] addr,          // effective address from ALU
    input  wire [31:0] rs2_data,      // data from register file (for store)
    output wire [31:0] load_data_out  // final data to register file (for load)
);

    // ---------------------------------------------
    // Internal wires
    // ---------------------------------------------
    wire [31:0] mem_read_data;    // data read from memory
    wire [31:0] mem_write_data;   // data to be written to memory
    wire [3:0]  byte_enable;      // which bytes are active for write

    // ---------------------------------------------
    // STORE path
    // ---------------------------------------------
    store_datapath u_store (
        .funct3(funct3),
        .rs2_data(rs2_data),
        .addr(addr),
        .mem_write_data(mem_write_data),
        .byte_enable(byte_enable)
    );

    // ---------------------------------------------
    // MEMORY block
    // ---------------------------------------------
    data_memory u_mem (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .addr(addr),
        .write_data(mem_write_data),
        .byte_enable(byte_enable),
        .read_data(mem_read_data)
    );

    // ---------------------------------------------
    // LOAD path
    // ---------------------------------------------
    load_datapath u_load (
        .funct3(funct3),
        .mem_data_in(mem_read_data),
        .addr(addr),
        .load_data_out(load_data_out)
    );

endmodule

