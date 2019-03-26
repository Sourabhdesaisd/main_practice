module ripple_carry_adder32 (
    input  [31:0] a,
    input  [31:0] b,
    input         cin,             // carry-in (0=ADD, 1=SUB)
    output [31:0] sum,
    output        carry_flag,      // CARRY FLAG (unsigned overflow)
    output        zero_flag,       // Result is zero
    output        negative_flag,   // MSB of result
    output        overflow_flag    // Signed overflow flag
);

    reg [32:0] c;      // Carry chain (c[0] to c[32])
    reg [31:0] s;      // Sum bits
    integer i;

    always @(*) begin
        c[0] = cin;    // starting carry

        // RIPPLE CARRY ADDER
        for (i = 0; i < 32; i = i + 1) begin
            // SUM
            s[i]   = a[i] ^ b[i] ^ c[i];

            // CARRY
            c[i+1] = (a[i] & b[i]) |
                     (a[i] & c[i]) |
                     (b[i] & c[i]);
        end
    end

    // Final SUM
    assign sum = s;

    // ? CARRY FLAG IS HERE
    assign carry_flag = c[32];

    // ZERO FLAG
    assign zero_flag = (sum == 32'd0);

    // NEGATIVE FLAG
    assign negative_flag = sum[31];

    // SIGNED OVERFLOW FLAG
    assign overflow_flag = (a[31] == b[31]) && (sum[31] != a[31]);

endmodule




//`timescale 1ns/1ps

module tb_ripple_carry_adder32;

    reg  [31:0] a, b;
    reg         cin;
    wire [31:0] sum;
    wire        carry_flag;
    wire        zero_flag;
    wire        negative_flag;
    wire        overflow_flag;

    // DUT
    ripple_carry_adder32 dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .carry_flag(carry_flag),
        .zero_flag(zero_flag),
        .negative_flag(negative_flag),
        .overflow_flag(overflow_flag)
    );

initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end



    initial begin
        $display("=== Ripple Carry Adder Testbench ===");

        // ----------------------------------------
        // Test 1: Unsigned Carry
        // ----------------------------------------
        a   = 32'hFFFF_FFFF;
        b   = 32'h0000_0001;
        cin = 0;
        #1;
        $display("T1: a=%h b=%h cin=%b | sum=%h c=%b z=%b n=%b ov=%b",
                 a, b, cin, sum, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ----------------------------------------
        // Test 2: Normal Addition
        // ----------------------------------------
        a   = 32'd25;
        b   = 32'd17;
        cin = 0;
        #1;
        $display("T2: a=%h b=%h cin=%b | sum=%h c=%b z=%b n=%b ov=%b",
                 a, b, cin, sum, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ----------------------------------------
        // Test 3: Zero Flag (55 - 55 = 0)
        // ----------------------------------------
        a   = 32'd55;
        b   = ~32'd55;
        cin = 1;   // a + (~b) + 1 = a - b
        #1;
        $display("T3: a=%h b=%h cin=%b | sum=%h c=%b z=%b n=%b ov=%b",
                 a, b, cin, sum, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ----------------------------------------
        // Test 4: Negative Result
        // ----------------------------------------
        a   = -32'd10;
        b   =  32'd3;
        cin = 0;
        #1;
        $display("T4: a=%h b=%h cin=%b | sum=%h c=%b z=%b n=%b ov=%b",
                 a, b, cin, sum, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ----------------------------------------
        // Test 5: Signed Overflow (+ + = -)
        // ----------------------------------------
        a   = 32'd2147483600;   // large positive
        b   = 32'd200;          // positive
        cin = 0;
        #1;
        $display("T5: a=%h b=%h cin=%b | sum=%h c=%b z=%b n=%b ov=%b",
                 a, b, cin, sum, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ----------------------------------------
        // Test 6: Signed Overflow (- - = +)
        // ----------------------------------------
        a   = -32'd2147483600;
        b   = -32'd200;
        cin = 0;
        #1;
        $display("T6: a=%h b=%h cin=%b | sum=%h c=%b z=%b n=%b ov=%b",
                 a, b, cin, sum, carry_flag, zero_flag, negative_flag, overflow_flag);

        // ----------------------------------------
        // Test 7: Subtraction (100 - 40)
        // ----------------------------------------
        a   = 32'd100;
        b   = ~32'd40;   // invert for subtraction
        cin = 1;
        #1;
        $display("T7: a=%h b=%h cin=%b | sum=%h c=%b z=%b n=%b ov=%b",
                 a, b, cin, sum, carry_flag, zero_flag, negative_flag, overflow_flag);

        $display("=== TEST COMPLETE ===");
        $finish;
    end

endmodule


