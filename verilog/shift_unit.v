module shift_unit (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire [ 2:0] op_i,
    input  wire        arithmetic_i,
    output wire [31:0] r_o
);

wire [4:0] shift_amount = b_i[4:0];

// For arithmetic right shift, we need to handle sign extension manually
wire [31:0] arithmetic_shift_right;
assign arithmetic_shift_right = ($signed(a_i)) >>> shift_amount;

assign r_o = ((op_i == 3'b001) ? a_i << shift_amount :
             (op_i == 3'b101 && ~arithmetic_i) ? a_i >> shift_amount :
             (op_i == 3'b101 && arithmetic_i) ? arithmetic_shift_right :
             32'b0);
endmodule
