module mux2x32 (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire        sel_i,
    output reg  [31:0] o_o
);

assign o_o = (sel_i == 0) ? a_i : b_i;

endmodule
