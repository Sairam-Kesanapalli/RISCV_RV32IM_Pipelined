
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 01/16/2026 03:26:46 PM
// Design Name:
// Module Name: ALU_n_bit
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module ALU_n_bit#(
    parameter WIDTH = 32
)(
    input [3:0] op_code,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input c_in,
    output reg [WIDTH-1:0] answer,
    output reg c_out,
    output reg zero,
    output reg negative,
    output reg overflow
);

    wire [WIDTH-1:0] add_sol;
//  wire [WIDTH-1:0] sub_sol;
    wire [WIDTH-1:0] inc_sol;
    wire [WIDTH-1:0] dec_sol;

    wire [WIDTH-1:0] and_sol;
    wire [WIDTH-1:0] or_sol;
    wire [WIDTH-1:0] xor_sol;
    wire [WIDTH-1:0] not_sol;

    wire [WIDTH-1:0] left_shift_logical_sol;
    wire [WIDTH-1:0] right_shift_logical_sol;

    wire [WIDTH-1:0] right_shift_arithmetic_sol;
    wire [WIDTH-1:0] SLT;

//  wire sub_in;
//  wire sub_out;
//  wire add_in;
    wire add_out;

//FOR SUBTRACTING LOGIC
    wire sub;
    wire [WIDTH-1:0] b_mux;
    wire carry_mux;
    wire overflow_wire;


    assign sub = (op_code == 4'd1);
    assign b_mux = sub? ~b : b;                 // NOT IS 1'S COMPLEMENT
    assign carry_mux = sub? 1'b1 : c_in;        // SUB = A + (~B + 1)


/*

        WHY OVERFLOW REQ?
        FOR SIGNED INTEGERS EX: 4BIT SIGNED NUMBER EXISTS FROM -8 TO +7
        IF A + B IS ASKED FOR A=0100  B=0101    {A=4, B=5}
        SUM WILL BE 1001 {9} WHICH WILL BE -1 IN SIGNED NUMBERS
        SO IT WILL BE AN OVERFLOW

*/


//  assign sub_in = c_in;
//  assign add_in = c_in;

    full_adder_n_bit #(
    .WIDTH(WIDTH)
    )f1(
        .a(a),
        .b(b_mux),
        .c_in(carry_mux),
        .c_out(add_out),
        .sum(add_sol)
    );

    assign overflow_wire = ((a[WIDTH-1] == b_mux[WIDTH-1]) && (a[WIDTH-1] != add_sol[WIDTH-1]));
/*    full_subtractor_n_bit f2#(
    .WIDTH(WIDTH)                           // INDUSTRIES DO NOT USE SEPERATE SUBTRACT BLOCK
    )(
        .a(a),
        .b(b),
        .difference(sub_sol),
        .borrow_in(c_in),
        .borrow_out(sub_out)
    );
*/
    assign inc_sol = a + 1;
    assign dec_sol = a - 1;

    assign and_sol = a & b;
    assign or_sol = a | b;
    assign xor_sol = a ^ b;
    assign not_sol = ~a;

    assign left_shift_logical_sol = a << b[4:0];
    assign right_shift_logical_sol = a >> b[4:0];

    assign right_shift_arithmetic_sol = $signed(a) >>> b[4:0];
    assign SLT = ($signed(a) < $signed(b))? 32'd1 : 32'd0;
    always @(*) begin

    overflow = 1'b0;
    answer = {WIDTH{1'b0}};
    c_out  = 1'b0;

    case(op_code)

        4'd0,
        4'd1 : begin
                    answer = add_sol;
                    c_out = add_out;
                    overflow = overflow_wire;
               end
        4'd2 : answer = inc_sol;
        4'd3 : answer = dec_sol;
        4'd4 : answer = and_sol;
        4'd5 : answer = or_sol;
        4'd6 : answer = xor_sol;
        4'd7 : answer = not_sol;
        4'd8 : answer = left_shift_logical_sol;
        4'd9 : answer = right_shift_logical_sol;
        4'd10: answer = right_shift_arithmetic_sol;
        4'd11: answer = SLT;
        default: begin
                    answer = {WIDTH{1'b0}};
                    c_out  = 1'b0;
                 end
        //1 for bitwise or
        //2 for bitwise and
        //3 for bitwise xor
        //4 for adder
        //5 for subtracting
     endcase

    zero = (answer == {WIDTH{1'b0}});
    negative = answer[WIDTH-1];

     end
endmodule
