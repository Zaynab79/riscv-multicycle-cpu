`timescale 1ns / 1ps

module tb_add_sub ();
    // Inputs
    reg [31:0] a_i, b_i;
    reg        sub_i;

    // Outputs
    wire [31:0] r_o;
    wire        carry_o;
    wire        zero_o;

    // Instantiate the Unit Under Test (UUT)
    add_sub uut (
        .a_i    (a_i),
        .b_i    (b_i),
        .sub_i  (sub_i),
        .carry_o(carry_o),
        .zero_o (zero_o),
        .r_o    (r_o)
    );

    initial begin
        // Generate waveform file
        $dumpfile("dump/tb_add_sub.vcd");
        $dumpvars(0, tb_add_sub);

        // Test 1: Addition
        a_i = 32'h00000005; b_i = 32'h00000003; sub_i = 1'b0;
        #20;
        if (r_o !== 32'h00000008 || carry_o !== 1'b0 || zero_o !== 1'b0) begin
            $display("Error: Addition failed");
            $display("Expected: r=8, carry=0, zero=0");
            $display("Got: r=%h, carry=%b, zero=%b", r_o, carry_o, zero_o);
        end else begin
            $display("Addition test passed");
        end

        // Test 1: Addition with carry
        a_i = 32'hFFFFFFFF; b_i = 32'h00000001; sub_i = 1'b0;
        #20;
        if (r_o !== 32'h00000000 || carry_o !== 1'b1 || zero_o !== 1'b1) begin
            $display("Error: Addition with carry failed");
            $display("Expected: r=0, carry=1, zero=1");
            $display("Got: r=%h, carry=%b, zero=%b", r_o, carry_o, zero_o);
        end else begin
            $display("Addition test passed");
        end

        // Test 2: Subtraction (A - B)
        a_i = 32'h00000008; b_i = 32'h00000003; sub_i = 1'b1;
        #20;
        if (r_o !== 32'h00000005 || carry_o !== 1'b0 || zero_o !== 1'b1) begin
            $display("Error: Subtraction failed");
            $display("Expected: r=5, carry=0, zero=0");
            $display("Got: r=%h, carry=%b, zero=%b", r_o, carry_o, zero_o);
        end else begin
            $display("Subtraction test passed");
        end

        // Test 3: Subtraction zero
        a_i = 32'h00000003; b_i = 32'h00000003; sub_i = 1'b1;
        #20;
        if (r_o !== 32'h00000000 || carry_o !== 1'b1 || zero_o !== 1'b1) begin
            $display("Error: subtraction zero failed");
            $display("Expected: r=0, carry=1, zero=1");
            $display("Got: r=%h, carry=%b, zero=%b", r_o, carry_o, zero_o);
        end else begin
            $display("Negative subtraction test passed");
        end

        // Test 5: Subtraction with negative results
        a_i = 32'h00000003; b_i = 32'h00000005; sub_i = 1'b1;
        #20;
        if (r_o !== 32'hFFFFFFFE|| carry_o !== 1'b1 || zero_o !== 1'b0) begin
            $display("Error: Carry out test failed");
            $display("Expected: r=-2, carry=1, zero=0");
            $display("Got: r=%h, carry=%b, zero=%b", r_o, carry_o, zero_o);
        end else begin
            $display("Carry out test passed");
        end

        $finish;
    end
endmodule