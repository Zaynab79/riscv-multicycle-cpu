module mem #(
    parameter B = 32'hA0000000
) (
    input  wire        clk_i,
    input  wire        en_i,
    input  wire        we_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] wdata_i,
    output wire [31:0] rdata_o
);

  //////////////////////
  // Constants
  //////////////////////
  localparam BASE_ADDR = 32'h80000000;

  //////////////////////
  // Memory Array
  //////////////////////
  reg [31:0] mem_r[(B - BASE_ADDR) >> 2];

  reg [31:0] rdata_r;

  // Write Process:
  always @(posedge clk_i) begin
    if (en_i && we_i) begin
      mem_r[(addr_i - BASE_ADDR) >> 2] <= wdata_i;
    end
  end

  // Read output: synchronous 1-cycle latency
  always @(posedge clk_i) begin
    if (en_i && !we_i) begin
      rdata_r <= mem_r[(addr_i - BASE_ADDR) >> 2];
    end else begin
      rdata_r <= 32'h0;
    end
  end

  assign rdata_o = rdata_r;

  //TODO Implement the memory module here

  //! Don't touch the code below this line
  //////////////////////
  // DPI-C Functions
  //////////////////////
  export "DPI-C" function mem_init;
  export "DPI-C" function mem_rd;
  export "DPI-C" function mem_wr;

  int read_file_descriptor;

  function void mem_init(input string file);
    read_file_descriptor = $fopen(file, "rb");
    $fread(mem_r, read_file_descriptor);
    $fclose(read_file_descriptor);
    // Fix the endianness of the memory
    for (int i = 0; i < (B - BASE_ADDR) >> 2; i = i + 1) begin
      mem_r[i] = {mem_r[i][7:0], mem_r[i][15:8], mem_r[i][23:16], mem_r[i][31:24]};
    end
  endfunction

  function int unsigned mem_rd(input int unsigned address);
    return mem_r[(address-BASE_ADDR)>>2];
  endfunction

  function void mem_wr(input int unsigned address, input int unsigned data,
                       input int unsigned strb);
    mem_r[(address-BASE_ADDR)>>2] <= data;
  endfunction

endmodule
