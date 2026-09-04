module add_sub (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire        sub_i,
    output wire        carry_o,
    output wire        zero_o,
    output wire [31:0] r_o
);

wire carry_i = sub_i;
wire [32:0] extended_a = {1'b0, a_i};
wire [32:0] extended_b = {1'b0, b_i};
wire [32:0] inverted_b = extended_b ^ {1'b0, {32{sub_i}}};
wire [32:0] result = extended_a + inverted_b + carry_i;

assign r_o = result[31:0];
assign carry_o = result[32];
assign zero_o = (r_o == 0);

endmodule
