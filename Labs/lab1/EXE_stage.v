`timescale 1ns / 1ps

module   EXE_stage( input clk,                                
                    input rst,              
                    input reg_DE_flush,                      
                    input [31:0] inst_ID,                    
                    input [31:0] PC_ID,                      
                    input [31:0] rs1Data_ID,                
                    input [31:0] rs2Data_ID,                
                    input [31:0] imm_ID,
                    input [4:0] rs2Addr_ID,
                    input [4:0] rdAddr_ID,
                    input ALUSrc_A_ID,                     
                    input ALUSrc_B_ID,                     
                    input [3:0] ALUControl_ID,            
                    input [1:0] dataToReg_ID,                    
                    input regWrite_ID,                     
                    input memWrite_ID,                                
                    input [2:0] memAccType_ID,
                    input MIO_ID,

                    output [31:0] PC_EXE_Hazard,                      
                    output [31:0] inst_EXE_Hazard,                    
                    output [31:0] ALUOut_EXE_Hazard,                      
                    output [31:0] MemDataOut_EXE_Hazard,                      
                    output [31:0] SAMVOut_EXE_Hazard,                      
                    output [4:0]  rdAddr_EXE_Hazard,                   
                    output regWrite_EXE_Hazard,                       
                    output [2:0]  op_EXE_Hazard,                      
                    output [1:0]  dataToReg_tmp_EXE_Hazard,


                    output wire[31:0] ALUOut_EXE,
                    output wire[31:0] MemDataOut_EXE,
                    output wire[31:0] SAMVOut_EXE,
                    output wire [1:0] dataToReg_EXE
                );


    wire[31:0] PC_EXE;              
    wire[31:0] inst_EXE;
    wire[4:0]  rdAddr_EXE;           
    wire       regWrite_EXE;  
    wire       MIO_EXE;
    wire[31:0] Dataout_EXE;


    wire ALUSrc_A_EXE, ALUSrc_B_EXE, ALUzero_EXE, ALUoverflow_EXE;            
    wire[3:0] ALUControl_EXE;
    wire[31:0] rs1Data_EXE, rs2Data_EXE, imm_EXE, ALUA_EXE, ALUB_EXE;
    wire [1:0] dataToReg_tmp;

    
    wire[6:0] opcode = inst_EXE[6:0];
    wire [31:0] ALUOut, MemDataOut, SAMVOut;
    wire [31:0] addr_MEM;
    
    wire [2:0] memAccType_EXE;

    // IF/EXE Register
    REG_ID_EX reg_ID_EX(
        .clk            (clk),
        .rst            (rst),
        .EN             (1'b1),
        .flush          (reg_DE_flush),

        .IR_in          (inst_ID),
        .PC_in          (PC_ID),
        .rs1Data_in     (rs1Data_ID),
        .rs2Data_in     (rs2Data_ID),       
        .imm_in         (imm_ID),
        .rs2Addr_in     (rs2Addr_ID),
        .rdAddr_in      (rdAddr_ID),
        .ALUSrc_A_in    (ALUSrc_A_ID),
        .ALUSrc_B_in    (ALUSrc_B_ID),
        .ALUControl_in  (ALUControl_ID),
        .dataToReg_in   (dataToReg_ID),
        .regWrite_in    (regWrite_ID),
        .memWrite_in    (memWrite_ID),
        .memAccType_in  (memAccType_ID),
        .MIO_in         (MIO_ID),

        .IR_out         (inst_EXE),
        .PC_out         (PC_EXE),
        .rs1Data_out    (rs1Data_EXE),
        .rs2Data_out    (rs2Data_EXE),     
        .imm_out        (imm_EXE),
        .rs2Addr_out    (rs2Addr_EXE),
        .rdAddr_out     (rdAddr_EXE),
        .ALUSrc_A_out   (ALUSrc_A_EXE),
        .ALUSrc_B_out   (ALUSrc_B_EXE),
        .ALUControl_out (ALUControl_EXE),
        .dataToReg_out  (dataToReg_tmp),
        .regWrite_out   (regWrite_EXE),
        .memWrite_out   (memWrite_EXE),
        .memAccType_out (memAccType_EXE),
        .MIO_out        (MIO_EXE)
    );
    
    MUX2T1_32 mux_A_EXE(           // ALUA selection module
        .I0             (rs1Data_EXE),
        .I1             (PC_EXE),
        .s              (ALUSrc_A_EXE),
        .o              (ALUA_EXE)
    );

    MUX2T1_32 mux_B_EXE(            // ALUB selection module
        .I0             (rs2Data_EXE),
        .I1             (imm_EXE),
        .s              (ALUSrc_B_EXE),
        .o              (ALUB_EXE)
    );

    ALU alu(                        
        .A              (ALUA_EXE),
        .B              (ALUB_EXE),
        .Control        (ALUControl_EXE),
        .res            (ALUOut),
        .zero           (ALUzero_EXE),
        .overflow       (ALUoverflow_EXE)
    );
    
    SAMV SAMV(
        .clk            (clk),
        .rst            (rst),
        .EN             (1),                                           
        .A              (ALUA_EXE),
        .B              (ALUB_EXE),
        .res            (SAMVOut)
    );


    assign addr_MEM = rs1Data_EXE + imm_EXE;

    RAM_B data_ram(                     //Data memory
        .clka           (clk),
        .wea            (memWrite_EXE),
        .addra          (addr_MEM),
        .access_type    (memAccType_EXE),
        .dina           (rs2Data_EXE), 
        .douta          (MemDataOut)
    );

    // [Topic 1] Now we have ALUOut, SAMVOut and MemDataOut signals, each generated at different cycles.
    // Please add bubbles to make sure that the final ALUOut_EXE, MemDataOut_EXE and SAMVOut_EXE are ready after 3 cycles.

    // You may add some code here...
    reg [31:0] ALUOut_reg1, ALUOut_reg2;
    reg [31:0] MemDataOut_reg1;
    reg [1:0] dataToReg_reg1, dataToReg_reg2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ALUOut_reg1 <= 0;
            ALUOut_reg2 <= 0;
            MemDataOut_reg1 <= 0;
            dataToReg_reg1 <= 0;
            dataToReg_reg2 <= 0;
        end else begin
            ALUOut_reg1 <= ALUOut;
            ALUOut_reg2 <= ALUOut_reg1;
            MemDataOut_reg1 <= MemDataOut;
            dataToReg_reg1 <= dataToReg_tmp;
            dataToReg_reg2 <= dataToReg_reg1;
        end
    end
    
    assign ALUOut_EXE = ALUOut_reg2;
    assign MemDataOut_EXE = MemDataOut_reg1;
    assign SAMVOut_EXE = SAMVOut;
    assign dataToReg_EXE = dataToReg_reg2;

    // Below logics are for hazard dection, do not change them.

    wire [1:0] op_type; // For hazard detection. 0: ALU, 1: MEM, 2: MUL
    assign op_type = (opcode == 7'b0101011) ? 2'b10 : (MIO_EXE) ? 2'b01 : 2'b00;
    assign PC_EXE_Hazard = PC_EXE;                      
    assign inst_EXE_Hazard = inst_EXE;                    
    assign ALUOut_EXE_Hazard = ALUOut;                      
    assign MemDataOut_EXE_Hazard = MemDataOut;                      
    assign SAMVOut_EXE_Hazard = SAMVOut;                  
    assign rdAddr_EXE_Hazard = rdAddr_EXE;               
    assign regWrite_EXE_Hazard = regWrite_EXE;                  
    assign op_EXE_Hazard = op_type;                     
    assign dataToReg_tmp_EXE_Hazard = dataToReg_tmp;
endmodule