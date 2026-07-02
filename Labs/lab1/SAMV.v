`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/11 11:32:25
// Design Name: 
// Module Name: PipelineSA
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


module SAMV(
    input clk,                                        
    input rst,
    input EN,                                           
    input[31:0] A, B,
    output[31:0] res
    );

// [Topic 1] Please finish the code of systolic array for matrix-vector multiplication that requires 3 cycles for execution.
// You may use the Mac module in common/Mac.v to implement the multiplication and add process.
// The pipeline SA is OK. And you can also find different ways to implenment it.

// You may add some code here...
wire [8:0] m1_res, m2_res, m3_res, m4_res;
reg [3:0] b_reg, r_reg, s_reg;
reg [8:0] m1_reg, m3_reg;
reg [15:0] res_high, res_low;

always @(posedge clk) begin
    if (rst) begin
        b_reg <= 0; r_reg <= 0; s_reg <= 0;
        m1_reg <= 0; m3_reg <= 0;
    end else if (EN) begin
        m1_reg <= m1_res;
        m3_reg <= m3_res;
        b_reg <= A[3:0]; r_reg <= B[7:4]; s_reg <= B[3:0];

        res_high <= {7'b0, m2_res};
        res_low <= {7'b0, m4_res};
    end
end

Mac mac1(
    .clk(clk),
    .rst(rst),
    .EN(EN),
    .A(A[7:4]),//a
    .B(B[15:12]),//p
    .C(8'b0),
    .res(m1_res)
);

Mac mac2(
    .clk(clk),
    .rst(rst),
    .EN(EN),
    .A(b_reg),//b
    .B(r_reg),//r
    .C(m1_reg[7:0]),//ap
    .res(m2_res)
);

Mac mac3(
    .clk(clk),
    .rst(rst),
    .EN(EN),
    .A(A[7:4]),//a
    .B(B[11:8]),//q
    .C(8'b0),
    .res(m3_res)
);

Mac mac4(
    .clk(clk),
    .rst(rst),
    .EN(EN),
    .A(b_reg),//b
    .B(s_reg),//s
    .C(m3_reg[7:0]),//aq
    .res(m4_res)
);

assign res = (res_high << 16) + res_low; // Complete the signal here.

endmodule

