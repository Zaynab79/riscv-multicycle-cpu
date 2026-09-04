module controller (
    input wire clk_i,
    input wire rst_ni,

    // Current instruction
    input wire [31:0] instruction_i,

    // ipending
    input wire ipending_i,

    // Branch operation
    output reg branch_op_o,

    // Immediate value correctly extended
    output reg [31:0] imm_o,

    // Instruction Register control signals
    output reg ir_en_o,

    // PC control signals
    output reg pc_add_imm_o,
    output reg pc_en_o,
    output reg pc_sel_alu_o,
    output reg pc_sel_pc_base_o,

    // Register file control signals
    output reg rf_we_o,

    // Multiplexer control signals
    output reg sel_addr_o,
    output reg sel_b_o,
    output reg sel_mem_o,
    output reg sel_pc_o,
    output reg sel_imm_o,

    // Memory control signals
    output reg we_o,

    // ALU control signals
    output reg [5:0] alu_op_o,

    // CSR control signal
    output reg csr_write_o,
    output reg csr_set_o,
    output reg csr_clear_o,
    output reg csr_interrupt_o,
    output reg csr_mret_o,
    output reg sel_csr_o,
    output reg pc_sel_mtvec_o,
    output reg pc_sel_mepc_o

);

    // State definitions using parameters
    parameter [3:0] FETCH1  = 4'b0000;
    parameter [3:0] FETCH2  = 4'b0001;
    parameter [3:0] DECODE  = 4'b0010;
    parameter [3:0] R_TYPE  = 4'b0011;
    parameter [3:0] I_TYPE  = 4'b0100;
    parameter [3:0] U_TYPE  = 4'b0101;
    parameter [3:0] LOAD1   = 4'b0110;
    parameter [3:0] LOAD2   = 4'b0111;
    parameter [3:0] S_TYPE  = 4'b1000;
    parameter [3:0] BREAK   = 4'b1001;
    parameter [3:0] B_TYPE  = 4'b1010;
    parameter [3:0] J_TYPE  = 4'b1011;
    parameter [3:0] JALR    = 4'b1100;
    parameter [3:0] CSR     = 4'b1101;
    parameter [3:0] INTERRUPT_RETURN = 4'b1110;


    // State registers
    reg [3:0] curr_state;
    reg [3:0] next_state;

    always@(posedge clk_i) begin
        if (!rst_ni) begin
            curr_state <= FETCH1;
        end else begin
            curr_state <= next_state;
        end
    end

    always@(*) begin
        branch_op_o = 0;
        imm_o = 32'b0;
        ir_en_o = 0;

        pc_add_imm_o = 0;
        pc_en_o = 0;
        pc_sel_alu_o = 0;
        pc_sel_pc_base_o = 0;

        rf_we_o = 0;

        sel_addr_o = 0;
        sel_b_o = 0;
        sel_mem_o = 0;
        sel_pc_o = 0;
        sel_imm_o = 0;

        we_o = 0;

        pc_sel_mtvec_o    = 0;
        pc_sel_mepc_o     = 0;
        csr_write_o       = 0;
        csr_set_o         = 0;
        csr_clear_o       = 0;
        csr_interrupt_o  = 0;
        csr_mret_o        = 0;
        sel_csr_o = 0;

        case (curr_state)
            FETCH1: begin
                we_o = 0;
                next_state = FETCH2;
            end
            FETCH2: begin
                if (ipending_i) begin
                    csr_interrupt_o = 1;
                    pc_sel_mtvec_o  = 1;
                    pc_en_o         = 1;
                    next_state      = FETCH1;
                end else begin
                    pc_en_o = 1;
                    ir_en_o = 1;
                    next_state = DECODE;
                end
            end
            DECODE: begin
                case (instruction_i[6:0])
                    7'b0110011: next_state = R_TYPE;
                    7'b0010011: next_state = I_TYPE;
                    7'b0110111: next_state = U_TYPE;
                    7'b0000011: next_state = LOAD1;
                    7'b0100011: next_state = S_TYPE;
                    7'b1100011: next_state = B_TYPE;
                    7'b1101111: next_state = J_TYPE;
                    7'b1100111: next_state = JALR;
                    7'b1110011: begin
                        if (instruction_i[14:12] == 3'b000) begin
                            // Either EBREAK or MRET
                            if (instruction_i[31:20] == 12'h302) begin
                                // mret
                                next_state = INTERRUPT_RETURN;
                            end else begin
                                // ebreak
                                next_state = BREAK;
                            end
                        end else begin
                            // CSR instruction
                            next_state = CSR;
                        end
                    end
                    default: next_state = FETCH1;
                endcase
            end
            I_TYPE: begin
                rf_we_o = 1;
                sel_b_o = 0;
                imm_o = {{20{instruction_i[31]}}, instruction_i[31:20]};
                next_state = FETCH2;
            end
            R_TYPE: begin
                rf_we_o = 1;
                sel_b_o = 1;
                next_state = FETCH2;
            end
            U_TYPE: begin
                rf_we_o = 1;
                sel_imm_o = 1;
                imm_o = {instruction_i[31:12], 12'b0};
                next_state = FETCH2;
            end
            LOAD1: begin
                sel_addr_o = 1;
                we_o = 0;
                sel_b_o = 0;
                imm_o = {{20{instruction_i[31]}}, instruction_i[31:20]};
                next_state = LOAD2;
            end
            LOAD2: begin
                rf_we_o = 1;
                sel_addr_o = 1;
                sel_mem_o = 1;
                imm_o = {{20{instruction_i[31]}}, instruction_i[31:20]};
                next_state = FETCH1;
            end
            S_TYPE: begin
                we_o = 1;
                sel_addr_o = 1;
                imm_o = {{20{instruction_i[31]}}, instruction_i[31:25], instruction_i[11:7]};
                next_state = FETCH1;
            end
            BREAK: begin
                next_state = BREAK;
            end
            B_TYPE: begin
                branch_op_o = 1;
                sel_b_o = 1;
                pc_sel_pc_base_o = 1;
                pc_add_imm_o = 1;
                imm_o = {{20{instruction_i[31]}},
                    instruction_i[7],
                    instruction_i[30:25],
                    instruction_i[11:8],
                    1'b0};
                next_state = FETCH1;
            end
            J_TYPE: begin
                rf_we_o = 1;
                pc_en_o = 1;
                pc_sel_pc_base_o = 1;
                pc_add_imm_o = 1;
                sel_pc_o = 1;
                imm_o = {{12{instruction_i[31]}},
                    instruction_i[19:12],
                    instruction_i[20],
                    instruction_i[30:21],
                    1'b0};
                next_state = FETCH1;
            end
            JALR: begin
                rf_we_o = 1;
                pc_en_o = 1;
                pc_sel_alu_o = 1;
                sel_pc_o = 1;
                imm_o = {{20{instruction_i[31]}}, instruction_i[31:20]};
                next_state = FETCH1;
            end
            CSR: begin
                sel_csr_o = 1;
                rf_we_o   = 1;

                case (instruction_i[14:12])
                    3'b001: csr_write_o = 1; // csrrw
                    3'b010: csr_set_o   = 1; // csrrs
                    3'b011: csr_clear_o = 1; // csrrc
                    3'b101: csr_write_o = 1; // csrrwi
                    3'b110: csr_set_o   = 1; // csrrsi
                    3'b111: csr_clear_o = 1; // csrrci
                    default: ;
                endcase

                // Immediate CSR
                if (instruction_i[14:12] >= 3'b101) begin
                    sel_imm_o = 1;
                    imm_o     = {27'b0, instruction_i[19:15]};
                end

                next_state = FETCH2;
            end
            INTERRUPT_RETURN: begin
                csr_mret_o    = 1;
                pc_sel_mepc_o = 1;
                pc_en_o       = 1;
                next_state    = FETCH1;
            end

            default: next_state = FETCH1;
        endcase
    end

    // ALU operation generation with branches
    always @(*) begin
        alu_op_o = 6'b0;
        case (instruction_i[6:0])
            // R-type instructions
            7'b0110011: begin
                case ({instruction_i[31:25], instruction_i[14:12]})  // {funct7, funct3}
                    {7'b0000000, 3'b000}: alu_op_o = 6'b000000; // ADD
                    {7'b0100000, 3'b000}: alu_op_o = 6'b001000; // SUB
                    {7'b0000000, 3'b100}: alu_op_o = 6'b100100; // XOR
                    {7'b0000000, 3'b110}: alu_op_o = 6'b100110; // OR
                    {7'b0000000, 3'b111}: alu_op_o = 6'b100111; // AND
                    {7'b0000000, 3'b010}: alu_op_o = 6'b011100; // SLT
                    {7'b0000000, 3'b011}: alu_op_o = 6'b011110; // SLTU
                    {7'b0000000, 3'b001}: alu_op_o = 6'b110001; // SLL
                    {7'b0000000, 3'b101}: alu_op_o = 6'b110101; // SRL
                    {7'b0100000, 3'b101}: alu_op_o = 6'b111101; // SRA
                    default: alu_op_o = 6'b000000;
                endcase
            end

            // I-type instructions
            7'b0010011: begin
                case (instruction_i[14:12])  // funct3
                    3'b000: alu_op_o = 6'b000000; // ADDI
                    3'b100: alu_op_o = 6'b100100; // XOR
                    3'b110: alu_op_o = 6'b100110; // OR
                    3'b111: alu_op_o = 6'b100111; // AND
                    3'b010: alu_op_o = 6'b011100; // SLT
                    3'b011: alu_op_o = 6'b011110; // SLTU
                    3'b001: alu_op_o = 6'b110001; // SLL
                    3'b101: begin
                        alu_op_o = (instruction_i[31:25]==7'b0100000) ? 6'b111101 : 6'b110101;
                    end
                    default: alu_op_o = 6'b000000;
                endcase
            end

            // B-typr instructions
            7'b1100011: begin
                case (instruction_i[14:12])  // funct3
                    3'b000: alu_op_o = 6'b011000; // BEQ
                    3'b001: alu_op_o = 6'b011001; // BNE
                    3'b100: alu_op_o = 6'b011100; // BLT
                    3'b101: alu_op_o = 6'b011101; // BGE
                    3'b110: alu_op_o = 6'b011110; // BLTU
                    3'b111: alu_op_o = 6'b011111; // BGEU
                    default: alu_op_o = 6'b000000;
                endcase
            end

            // Default for other instructions
            default: alu_op_o = 6'b000000;

        endcase
    end
endmodule
