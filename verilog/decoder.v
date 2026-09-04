module decoder (
    input  wire [31:0] addr_i,
    output wire        en_ram_o,
    output wire        en_leds_o,
    output wire        en_7_seg_lcd_o,
    output wire        en_buttons_o
);

    // LEDs
    assign en_leds_o = (addr_i >= 32'h50000000 && addr_i <= 32'h50000FFF);

    // 7-Segment LCD
    assign en_7_seg_lcd_o = (addr_i >= 32'h60000000 && addr_i <= 32'h60000FFF);

    // Button
    assign en_buttons_o = (addr_i >= 32'h70000000 && addr_i <= 32'h70000FFF);

    // RAM
    assign en_ram_o = (addr_i >= 32'h80000000 && addr_i <= 32'h9FFFFFFF);

endmodule
