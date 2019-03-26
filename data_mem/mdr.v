module load_datapath (
    input  wire [2:0]   funct3,         // from instruction
    input  wire [31:0]  mem_data_in,    // 32-bit data read from memory
    input  wire [31:0]  addr,           // byte address from ALU
    output wire [31:0]  load_data_out   // final 32-bit data to regfile
);

        wire [31:0] MDR = mem_data_in;

       // Step 2: Byte selection
    
    wire [7:0] selected_byte = (addr[1:0] == 2'b00) ? MDR[7:0]   :
                               (addr[1:0] == 2'b01) ? MDR[15:8]  :
                               (addr[1:0] == 2'b10) ? MDR[23:16] :
                                                       MDR[31:24];

    // Step 3: Halfword selection
    
    wire [15:0] selected_half = (addr[1]) ? MDR[31:16] : MDR[15:0];

    //    // Step 4: Sign / Zero Extension
    
    wire [31:0] ext_byte = (funct3 == 3'b000) ? {{24{selected_byte[7]}}, selected_byte} : // LB
                           (funct3 == 3'b100) ? {24'b0, selected_byte}                  : // LBU
                                                32'b0;

    wire [31:0] ext_half = (funct3 == 3'b001) ? {{16{selected_half[15]}}, selected_half} : // LH
                           (funct3 == 3'b101) ? {16'b0, selected_half}                  : // LHU
                                                32'b0;

    assign load_data_out = (funct3 == 3'b010) ? MDR :               // LW
                           (funct3 == 3'b110) ? MDR :               // LWU (same as LW for RV32)
                           (funct3 == 3'b000 || funct3 == 3'b100) ? ext_byte :
                           (funct3 == 3'b001 || funct3 == 3'b101) ? ext_half :
                           32'b0;

endmodule





// testbench
module tb_load_datapath;

    // DUT ports
    reg  [2:0]  funct3;
    reg  [31:0] mem_data_in;
    reg  [31:0] addr;
    wire [31:0] load_data_out;

    // instantiate DUT (assumes load_datapath module in same directory)
    load_datapath DUT (
        .funct3(funct3),
        .mem_data_in(mem_data_in),
        .addr(addr),
        .load_data_out(load_data_out)
    );
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end

    initial begin
             // Test 1: LB (positive)
       
        mem_data_in = 32'h11223344;
        addr = 32'h00000000;      // addr[1:0]=10 -> selects byte2 = 0x22
        funct3 = 3'b000;          // LB (sign-extend)

        #5; // wait

        
        //Test 2: LB (negative sign extension) 
       
       	mem_data_in = 32'h11F23344; // byte2 = 0xF2 (MSB=1)
        addr = 32'h00000002;        // select byte2
        funct3 = 3'b000;            // LB
        #5;
       
	//test 3:
        mem_data_in = 32'h11F23344; // same word, byte2 = 0xF2 (but zero-extend)
        addr = 32'h00000002;
        funct3 = 3'b100;            // LBU
        #5;
        

        // Test 4: LH 
               
	mem_data_in = 32'hAABBCCDD;
        addr = 32'h00000000;      // addr[1]=0 -> selects lower half = 0xCCDD
        funct3 = 3'b001;          // LH (sign-extend)
        #5;


        
        // Test 5: LHU (zero-extend) 

	mem_data_in = 32'hAABBCCDD;
        addr = 32'h00000000;      // lower half
        funct3 = 3'b101;          // LHU
        #5;
        

        //  Test 6: LW (word)
        mem_data_in = 32'hDEADBEEF;
        addr = 32'h00000000;      // word-aligned
        funct3 = 3'b010;          // LW
        #5;
       
        

	//  Test 7: LWU (for RV32 same as LW) 
        mem_data_in = 32'hCAFEBABE;
        addr = 32'h00000000;
        funct3 = 3'b110;          // LWU (RV32: behaves same as LW)
        #5;


        // ---------- Test 8: Byte select edge cases ----------
        mem_data_in = 32'h01020304;  // bytes: 04,03,02,01
        // test all byte offsets for LB (zero-extend/ sign depends on byte)
        addr = 32'h00000000; funct3 = 3'b000; #2; $display("%8t |  LB b0| %h | %h | %h | %h", $time, addr, mem_data_in, 32'h00000004, load_data_out);
        addr = 32'h00000001; funct3 = 3'b000; #2; $display("%8t |  LB b1| %h | %h | %h | %h", $time, addr, mem_data_in, 32'h00000003, load_data_out);
        addr = 32'h00000002; funct3 = 3'b000; #2; $display("%8t |  LB b2| %h | %h | %h | %h", $time, addr, mem_data_in, 32'h00000002, load_data_out);
        addr = 32'h00000003; funct3 = 3'b000; #2; $display("%8t |  LB b3| %h | %h | %h | %h", $time, addr, mem_data_in, 32'h00000001, load_data_out);

                $finish;
    end

endmodule

