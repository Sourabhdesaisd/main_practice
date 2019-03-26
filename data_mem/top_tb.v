//`timescale 1ns/1ps
module tb_memory_stage;

    reg clk;
    reg MemRead, MemWrite;
    reg [2:0] funct3;
    reg [31:0] addr, rs2_data;
    wire [31:0] load_data_out;

    memory_stage uut (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .funct3(funct3),
        .addr(addr),
        .rs2_data(rs2_data),
        .load_data_out(load_data_out)
    );
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end
    // Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0; MemRead = 0; MemWrite = 0;
        funct3 = 3'b000; addr = 0; rs2_data = 0;

        // 1?? Store Word
        #10 addr = 32'h0000_0000; rs2_data = 32'hDDCCBBAA;
            funct3 = 3'b010; MemWrite = 1;
        #10 MemWrite = 0;

        // 2?? Load Word
        #10 MemRead = 1; funct3 = 3'b010;
        #10 $display("LW Read = %h", load_data_out);
        MemRead = 0;

        // 3?? Store Byte at addr+1
        #10 addr = 32'h0000_0001; rs2_data = 32'h000000EE;
            funct3 = 3'b000; MemWrite = 1;
        #10 MemWrite = 0;

        // 4?? Load Word again
        #10 MemRead = 1; funct3 = 3'b010;
        #10 $display("After SB Read = %h", load_data_out);
        MemRead = 0;

        #20 $finish;
    end

endmodule

