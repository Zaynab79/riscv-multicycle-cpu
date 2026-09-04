
module csr (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire [11:0] addr_i,
    input  wire [31:0] wdata_i,
    input  wire        irq_i,
    input  wire [31:0] pc_i,
    input  wire        write_i,
    input  wire        set_i,
    input  wire        clear_i,
    input  wire        interrupt_i,
    input  wire        mret_i,
    output wire [31:0] rdata_o,
    output wire [31:0] mtvec_o,
    output wire [31:0] mepc_o,
    output wire        ipending_o
);

  //! Don't change the following definition.
  //! Should be used for storing the CSR registers values as
  //! described in the assignment.
  reg [31:0] mstatus_r, mie_r, mtvec_r, mepc_r, mcause_r, mip_r;

  localparam MIE_BIT = 3;
  localparam MPIE_BIT = 7;
  localparam MBIP_BIT = 11;

  localparam [31:0] MASK_MSTATUS = 32'h00001888;
  localparam [31:0] MASK_MIE     = 32'h00000800;
  localparam [31:0] MASK_MTVEC   = 32'hFFFFFFFF;
  localparam [31:0] MASK_MEPC    = 32'hFFFFFFFF;
  localparam [31:0] MASK_MCAUSE  = 32'h80000800;
  localparam [31:0] MASK_MIP     = 32'h00000800;

  // Output assignments
  assign mtvec_o = mtvec_r;
  assign mepc_o = mepc_r;
  assign ipending_o = mip_r[MBIP_BIT] & mstatus_r[MIE_BIT] & mie_r[11];

  // Read
  assign rdata_o = (addr_i == 12'h300)  ? mstatus_r :
                   (addr_i == 12'h304)  ? mie_r :
                   (addr_i == 12'h305)  ? mtvec_r :
                   (addr_i == 12'h341)  ? mepc_r :
                   (addr_i == 12'h342)  ? mcause_r :
                   (addr_i == 12'h344)  ? mip_r :
                   32'b0;

  always @(posedge clk_i) begin
    // reset
    if (!rst_ni) begin
      mstatus_r <= 32'h1800;
      mie_r <= 32'b0;
      mtvec_r <= 32'b0;
      mepc_r <= 32'b0;
      mcause_r <= 32'b0;
      mip_r <= 32'b0;
    end else begin

      // interrupt request handling
      if (irq_i) begin
        mip_r[MBIP_BIT] <= 1'b1;
      end else begin
        mip_r[MBIP_BIT] <= 1'b0;
      end

      // interrupt processing
      if (interrupt_i) begin
        mepc_r <= pc_i;
        mcause_r <= {1'b1, 19'b0, 1'b1, 11'b0};
        mstatus_r[MPIE_BIT] <= mstatus_r[MIE_BIT];
        mstatus_r[MIE_BIT] <= 1'b0;
      end

      // mret
      if (mret_i) begin
        mstatus_r[MIE_BIT] <= mstatus_r[MPIE_BIT];
        mstatus_r[MPIE_BIT] <= 1'b1;
      end

      //write
      if (write_i) begin
        case (addr_i)
          12'h300: mstatus_r <= (wdata_i & MASK_MSTATUS);
          12'h304: mie_r <= (wdata_i & MASK_MIE);
          12'h305: mtvec_r <= (wdata_i & MASK_MTVEC);
          12'h341: mepc_r <= (wdata_i & MASK_MEPC);
          12'h342: mcause_r <= (wdata_i & MASK_MCAUSE);
          12'h344: mip_r <= (wdata_i & MASK_MIP);
          default: ;
        endcase
      end

      //set
      else if (set_i) begin
        case (addr_i)
          12'h300: mstatus_r <= mstatus_r | (wdata_i & MASK_MSTATUS);
          12'h304: mie_r <= mie_r | (wdata_i & MASK_MIE);
          12'h305: mtvec_r <= mtvec_r | (wdata_i & MASK_MTVEC);
          12'h341: mepc_r <= mepc_r | (wdata_i & MASK_MEPC);
          12'h342: mcause_r <= mcause_r | (wdata_i & MASK_MCAUSE);
          12'h344: mip_r <= mip_r | (wdata_i & MASK_MIP);
          default: ;
        endcase
      end

      //clear
      else if (clear_i) begin
        case (addr_i)
          12'h300: mstatus_r <= mstatus_r & ~(wdata_i & MASK_MSTATUS);
          12'h304: mie_r <= mie_r & ~(wdata_i & MASK_MIE);
          12'h305: mtvec_r <= mtvec_r & ~(wdata_i & MASK_MTVEC);
          12'h341: mepc_r <= mepc_r & ~(wdata_i & MASK_MEPC);
          12'h342: mcause_r <= mcause_r & ~(wdata_i & MASK_MCAUSE);
          12'h344: mip_r <= mip_r & ~(wdata_i & MASK_MIP);
          default: ;
        endcase
      end
    end
  end

endmodule
