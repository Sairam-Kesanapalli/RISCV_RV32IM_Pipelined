module alu_control(
    input [2:0] ALU_OP,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [3:0] alu_op,
    output reg is_mul_div,
    output reg [2:0] md_op
);

localparam ADD = 4'd0;
localparam SUB = 4'd1;
localparam AND = 4'd4;
localparam OR  = 4'd5;
localparam XOR = 4'd6;
localparam SLL = 4'd8;
localparam SRL = 4'd9;
localparam SRA = 4'd10;
localparam SLT = 4'd11;

    always @(*) begin
        // Default outputs
        is_mul_div = 1'b0;
        md_op      = 3'b000;
        
        case (ALU_OP)
        3'd0: begin                                     // I-TYPE
            case(funct3)                        
                3'b000 : alu_op = ADD;
                3'b001 : alu_op = SLL;
                3'b010 : alu_op = SLT;
                3'b100 : alu_op = XOR;
                3'b110 : alu_op = OR ;
                3'b111 : alu_op = AND;
                3'b101 : begin
                        if (funct7 == 7'b0000000)
                            alu_op = SRL;
                        else if(funct7 == 7'b0100000)
                            alu_op = SRA;
                        else
                            alu_op = ADD;
                    end
                default: alu_op = ADD;
            endcase
        end
        3'd1: begin                                    // B
            alu_op = SUB;                              // NO NEED TO CHECK FUNCT3 - ALL REQS SAME OPERATION
        end
        3'd2: begin
            if (funct7 == 7'b0000001) begin
                // M-Extension (Multiplication / Division)
                is_mul_div = 1'b1;
                md_op      = funct3;
                alu_op     = ADD; // Doesn't matter
            end else begin
                case({funct7, funct3})                  // R-TYPE
                        10'b0000000000: alu_op = ADD;  
                        10'b0100000000: alu_op = SUB;  
                        10'b0000000111: alu_op = AND;
                        10'b0000000110: alu_op = OR;
                        10'b0000000100: alu_op = XOR;
                        10'b0000000001: alu_op = SLL;
                        10'b0000000101: alu_op = SRL;
                        10'b0100000101: alu_op = SRA;
                        10'b0000000010: alu_op = SLT;
                        default : alu_op = ADD;
                endcase
            end
        end

        3'd3: alu_op = ADD;                             // MEM/U-TYPE

        default : alu_op = ADD;
        endcase
     end
endmodule
