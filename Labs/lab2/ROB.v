`timescale 1ns / 1ps

`define ROB_SIZE 4

module ROB (
    input wire clk,
    input wire rst,
    input wire[1:0]   ALU_entry,               
    input wire        ALU_valid,
    input wire[4:0]   ALU_addr,
    input wire[31:0]  ALU_data,

    input wire[1:0]   MEM_entry,
    input wire        MEM_valid,
    input wire[4:0]   MEM_addr,
    input wire[31:0]  MEM_data,

    input wire[1:0]   SAMV_entry,
    input wire        SAMV_valid,
    input wire[4:0]   SAMV_addr,
    input wire[31:0]  SAMV_data,

    input wire[1:0]   rs1RobAddr,
    input wire[1:0]   rs2RobAddr,

    output wire       rdReady,
    output wire[4:0]  rdAddr,
    output wire[31:0] rdData,
    output wire[1:0]  rdRobAddr,

    output wire       rs1FwdReady,
    output wire[31:0] rs1FwdData,
    output wire       rs2FwdReady,
    output wire[31:0] rs2FwdData
);

    reg  [31:0] ROB_data[0:`ROB_SIZE-1];
    reg  [4:0]  ROB_addr[0:`ROB_SIZE-1];
    reg         ROB_valid[0:`ROB_SIZE-1];

    reg  [1:0]  ROB_head;
    
    assign rs1FwdReady  = ROB_valid[rs1RobAddr];
    assign rs1FwdData   = ROB_data[rs1RobAddr];
    assign rs2FwdReady  = ROB_valid[rs2RobAddr];
    assign rs2FwdData   = ROB_data[rs2RobAddr];

    // [Topic 2]: Please finish the ROB module. 

    integer i;

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            ROB_head = 0;
            for(i=0;i<`ROB_SIZE;i=i+1) begin
                ROB_data[i] <= 0;
                ROB_addr[i] <= 0;
                ROB_valid[i] <= 0;
            end
        end else begin
            if(ALU_valid) begin
                ROB_data[ALU_entry] <= ALU_data;
                ROB_addr[ALU_entry] <= ALU_addr;
                ROB_valid[ALU_entry] <= 1'b1;
            end
            if(MEM_valid) begin
                ROB_data[MEM_entry] <= MEM_data;
                ROB_addr[MEM_entry] <= MEM_addr;
                ROB_valid[MEM_entry] <= 1;
            end
            if(SAMV_valid) begin
                ROB_data[SAMV_entry] <= SAMV_data;
                ROB_addr[SAMV_entry] <= SAMV_addr;
                ROB_valid[SAMV_entry] <= 1'b1;
            end
            if(ROB_valid[ROB_head]) begin
                ROB_head <= ROB_head + 2'b01;
                ROB_valid[ROB_head] <= 1'b0;
            end
        end
    end

    assign rdReady      = ROB_valid[ROB_head];
    assign rdAddr       = ROB_addr[ROB_head];
    assign rdData       = ROB_data[ROB_head];
    assign rdRobAddr    = ROB_head;

endmodule