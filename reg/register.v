module register_file (
    input  wire        clk,

    // Read ports
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,

    // Write port
    input  wire        rd_we,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data
);

    // 32 registers (x0–x31)
    reg [31:0] rf [0:31];

    // ========== WRITE OPERATION ==========
    // Synchronous write: update register on rising edge
    always @(posedge clk) begin
        if (rd_we && (rd_addr != 5'd0))
            rf[rd_addr] <= rd_data;
        rf[0] <= 32'b0; // Keep x0 = 0
    end

    // ========== READ OPERATION ==========
    // Pure combinational reads (no write-through)
    assign rs1_data = (rs1_addr == 5'd0) ? 32'b0 : rf[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'b0 : rf[rs2_addr];

endmodule


//testbench code
// ============================================================
// Testbench for Single-Cycle Register File
// ============================================================

//`timescale 1ns/1ps

module tb_register_file;

    reg         clk;
    reg         rd_we;
    reg  [4:0]  rs1_addr, rs2_addr, rd_addr;
    reg  [31:0] rd_data;
    wire [31:0] rs1_data, rs2_data;

    // Instantiate DUT
    register_file uut (
        .clk(clk),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rd_we(rd_we),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $display("===============================================");
        $display("  Register File Testbench (Single-Cycle)       ");
        $display("===============================================");
        $monitor("T=%0t | WE=%b | rd=%2d | rs1=%2d | rs2=%2d | rs1_data=%h | rs2_data=%h",
                 $time, rd_we, rd_addr, rs1_addr, rs2_addr, rs1_data, rs2_data);

        // Initialize
        rd_we = 0;
        rd_addr = 0;
        rd_data = 0;
        rs1_addr = 0;
        rs2_addr = 0;
        #10;

        // =====================================================
        // TEST 1: Write to x1, x2, x3
        // =====================================================
        $display("\nTEST 1: Write x1=1111, x2=2222, x3=3333");
        rd_we = 1;
        rd_addr = 1; rd_data = 32'h11111111; #10;
        rd_addr = 2; rd_data = 32'h22222222; #10;
        rd_addr = 3; rd_data = 32'h33333333; #10;
        rd_we = 0;

        // =====================================================
        // TEST 2: Read them back
        // =====================================================
        $display("\nTEST 2: Read back x1, x2, x3");
        rs1_addr = 1; rs2_addr = 2; #5;
        $display("x1=%h x2=%h", rs1_data, rs2_data);
        rs1_addr = 3; rs2_addr = 0; #5;
        $display("x3=%h x0=%h", rs1_data, rs2_data);

        // =====================================================
        // TEST 3: Write to x0 (should stay zero)
        // =====================================================
        $display("\nTEST 3: Try writing to x0 (ignored)");
        rd_we = 1;
        rd_addr = 0; rd_data = 32'hFFFFFFFF; #10;
        rd_we = 0;
        rs1_addr = 0; #5;
        $display("Expect x0 = 0, Got = %h", rs1_data);

        // =====================================================
        // END TEST
        // =====================================================
        $display("\nAll tests completed.");
        $finish;
    end

endmodule

