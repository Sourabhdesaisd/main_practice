module pc_reg (
    input         clk,
    input         reset,        // active-high reset
    input  [31:0] pc_next,      // next PC from PC update logic
    output reg [31:0] pc_current   // current PC
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_current <= 32'd0;     // PC starts at 0 (can change to 4 or any start addr)
        else
            pc_current <= pc_next;   // update PC each cycle
    end

endmodule

