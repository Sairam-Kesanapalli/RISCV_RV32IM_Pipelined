
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 01/14/2026 11:13:05 AM
// Design Name:
// Module Name: 4_bit_adder
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


module full_adder_n_bit #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input c_in,
    output c_out,
    output [WIDTH-1:0] sum
    );

    assign {c_out,sum} = a + b + c_in;


    //logic c1,c2,c3;

    //full_adder f1(.a(a[0]), .b(b[0]), .c(c_in), .sum(sum[0]), .carry(c1));
    //full_adder f2(.a(a[1]), .b(b[1]), .c(c1), .sum(sum[1]), .carry(c2));
    //full_adder f3(.a(a[2]), .b(b[2]), .c(c2), .sum(sum[2]), .carry(c3));
    //full_adder f4(.a(a[3]), .b(b[3]), .c(c3), .sum(sum[3]), .carry(c_out));
endmodule
