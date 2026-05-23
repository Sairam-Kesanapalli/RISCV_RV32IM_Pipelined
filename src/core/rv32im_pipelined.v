/*********************************************************************************
 * RV32IM 5-STAGE PIPELINED PROCESSOR
 * -------------------------------------------------------------------------------
 * This is the pipelined core, refactored from the multi-cycle design into a
 * classic 5-stage pipeline: Fetch (IF), Decode (ID), Execute (EX), Memory (MEM),
 * and Write-Back (WB).
 *********************************************************************************/
module rv32im_pipelined #(
    parameter XLEN = 32
)(
    input clk,
    input rst_n
);

    // =========================================================================
    // PIPELINE REGISTER AND WIRE DECLARATIONS (Declared at top for safe scoping)
    // =========================================================================
    
    // Forward declarations of critical signals for safe scoping
    wire take_branch_or_jump;
    wire [XLEN-1:0] wb_write_data;
    wire [6:0] opcode;
    wire [4:0] rs1;
    wire [4:0] rs2;

    // IF/ID Pipeline Register
    reg [XLEN-1:0] if_id_pc;
    reg [XLEN-1:0] if_id_instr;

    // ID/EX Pipeline Register
    reg [XLEN-1:0] id_ex_pc;
    reg [XLEN-1:0] id_ex_read_data1;
    reg [XLEN-1:0] id_ex_read_data2;
    reg [XLEN-1:0] id_ex_imm;
    reg [6:0]      id_ex_funct7;
    reg [4:0]      id_ex_rs1;
    reg [4:0]      id_ex_rs2;
    reg [4:0]      id_ex_rd;
    reg [2:0]      id_ex_funct3;
    reg [2:0]      id_ex_ALU_OP;
    reg [1:0]      id_ex_ALUSrcA_ctrl;
    reg [1:0]      id_ex_ALUSrcB_ctrl;  
    reg            id_ex_RegWrite;
    reg            id_ex_MemRead;
    reg            id_ex_MemWrite;
    reg            id_ex_MemToReg;
    reg            id_ex_Branch;
    reg            id_ex_Jump;

    // EX/MEM Pipeline Register
    reg [XLEN-1:0] ex_mem_alu_result;
    reg [XLEN-1:0] ex_mem_write_data;
    reg [4:0]      ex_mem_rd;
    reg            ex_mem_MemRead;
    reg            ex_mem_MemWrite;
    reg            ex_mem_MemToReg;
    reg            ex_mem_RegWrite;

    // MEM/WB Pipeline Register
    reg [XLEN-1:0] mem_wb_read_data;
    reg [XLEN-1:0] mem_wb_alu_result;
    reg [4:0]      mem_wb_rd;
    reg            mem_wb_MemToReg;
    reg            mem_wb_RegWrite;

    // =========================================================================
    // HAZARD DETECTION & FORWARDING UNIT
    // =========================================================================
    wire is_mul_div;
    wire done;
    wire stall = is_mul_div & ~done;

    // Load-use stall detection
    wire load_use_stall = id_ex_MemRead && (id_ex_rd != 0) &&
                          ((id_ex_rd == rs1) || (id_ex_rd == rs2));
    wire pipeline_stall = stall | load_use_stall;
    wire flush = take_branch_or_jump;

    // Forwarding logic to resolve data hazards
    reg [1:0] forwardA;
    reg [1:0] forwardB;
    wire [XLEN-1:0] forwarded_read_data1;
    wire [XLEN-1:0] forwarded_read_data2;

    always @(*) begin
        if (ex_mem_RegWrite && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1))
            forwardA = 2'b10;
        else if (mem_wb_RegWrite && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs1))
            forwardA = 2'b01;
        else
            forwardA = 2'b00;
    end

    always @(*) begin
        if (ex_mem_RegWrite && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2))
            forwardB = 2'b10;
        else if (mem_wb_RegWrite && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs2))
            forwardB = 2'b01;
        else
            forwardB = 2'b00;
    end

    assign forwarded_read_data1 =
        (forwardA == 2'b10) ? ex_mem_alu_result :
        (forwardA == 2'b01) ? wb_write_data :
        id_ex_read_data1;

    assign forwarded_read_data2 =
        (forwardB == 2'b10) ? ex_mem_alu_result :
        (forwardB == 2'b01) ? wb_write_data :
        id_ex_read_data2;

    // Helper register to prevent start from asserting continuously during stall
    reg ex_stage_md_active;
    always @(posedge clk) begin
        if (!rst_n)
            ex_stage_md_active <= 1'b0;
        else if (is_mul_div & ~done)
            ex_stage_md_active <= 1'b1;
        else
            ex_stage_md_active <= 1'b0;
    end
    wire start = is_mul_div & ~ex_stage_md_active;

    // =========================================================================
    // 1. INSTRUCTION FETCH (IF) STAGE
    // =========================================================================
    reg [XLEN-1:0] PC;
    wire [XLEN-1:0] PC_next;
    wire [XLEN-1:0] PC_plus_4 = PC + 4;
    wire [XLEN-1:0] mem_instr;

    instruction_memory imem(
        .addr(PC),
        .instr(mem_instr)
    );

    // End-of-program detection: freeze PC when reading uninitialized instruction memory (32'hx)
    // to match the golden model's halt behavior.
    wire halt = (mem_instr === 32'hxxxxxxxx);

    // Update the PC sequentially on every clock edge, subject to stall and halt
    always @(posedge clk) begin
        if (!rst_n)
            PC <= 0;
        else if (!pipeline_stall && !halt)
            PC <= PC_next;
    end

    // IF/ID Pipeline Register sequential update with stall and flush (control hazards)
    always @(posedge clk) begin
        if (!rst_n) begin
            if_id_pc    <= 0;
            if_id_instr <= 32'h00000013; // NOP (addi x0, x0, 0)
        end else if (flush) begin
            if_id_pc    <= 0;
            if_id_instr <= 32'h00000013; // NOP (addi x0, x0, 0)
        end else if (!pipeline_stall) begin
            if_id_pc    <= PC;
            if_id_instr <= mem_instr;
        end
    end

    // =========================================================================
    // 2. INSTRUCTION DECODE (ID) STAGE
    // =========================================================================
    assign opcode       = if_id_instr[6:0];
    wire [4:0] rd       = if_id_instr[11:7];      // Destination register
    wire [2:0] funct3   = if_id_instr[14:12];     // Function identifier
    assign rs1          = if_id_instr[19:15];     // Source register 1
    assign rs2          = if_id_instr[24:20];     // Source register 2
    wire [6:0] funct7   = if_id_instr[31:25];     // Secondary function identifier

    // Control Unit outputs
    wire [1:0] ALUSrcA_ctrl;
    wire [1:0] ALUSrcB_ctrl;
    wire [2:0] ALU_OP;
    wire MemRead, MemWrite, Branch, Jump, RegWrite, MemToReg;

    control_unit cu(
        .op_code(opcode),
        .ALUSrcA_ctrl(ALUSrcA_ctrl),
        .ALUSrcB_ctrl(ALUSrcB_ctrl),
        .ALU_OP(ALU_OP),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .Jump(Jump),
        .RegWrite(RegWrite),
        .MemToReg(MemToReg)
    );

    // Register File outputs and write-back interface
    wire [XLEN-1:0] read_data1;
    wire [XLEN-1:0] read_data2;

    register_file rf(
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(mem_wb_RegWrite),
        .rd(mem_wb_rd),
        .write_data(wb_write_data),
        .rs1(rs1),
        .rs2(rs2),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Sign-extend immediate generator
    wire [XLEN-1:0] imm_out;
    imm_gen ig (
        .instr(if_id_instr),
        .imm_out(imm_out)
    );

    // ID/EX Pipeline Register sequential update with stall and flush (control hazards)
    always @(posedge clk) begin
        if (!rst_n) begin
            id_ex_pc            <= 0;
            id_ex_read_data1    <= 0;
            id_ex_read_data2    <= 0;
            id_ex_imm           <= 0;
            id_ex_funct7        <= 0;
            id_ex_rs1           <= 0;
            id_ex_rs2           <= 0;
            id_ex_rd            <= 0;
            id_ex_funct3        <= 0;
            id_ex_ALU_OP        <= 0;
            id_ex_ALUSrcA_ctrl  <= 0;
            id_ex_ALUSrcB_ctrl  <= 0;
            id_ex_RegWrite      <= 0;
            id_ex_MemRead       <= 0;
            id_ex_MemWrite      <= 0;
            id_ex_MemToReg      <= 0;
            id_ex_Branch        <= 0;
            id_ex_Jump          <= 0;
        end else if (flush) begin
            id_ex_pc            <= 0;
            id_ex_read_data1    <= 0;
            id_ex_read_data2    <= 0;
            id_ex_imm           <= 0;
            id_ex_funct7        <= 0;
            id_ex_rs1           <= 0;
            id_ex_rs2           <= 0;
            id_ex_rd            <= 0;
            id_ex_funct3        <= 0;
            id_ex_ALU_OP        <= 0;
            id_ex_ALUSrcA_ctrl  <= 0;
            id_ex_ALUSrcB_ctrl  <= 0;
            id_ex_RegWrite      <= 0;
            id_ex_MemRead       <= 0;
            id_ex_MemWrite      <= 0;
            id_ex_MemToReg      <= 0;
            id_ex_Branch        <= 0;
            id_ex_Jump          <= 0;
        end else if (stall) begin
            // Multiplier stall: hold state stable
        end else if (load_use_stall) begin
            // Load-use stall: inject a bubble (clear control signals, but keep source regs to avoid forwarding issues)
            id_ex_pc            <= 0;
            id_ex_read_data1    <= 0;
            id_ex_read_data2    <= 0;
            id_ex_imm           <= 0;
            id_ex_funct7        <= 0;
            id_ex_rs1           <= 0;
            id_ex_rs2           <= 0;
            id_ex_rd            <= 0;
            id_ex_funct3        <= 0;
            id_ex_ALU_OP        <= 0;
            id_ex_ALUSrcA_ctrl  <= 0;
            id_ex_ALUSrcB_ctrl  <= 0;
            id_ex_RegWrite      <= 0;
            id_ex_MemRead       <= 0;
            id_ex_MemWrite      <= 0;
            id_ex_MemToReg      <= 0;
            id_ex_Branch        <= 0;
            id_ex_Jump          <= 0;
        end else begin
            id_ex_pc            <= if_id_pc;
            id_ex_read_data1    <= read_data1;
            id_ex_read_data2    <= read_data2;
            id_ex_imm           <= imm_out;
            id_ex_funct7        <= funct7;
            id_ex_rs1           <= rs1;
            id_ex_rs2           <= rs2;
            id_ex_rd            <= rd;
            id_ex_funct3        <= funct3;
            id_ex_ALU_OP        <= ALU_OP;
            id_ex_ALUSrcA_ctrl  <= ALUSrcA_ctrl;
            id_ex_ALUSrcB_ctrl  <= ALUSrcB_ctrl;
            id_ex_RegWrite      <= RegWrite;
            id_ex_MemRead       <= MemRead;
            id_ex_MemWrite      <= MemWrite;
            id_ex_MemToReg      <= MemToReg;
            id_ex_Branch        <= Branch;
            id_ex_Jump          <= Jump;
        end
    end

    // =========================================================================
    // 3. EXECUTE (EX) STAGE
    // =========================================================================
    wire [2:0] md_op;   // Uses funct3
    wire [3:0] alu_op;
    alu_control ac(
        .ALU_OP(id_ex_ALU_OP),
        .funct3(id_ex_funct3),
        .funct7(id_ex_funct7),
        .alu_op(alu_op),
        .is_mul_div(is_mul_div),
        .md_op(md_op)
    );

    wire [XLEN-1:0] alu_input_a;
    wire [XLEN-1:0] alu_input_b;
    wire zero_flag, carry_out, negative, overflow;
    wire [XLEN-1:0] alu_result;
    wire [31:0] mul_div_result;
    wire busy;

    mul_div md(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .md_op(md_op),
        .A(alu_input_a),
        .B(alu_input_b),
        .Result(mul_div_result),
        .busy(busy),
        .done(done)
    );

    // Dedicated target adder for branch and jump offset calculation
    wire [31:0] target_address = id_ex_pc + id_ex_imm;

    // ALU input multiplexers pulling from ID/EX pipeline stage registers
    assign alu_input_a =
            (id_ex_ALUSrcA_ctrl == 2'b00) ? id_ex_pc :
            (id_ex_ALUSrcA_ctrl == 2'b01) ? forwarded_read_data1 :
            (id_ex_ALUSrcA_ctrl == 2'b10) ? 32'b0 :
            forwarded_read_data1;

    assign alu_input_b =
            (id_ex_ALUSrcB_ctrl == 2'b00) ? forwarded_read_data2 :
            (id_ex_ALUSrcB_ctrl == 2'b01) ? 32'd4 :
            (id_ex_ALUSrcB_ctrl == 2'b10) ? id_ex_imm :
            forwarded_read_data2;

    ALU_n_bit #(
        .WIDTH(32)
    ) alu (
        .op_code(alu_op),
        .a(alu_input_a),
        .b(alu_input_b),
        .c_in(1'b0),
        .answer(alu_result),
        .c_out(carry_out),
        .zero(zero_flag),
        .negative(negative),
        .overflow(overflow)
    );

    // Evaluate branch conditions combinationaly in Execute stage
    reg id_ex_branch_taken;
    always @(*) begin
        case(id_ex_funct3)
            3'b000 : id_ex_branch_taken = zero_flag;                      // BEQ
            3'b001 : id_ex_branch_taken = ~zero_flag;                     // BNE
            3'b100 : id_ex_branch_taken = negative ^ overflow;            // BLT  (Signed)
            3'b101 : id_ex_branch_taken = ~(negative ^ overflow);         // BGE  (Signed)
            3'b110 : id_ex_branch_taken = ~carry_out;                     // BLTU (Unsigned)
            3'b111 : id_ex_branch_taken = carry_out;                      // BGEU (Unsigned)
            default: id_ex_branch_taken = 0;
        endcase
    end

    // Next PC Selection is determined immediately by branch resolution in the EX stage
    assign take_branch_or_jump = (id_ex_Branch & id_ex_branch_taken) | id_ex_Jump;
    assign PC_next = (take_branch_or_jump) ? target_address : PC_plus_4;

    // Output of the stage is either the ALU calculation or the Multiplier result
    wire [XLEN-1:0] ex_stage_result = (is_mul_div) ? mul_div_result : alu_result;

    // EX/MEM Pipeline Register sequential update
    always @(posedge clk) begin
        if(!rst_n) begin
            ex_mem_alu_result       <= 0;
            ex_mem_write_data       <= 0;
            ex_mem_rd               <= 0;
            ex_mem_MemRead          <= 0;
            ex_mem_MemWrite         <= 0;
            ex_mem_MemToReg         <= 0;
            ex_mem_RegWrite         <= 0;
        end else if (stall) begin
            // Bubble injection on stall: deactivate side-effects (writes)
            ex_mem_MemRead          <= 0;
            ex_mem_MemWrite         <= 0;
            ex_mem_RegWrite         <= 0;
        end else begin
            ex_mem_alu_result       <= ex_stage_result;
            ex_mem_write_data       <= forwarded_read_data2;
            ex_mem_rd               <= id_ex_rd;
            ex_mem_MemRead          <= id_ex_MemRead;
            ex_mem_MemWrite         <= id_ex_MemWrite;
            ex_mem_MemToReg         <= id_ex_MemToReg;
            ex_mem_RegWrite         <= id_ex_RegWrite;
        end
    end

    // =========================================================================
    // 4. MEMORY ACCESS (MEM) STAGE
    // =========================================================================
    wire [XLEN-1:0] mem_data;

    data_mem dm(
        .clk(clk),
        .MemRead(ex_mem_MemRead),
        .MemWrite(ex_mem_MemWrite),
        .write_data(ex_mem_write_data),
        .addr(ex_mem_alu_result),
        .read_data(mem_data)
    );

    // MEM/WB Pipeline Register sequential update
    always @(posedge clk) begin
        if(!rst_n) begin
            mem_wb_read_data    <= 0;
            mem_wb_alu_result   <= 0;
            mem_wb_rd           <= 0;
            mem_wb_MemToReg     <= 0;
            mem_wb_RegWrite     <= 0;
        end else begin
            mem_wb_read_data    <= mem_data;
            mem_wb_alu_result   <= ex_mem_alu_result;
            mem_wb_rd           <= ex_mem_rd;
            mem_wb_MemToReg     <= ex_mem_MemToReg;
            mem_wb_RegWrite     <= ex_mem_RegWrite;
        end
    end

    // =========================================================================
    // 5. WRITE-BACK (WB) STAGE
    // =========================================================================
    assign wb_write_data = (mem_wb_MemToReg) ? mem_wb_read_data : mem_wb_alu_result;

endmodule
