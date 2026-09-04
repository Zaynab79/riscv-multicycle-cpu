module pc (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        en_i,
    input  wire        sel_alu_i,
    input  wire        sel_pc_base_i,
    input  wire        sel_mtvec_i,
    input  wire        sel_mepc_i,
    input  wire        add_imm_i,
    input  wire [31:0] imm_i,
    input  wire [31:0] alu_i,
    input  wire [31:0] mtvec_i,
    input  wire [31:0] mepc_i,
    output wire [31:0] addr_o
);

  /////////////////////
  // Internal Registers
  /////////////////////
  //! Do not rename the pc_reg signal
  //! Use it to store the current PC value
  reg [31:0] pc_reg;

  always@(posedge clk_i) begin
    if(!rst_ni) begin
      pc_reg <= 32'h80000000;
    end

    else if (en_i) begin
      if (sel_alu_i) begin
        pc_reg <= alu_i;
      end
      else if (add_imm_i) begin
        if (sel_pc_base_i) begin
          pc_reg <= pc_reg - 32'h00000004 + imm_i;
        end
        else begin
          pc_reg <= pc_reg + imm_i;
        end
      end
      else if (sel_mtvec_i) begin
        pc_reg <= mtvec_i;
      end
      else if (sel_mepc_i) begin
        pc_reg <= mepc_i;
      end
      else begin
        pc_reg <= pc_reg + 32'h00000004;
      end
    end
  end

  assign addr_o = pc_reg & 32'hFFFFFFFC;

endmodule
