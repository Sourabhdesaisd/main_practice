
module RegisterFile (
    input  wire        Clock,        // System clock
    input  wire        RegWrite,     // Write enable signal (from WB stage)

    // Read Port 1
    input  wire [4:0]  ReadAddress1, // Address for 1st read (from ID stage)
    output wire [31:0] ReadData1,    // Data from 1st read

    // Read Port 2
    input  wire [4:0]  ReadAddress2, // Address for 2nd read (from ID stage)
    output wire [31:0] ReadData2,    // Data from 2nd read

    // Write Port
    input  wire [4:0]  WriteAddress, // Address to write (from WB stage)
    input  wire [31:0] WriteData     // Data to write (from WB stage)
);
    reg [31:0] register_memory [0:31];

  
    always @(posedge Clock) begin
        if (RegWrite) begin
            if (WriteAddress != 5'b00000) begin
                register_memory[WriteAddress] <= WriteData;
            end
        end
    end

  
    assign ReadData1 = (ReadAddress1 == 5'b00000) ? 32'b0 : register_memory[ReadAddress1];
    assign ReadData2 = (ReadAddress2 == 5'b00000) ? 32'b0 : register_memory[ReadAddress2];

   
    // 4. Initialization (Simulation Only)
 
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            register_memory[i] = 32'b0;
    end

endmodule



module RegisterFile_tb;

    // Testbench signals
    reg         Clock;
    reg         RegWrite;
    reg  [4:0]  ReadAddress1, ReadAddress2, WriteAddress;
    reg  [31:0] WriteData;
    wire [31:0] ReadData1, ReadData2;

    // Instantiate the DUT (Device Under Test)
    RegisterFile uut (
        .Clock(Clock),
        .RegWrite(RegWrite),
        .ReadAddress1(ReadAddress1),
        .ReadData1(ReadData1),
        .ReadAddress2(ReadAddress2),
        .ReadData2(ReadData2),
        .WriteAddress(WriteAddress),
        .WriteData(WriteData)
    );
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end

    // Clock generation (10 ns period)
    initial begin
        Clock = 0;
        forever #5 Clock = ~Clock;  // Toggle clock every 5 ns
    end

    // Test sequence
    initial begin
        // Display header
        
        // Initialize control signals
        RegWrite = 0;
        WriteAddress = 0;
        WriteData = 0;
        ReadAddress1 = 0;
        ReadAddress2 = 0;

        // Wait 10ns for stability
        #10;
        RegWrite = 1;
        WriteAddress = 5'd1;
        WriteData = 32'hAAAA_BBBB;
        #10; // One clock period

        
        // 2 Write to register 2
      
        WriteAddress = 5'd2;
        WriteData = 32'h1234_5678;
        #10;

       
        // 3 Try to write to register 0 ($zero)
        
        WriteAddress = 5'd3;
        WriteData = 32'hFFFF_FFFF; // Should be ignored
        #10;

        // Disable write
        RegWrite = 0;

       
        // 4 Read back values
       
        ReadAddress1 = 5'd1;
        ReadAddress2 = 5'd2;
        #2;  // Small delay to see combinational effect
        $display("%4dns | %b | %2d | %h | %2d | %h | %2d | %h",
                 $time, RegWrite, WriteAddress, WriteData,
                 ReadAddress1, ReadData1, ReadAddress2, ReadData2);

        // -----------------------------
        // 5?? Read $zero (should always be 0)
        // -----------------------------
        ReadAddress1 = 5'd0;
        ReadAddress2 = 5'd0;
        #2;
        $display("%4dns | %b | %2d | %h | %2d | %h | %2d | %h",
                 $time, RegWrite, WriteAddress, WriteData,
                 ReadAddress1, ReadData1, ReadAddress2, ReadData2);

        // Finish simulation
        #10;
        $finish;
    end

    // Monitor all changes
    initial begin
        $monitor("%4dns | %b | %2d | %h | %2d | %h | %2d | %h",
                 $time, RegWrite, WriteAddress, WriteData,
                 ReadAddress1, ReadData1, ReadAddress2, ReadData2);
    end

endmodule
//`timescale 1ns/1ps

/*module RegisterFile_tb;

    // ------------------------------------------------------------
    // DUT Signals
    // ------------------------------------------------------------
    reg         Clock;
    reg         RegWrite;
    reg  [4:0]  ReadAddress1, ReadAddress2, WriteAddress;
    reg  [31:0] WriteData;
    wire [31:0] ReadData1, ReadData2;

    integer i;  // <-- declared at module level for Verilog compatibility

    // ------------------------------------------------------------
    // Instantiate Device Under Test (DUT)
    // ------------------------------------------------------------
    RegisterFile uut (
        .Clock(Clock),
        .RegWrite(RegWrite),
        .ReadAddress1(ReadAddress1),
        .ReadData1(ReadData1),
        .ReadAddress2(ReadAddress2),
        .ReadData2(ReadData2),
        .WriteAddress(WriteAddress),
        .WriteData(WriteData)
    );
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end

    // ------------------------------------------------------------
    // Clock generation (10ns period)
    // ------------------------------------------------------------
    initial begin
        Clock = 0;
        forever #5 Clock = ~Clock;  // Toggle every 5ns
    end

    // ------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------
    initial begin
        $display("------------------------------------------------------------");
        $display("Time | RegWrite | WriteAddr | WriteData | ReadAddr1 | ReadData1 | ReadAddr2 | ReadData2");
        $display("------------------------------------------------------------");

        // Initialize
        RegWrite = 0;
        WriteAddress = 0;
        WriteData = 0;
        ReadAddress1 = 0;
        ReadAddress2 = 0;
        #10;

        // ============================================================
        // 1?? Write to registers 1–4
        // ============================================================
        RegWrite = 1;
        WriteAddress = 5'd1; WriteData = 32'hAAAA_BBBB; #10;
        WriteAddress = 5'd2; WriteData = 32'h1234_5678; #10;
        WriteAddress = 5'd3; WriteData = 32'hCAFEBABE; #10;
        WriteAddress = 5'd4; WriteData = 32'h0000_FFFF; #10;

        // ============================================================
        // 2?? Read back values
        // ============================================================
        RegWrite = 0;
        ReadAddress1 = 5'd1; ReadAddress2 = 5'd2; #2;
        $display("%4dns | %b | %2d | %h | %2d | %h | %2d | %h",
                 $time, RegWrite, WriteAddress, WriteData,
                 ReadAddress1, ReadData1, ReadAddress2, ReadData2);

        ReadAddress1 = 5'd3; ReadAddress2 = 5'd4; #2;
        $display("%4dns | %b | %2d | %h | %2d | %h | %2d | %h",
                 $time, RegWrite, WriteAddress, WriteData,
                 ReadAddress1, ReadData1, ReadAddress2, ReadData2);

        // ============================================================
        // 3?? Attempt to write to $zero (register 0)
        // ============================================================
        RegWrite = 1;
        WriteAddress = 5'd0; WriteData = 32'hDEAD_BEEF; #10;
        RegWrite = 0;
        ReadAddress1 = 5'd0; #2;
        $display("Zero Register Test ? ReadData1 = %h (should be 0)", ReadData1);

        // ============================================================
        // 4?? Back-to-back writes and reads
        // ============================================================
        RegWrite = 1;
        WriteAddress = 5'd10; WriteData = 32'hA1A1_A1A1; #10;
        WriteAddress = 5'd11; WriteData = 32'hB2B2_B2B2; #10;
        WriteAddress = 5'd12; WriteData = 32'hC3C3_C3C3; #10;
        RegWrite = 0;
        ReadAddress1 = 5'd10; ReadAddress2 = 5'd12; #2;
        $display("Back-to-back write test: R10=%h, R12=%h", ReadData1, ReadData2);

        // ============================================================
        // 5?? Read-after-write (same address)
        // ============================================================
        RegWrite = 1;
        WriteAddress = 5'd5; WriteData = 32'hFACE_CAFE;
        ReadAddress1 = 5'd5;  // same address as write
        ReadAddress2 = 5'd2;
        #1;
        $display("Before clock edge (write not yet done): R5=%h", ReadData1);
        #10; // after clock edge
        RegWrite = 0;
        #1;
        $display("After clock edge (write done): R5=%h", ReadData1);

        // ============================================================
        // 6?? Randomized write/read test
        // ============================================================
        RegWrite = 1;
        for (i = 6; i < 10; i = i + 1) begin
            WriteAddress = i;
            WriteData = $random;
            #10;
        end
        RegWrite = 0;

        for (i = 6; i < 10; i = i + 1) begin
            ReadAddress1 = i;
            ReadAddress2 = i - 1;
            #2;
            $display("R%0d=%h, R%0d=%h", ReadAddress1, ReadData1, ReadAddress2, ReadData2);
        end

        // ============================================================
        // End of simulation
        // ============================================================
        #20;
        $display("? Testbench completed successfully.");
        $finish;
    end

    // ------------------------------------------------------------
    // Monitor signals
    // ------------------------------------------------------------
    initial begin
        $monitor("%4dns | %b | %2d | %h | %2d | %h | %2d | %h",
                 $time, RegWrite, WriteAddress, WriteData,
                 ReadAddress1, ReadData1, ReadAddress2, ReadData2);
    end

endmodule
*/
