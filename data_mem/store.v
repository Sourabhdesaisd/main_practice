module store_datapath (
    input  wire [2:0]   funct3,         // from instruction (000=SB, 001=SH, 010=SW)
    input  wire [31:0]  rs2_data,       // data to be stored
    input  wire [31:0]  addr,           // effective address from ALU
    output reg  [31:0]  mem_write_data, // data aligned for memory
    output reg  [3:0]   byte_enable     // active byte lanes
);

    always @(*) begin
        // Default values
        mem_write_data = 32'b0;
        byte_enable    = 4'b0000;

        case (funct3)
            // ---------------- SB ----------------
            3'b000: begin
                case (addr[1:0])
                    2'b00: begin mem_write_data = {24'b0, rs2_data[7:0]};  byte_enable = 4'b0001; end
                    2'b01: begin mem_write_data = {16'b0, rs2_data[7:0], 8'b0}; byte_enable = 4'b0010; end
                    2'b10: begin mem_write_data = {8'b0,  rs2_data[7:0], 16'b0}; byte_enable = 4'b0100; end
                    2'b11: begin mem_write_data = {rs2_data[7:0], 24'b0};      byte_enable = 4'b1000; end
                endcase
            end

            // ---------------- SH ----------------
            3'b001: begin
                case (addr[1])
                    1'b0: begin mem_write_data = {16'b0, rs2_data[15:0]}; byte_enable = 4'b0011; end
                    1'b1: begin mem_write_data = {rs2_data[15:0], 16'b0}; byte_enable = 4'b1100; end
                endcase
            end

            // ---------------- SW ----------------
            3'b010: begin
                mem_write_data = rs2_data;
                byte_enable    = 4'b1111;
            end

            default: begin
                mem_write_data = 32'b0;
                byte_enable    = 4'b0000;
            end
        endcase
    end

endmodule

//`timescale 1ns/1ps
module tb_store_datapath;

    reg  [2:0]  funct3;
    reg  [31:0] rs2_data;
    reg  [31:0] addr;
    wire [31:0] mem_write_data;
    wire [3:0]  byte_enable;

    store_datapath uut (
        .funct3(funct3),
        .rs2_data(rs2_data),
        .addr(addr),
        .mem_write_data(mem_write_data),
        .byte_enable(byte_enable)
    );
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end

    initial begin
        $display("funct3 | addr | addr[1:0] | rs2_data | mem_write_data | byte_enable");
        $display("-------------------------------------------------------------");

        rs2_data = 32'hAABBCCDD;

        // SB tests
        funct3 = 3'b000;
        addr = 32'h0000_1000; #1;
        $display("SB | %h | %b | %h | %h | %b", addr, addr[1:0], rs2_data, mem_write_data, byte_enable);

        addr = 32'h0000_1001; #1;
        $display("SB | %h | %b | %h | %h | %b", addr, addr[1:0], rs2_data, mem_write_data, byte_enable);

        addr = 32'h0000_1002; #1;
        $display("SB | %h | %b | %h | %h | %b", addr, addr[1:0], rs2_data, mem_write_data, byte_enable);

        addr = 32'h0000_1003; #1;
        $display("SB | %h | %b | %h | %h | %b", addr, addr[1:0], rs2_data, mem_write_data, byte_enable);

        // SH tests
        funct3 = 3'b001;
        addr = 32'h0000_2000; #1;
        $display("SH | %h | %b | %h | %h | %b", addr, addr[1:0], rs2_data, mem_write_data, byte_enable);

        addr = 32'h0000_2002; #1;
        $display("SH | %h | %b | %h | %h | %b", addr, addr[1:0], rs2_data, mem_write_data, byte_enable);

        // SW test
        funct3 = 3'b010;
        addr = 32'h0000_3000; #1;
        $display("SW | %h | %b | %h | %h | %b", addr, addr[1:0], rs2_data, mem_write_data, byte_enable);

        $finish;
    end

endmodule

