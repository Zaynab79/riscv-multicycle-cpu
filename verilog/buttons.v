module buttons (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        en_i,
    input  wire        we_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] wdata_i,
    input  wire [ 9:0] push_i,
    input  wire [ 7:0] switch_i,
    output wire [31:0] rdata_o,
    output wire        irq_o
);

    // ========== INTERNAL REGISTERS ==========
    reg [31:0] src, ptm, stm;
    reg [ 9:0] prev_push;
    reg [ 7:0] prev_switch;
    reg [31:0] captured_data;

    reg [1:0] mode_btn;
    reg curr_btn, prev_btn, rising_btn, falling_btn, high_btn, low_btn, cond_btn;

    reg [1:0] mode_sw;
    reg curr_sw, prev_sw, rising_sw, falling_sw, high_sw, low_sw, cond_sw;

    // ========== RESET AND WRITE LOGIC ==========
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            src <= 32'h0;
            ptm <= 32'hFFFFF;
            stm <= 32'hFFFF;
            prev_push <= 10'h0;
            prev_switch <= 8'h0;
        end else begin
            // store prev states
            prev_push <= push_i;
            prev_switch <= switch_i;

            // write to regs
            if (en_i && we_i) begin
                case (addr_i[3:0])
                    4'h4: src <= wdata_i;
                    4'h8: ptm <= wdata_i;
                    4'hc: stm <= wdata_i;
                    default: ;
                endcase
            end

            // Buttons interrupt
            for (integer i = 0; i < 10; i = i+1) begin
                mode_btn   = ptm[2*i +: 2];
                curr_btn   = push_i[i];
                prev_btn   = prev_push[i];

                rising_btn  = (~prev_btn) & curr_btn;
                falling_btn = prev_btn & (~curr_btn);
                high_btn    = curr_btn;
                low_btn     = ~curr_btn;

                case (mode_btn)
                    2'b00: cond_btn = low_btn;
                    2'b01: cond_btn = rising_btn;
                    2'b10: cond_btn = falling_btn;
                    2'b11: cond_btn = high_btn;
                    default: cond_btn = high_btn;
                endcase

                if (cond_btn) src[i] <= 1'b1;
            end

            // Switch interrupt
            for (integer i = 0; i < 8; i = i+1) begin
                mode_sw   = stm[2*i +: 2];
                curr_sw   = switch_i[i];
                prev_sw   = prev_switch[i];

                rising_sw  = (~prev_sw) & curr_sw;
                falling_sw = prev_sw & (~curr_sw);
                high_sw    = curr_sw;
                low_sw     = ~curr_sw;

                case (mode_sw)
                    2'b00: cond_sw = low_sw;
                    2'b01: cond_sw = rising_sw;
                    2'b10: cond_sw = falling_sw;
                    2'b11: cond_sw = high_sw;
                    default: cond_sw = high_sw;
                endcase

                if (cond_sw) src[16+i] <= 1'b1;
            end
        end
    end

    // ========== READ LOGIC ==========
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            captured_data <= 32'h0;
        end else if (en_i) begin
            case (addr_i[3:0])
                4'h0: captured_data <= {8'h0, switch_i, 6'h0, push_i};
                4'h4: captured_data <= src;   // src
                default: captured_data <= 32'h0;
            endcase
        end
    end
    assign rdata_o = captured_data;
    assign irq_o = (src != 32'h0);

endmodule
