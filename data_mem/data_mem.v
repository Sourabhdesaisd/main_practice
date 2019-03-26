module data_memory (
    input  wire         clk,          // system clock
    input  wire         MemRead,      // memory read enable
    input  wire         MemWrite,     // memory write enable
    input  wire [2:0]   funct3,       // determines load/store type
    input  wire [31:0]  address,      // effective address from ALU
    input  wire [31:0]  WriteData,    // data to store (from RS2)
    output reg  [31:0]  ReadData,     // data to load (to RD)
    output wire         misaligned    // alignment error flag
);

    // ------------------------------------------------------
    // 4KB Byte-Addressable Memory (8-bit entries)
    // ------------------------------------------------------
    reg [7:0] memory_array [0:4095]; // each entry = 1 byte

    // ------------------------------------------------------
    // Alignment check logic
    // ------------------------------------------------------
    assign misaligned =
        ((funct3 == 3'b001 || funct3 == 3'b101) && address[0])      || // LH/LHU
        ((funct3 == 3'b010) && |address[1:0]);                        // LW

    // ------------------------------------------------------
    // WRITE Operation (Synchronous)
    // ------------------------------------------------------
    always @(posedge clk) begin
        if (MemWrite && !misaligned) begin
            case (funct3)
                3'b000: begin // SB - store byte
                    memory_array[address] <= WriteData[7:0];
                end

                3'b001: begin // SH - store halfword
                    memory_array[address]     <= WriteData[7:0];
                    memory_array[address + 1] <= WriteData[15:8];
                end

                3'b010: begin // SW - store word
                    memory_array[address]     <= WriteData[7:0];
                    memory_array[address + 1] <= WriteData[15:8];
                    memory_array[address + 2] <= WriteData[23:16];
                    memory_array[address + 3] <= WriteData[31:24];
                end
            endcase
        end
    end

    // ------------------------------------------------------
    // READ Operation (Combinational)
    // ------------------------------------------------------
    always @(*) begin
        if (MemRead && !misaligned) begin
            case (funct3)
                3'b000:  // LB - load byte (sign-extend)
                    ReadData = {{24{memory_array[address][7]}},
                                memory_array[address]};

                3'b100:  // LBU - load byte (zero-extend)
                    ReadData = {24'b0, memory_array[address]};

                3'b001:  // LH - load halfword (sign-extend)
                    ReadData = {{16{memory_array[address + 1][7]}},
                                memory_array[address + 1],
                                memory_array[address]};

                3'b101:  // LHU - load halfword (zero-extend)
                    ReadData = {16'b0,
                                memory_array[address + 1],
                                memory_array[address]};

                3'b010:  // LW - load word (32-bit)
                    ReadData = {memory_array[address + 3],
                                memory_array[address + 2],
                                memory_array[address + 1],
                                memory_array[address]};

                default:
                    ReadData = 32'b0;
            endcase
        end else begin
            ReadData = 32'b0;
        end
    end

endmodule
