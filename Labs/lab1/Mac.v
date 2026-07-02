`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/11 11:11:34
// Design Name: 
// Module Name: Mac
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


module Mac(
    input clk,                                        
    input rst,
    input EN,                                           
    input[3:0] A, B,
    input[7:0] C,
    output[8:0] res
    );
    wire [7:0] mult;
    Mult4 mult4(
        .clk(clk),
        .rst(rst),
        .EN(EN),
        .A(A),
        .B(B),
        .res(mult)
    );
    assign res = mult + C;
    
endmodule
