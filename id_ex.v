/**
 * ID与Ex之间的寄存器模块
 * @author AshinZ
 * @time   2020-4-26
*/

module id_ex(clk,rst,fourPC,//传时钟和pc+4
regDst,jump,branch,memRead,memToReg,aluOp,memWrite,aluSrc,regWrite,//控制器输入
readData1,readData2,instruction1,instruction2,extNumber, //regfile和拓展其输入
out_regDst,out_jump,out_branch,out_memRead,out_memToReg,out_aluOp,out_aluSrc,out_regWrite,
out_memWrite,out_readData1,out_readData2,
out_extNumber,out_instruction1,out_instruction2,out_fourPC);

    input           clk;
    input           rst;
    input  [31:2]   fourPC;
    input  [1:0]    regDst;
    input  [1:0]    jump;
    input  [1:0]    branch;
    input           memRead;
    input  [1:0]    memToReg;
    input  [2:0]    aluOp;
    input           memWrite;
    input           aluSrc;
    input           regWrite;
    input  [31:0]   readData1;
    input  [31:0]   readData2;
    input  [5:0]    instruction1;
    input  [5:0]    instruction2;
    input  [31:0]   extNumber;

    output reg [31:2]   out_fourPC;
    output reg [1:0]    out_regDst;
    output reg [1:0]    out_jump;
    output reg [1:0]    out_branch;
    output reg          out_memRead;
    output reg [1:0]    out_memToReg;
    output reg [2:0]    out_aluOp;
    output reg          out_memWrite;
    output reg          out_aluSrc;
    output reg          out_regWrite;
    output reg [31:0]   out_readData1;
    output reg [31:0]   out_readData2;
    output reg [5:0]    out_instruction1;
    output reg [5:0]    out_instruction2;
    output reg [31:0]   out_extNumber;

    always @(posedge clk)
        begin
            out_fourPC <= fourPC;
            out_regDst <= regDst;
            out_jump <= jump;
            out_branch <= branch;
            out_memRead <= memRead;
            out_memToReg <= memToReg;
            out_aluOp <= aluOp;
            out_memWrite <= memWrite;
            out_aluSrc <= aluSrc;
            out_regWrite <= regWrite;
            out_readData1 <= readData1;
            out_readData2 <= readData2;
            out_instruction1 <= instruction1;
            out_instruction2 <= instruction2;
            out_extNumber <= extNumber;
        end
endmodule