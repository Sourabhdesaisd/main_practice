module sequential_unit (
    input  [31:0] pc_current,
    output [31:0] pc_next_seq
);

    assign pc_next_seq = pc_current + 32'd4;

endmodule
