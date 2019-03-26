//==========================================================
// 32-bit Instruction Memory (Hex File Loaded via $readmemh)
//==========================================================
module instruction_memory (
    input  [31:0] pc,             // Program Counter (word-aligned)
    output [31:0] instruction     // Fetched 32-bit instruction
);

    // 256 words = 1024 bytes (increase if needed)
    reg [31:0] mem [0:255];

    // Load program.hex file into memory
    initial begin
        $readmemh("instr_mem.hex", mem);   // <-- place program.hex in same folder
    end

    // Word-aligned fetch: PC = 0,4,8,12,...
    assign instruction = mem[pc[31:2]];

endmodule

