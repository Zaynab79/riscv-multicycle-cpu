module seven_seg_lcd (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        en_i,
    input  wire        we_i,
    input  wire [31:0] waddr_i,
    input  wire [31:0] wdata_i,
    output wire [31:0] disp_o
);
    reg [31:0] disp_reg;

    // Synchronous reset and write
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            disp_reg <= 32'h00000000;
        end else if (waddr_i == 32'h60000000 && en_i && we_i) begin
            disp_reg <= wdata_i;
        end
    end

    assign disp_o = disp_reg;

endmodule
