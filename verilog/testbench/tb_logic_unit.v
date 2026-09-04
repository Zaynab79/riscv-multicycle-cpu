`timescale 1ns / 1ps

module tb_logic_unit ();
    // Inputs
    reg [31:0] a_i, b_i;
    reg [2:0]  op_i;

    // Outputs
    wire [31:0] r_o;

    // Instantiate the Unit Under Test (UUT)
    logic_unit uut (
        .a_i  (a_i),
        .b_i  (b_i),
        .op_i (op_i),
        .r_o  (r_o)
    );

    // Operation codes (matching the logic_unit module)
    localparam XOR = 3'b100;
    localparam OR  = 3'b110;
    localparam AND = 3'b111;

    initial begin
        // Generate waveform file
        $dumpfile("dump/tb_logic_unit.vcd");
        $dumpvars(0, tb_logic_unit);

        // Test XOR operation
        a_i = 32'hAAAAAAAA; b_i = 32'h55555555; op_i = XOR;
        #20; // wait for circuit to settle
        if (r_o !== 32'hFFFFFFFF) begin
        $display("Error: XOR operation failed");
        $display("Expected: 32'hFFFFFFFF, Got: %h", r_o);
        end else begin
        $display("XOR operation passed");
        end

        // Test OR operation
        a_i = 32'h00FF00FF; b_i = 32'hFF00FF00; op_i = OR;
        #20;
        if (r_o !== 32'hFFFFFFFF) begin
            $display("Error: OR operation failed");
            $display("Expected: 32'hFFFFFFFF, Got: %h", r_o);
        end else begin
            $display("OR operation passed");
        end

        // Test AND operation
        a_i = 32'hFFFFFFFF; b_i = 32'hFFFF0000; op_i = AND;
        #20;
        if (r_o !== 32'hFFFF0000) begin
            $display("Error: AND operation failed");
            $display("Expected: 32'hFFFF0000, Got: %h", r_o);
        end else begin
            $display("AND operation passed");
        end

         // Test undefined operation (should default to all zeros)
        a_i = 32'h12345678; b_i = 32'h87654321; op_i = 3'b000;
        #20;
        if (r_o !== 32'b0) begin
            $display("Error: Default operation failed");
            $display("Expected: 32'b0, Got: %h", r_o);
        end else begin
            $display("Default operation passed");
        end

        // Finish simulation
        $finish;
    end
endmodule