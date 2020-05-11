/**
 * datapath模块
 * @author AshinZ
 * @time   2020-4-18 
 * @param
 * @return 
*/

module datapath(clk,rst,regDst,jump,branch,memRead,memToReg,aluOp,memWrite,aluSrc,regWrite,extType,ID_instruction);

    input          clk;
    input          rst;
    input  [1:0]   regDst;
    input  [1:0]   jump;
    input  [1:0]   branch;
    input          memRead;
    input  [1:0]   memToReg;
    input  [2:0]   aluOp;
    input          memWrite;
    input          aluSrc;
    input          regWrite;
    input  [1:0]   extType; //control的结果
    output [31:0]  ID_instruction;

//进行四个流水线寄存器的变量声明
//变量命名规则 对于例如IF_ID模块 在其输出变量上加ID 输入加IF
//所以往往其输入是由上个部分声明 所以声明输出即可
//IF_ID寄存器
    wire  [31:2] ID_fourPC;
    wire  [31:0] ID_instruction;

//ID_EX寄存器
    wire  [31:2] EX_fourPC;
    wire  [1:0]  EX_regDst;
    wire  [1:0]  EX_jump;
    wire  [1:0]  EX_branch;
    wire         EX_memRead;
    wire  [1:0]  EX_memToReg;
    wire  [2:0]  EX_aluOp;
    wire         EX_memWrite;
    wire         EX_aluSrc;
    wire         EX_regWrite;
    wire [31:0]  EX_readData1;
    wire [31:0]  EX_readData2;
    wire [4:0]   EX_instruction1;
    wire [4:0]   EX_instruction2;
    wire [1:0]   EX_extType;
    wire [31:0]  EX_extNumber;
    wire [31:0]  EX_instruction;

//EX_MEM寄存器
    wire [31:2]   MEM_fourPC;
    wire [1:0]    MEM_jump;
    wire [1:0]    MEM_branch;
    wire          MEM_memRead;
    wire [1:0]    MEM_memToReg;
    wire          MEM_memWrite;
    wire          MEM_regWrite;
    wire          MEM_zero;
    wire [31:0]   MEM_aluResult;
    wire [31:0]   MEM_readData2;
    wire [4:0]    MEM_writeDataReg;
    wire [31:0]   MEM_instruction;

//MEM_WB寄存器
    wire [31:2]   WB_fourPC;
    wire [1:0]    WB_jump;
    wire [1:0]    WB_branch;
    wire          WB_memRead;
    wire [1:0]    WB_memToReg;
    wire          WB_memWrite;
    wire          WB_regWrite;
    wire [31:0]   WB_aluResult;
    wire [31:0]   WB_readData;
    wire [4:0]    WB_writeDataReg;
    wire [31:0]   WB_instruction;

// hazard detection模块
    wire          PCSrc;  //判断是否为branch
    wire          flush;  //冲刷数据指令                    
    wire          PC_write;//pc修改指令
    wire          IF_ID_write; //ifid更新指令
    wire          stall_info; //阻塞指令 用于control出来的数据选择器
    hazard_detection Hazard_detection(jump,EX_instruction[20:16],ID_instruction[25:21],ID_instruction[20:16],
    EX_memRead,MEM_instruction[20:16],MEM_memRead,PCSrc,PC_write,IF_ID_write,stall_info,flush);
/*  im    
    input   [11:2]   addr;//address bus
    output  [31:0]  dout;//32-bit memory output
*/
    wire [31:0]  instruction;
    wire [31:0]  mux_instruction;
    im_4k Im(PC[11:2],instruction);
    mux2_32 Mux2_32_3(instruction,32'b0,flush,mux_instruction);

/*  npc
    input  [31:2]  PC; //当前pc
    input  [25:0]  instruction;//指令的后26位 在j指令的时候使用
    input  [31:0]  beqInstruction;//beq指令用到的地址 这里是经过了左移两位的
    input  [1:0]   branch; //是否是beq
    input  [1:0]   jump;//是否为j指令
    input          zero;//alu计算出来的是否符合条件
    output [31:2]  NPC; //next pc
    output [31:2]  fourPc;//pc+4 用来针对jr指令
*/
    wire [31:2]  PC;
    wire [31:0]  temp_beqInstruction1;  
    wire [31:0]  temp_beqInstruction2; 
    wire [31:2]  beqInstruction;
    wire [31:2]  NPC;
    wire [31:2]  fourPc;
/*   pc
    input [31:2]   NPC;
    input          clk;
    input          rst;
    output [31:2]  PC;
    */
    pc Pc(NPC,clk,rst,PC_write,PC);
    npc Npc(PC,ID_instruction[25:0],beqInstruction,PCSrc,jump,NPC,fourPc);
    signext Signext_1(ID_instruction[15:0],2'b00,temp_beqInstruction1);
    sl2 Sl2(temp_beqInstruction1,temp_beqInstruction2);
    assign beqInstruction =  ID_fourPC + temp_beqInstruction2[31:2];
//加入IF_ID寄存器
    if_id If_id(clk,rst,PC + 1,mux_instruction,IF_ID_write,ID_fourPC,ID_instruction);


/*   regfile
    input  [4:0]   readRegister1,readRegister2,writeRegister;
    input  [32:0]  writeData;
    input          regWrite;
    input          clk;
    input          rst;
    output [31:0]  readData1,readData2;
*/
    wire [31:0] writeData;
    wire [31:0] readData1;
    wire [31:0] readData2;
    regfile Regfile(ID_instruction[25:21],ID_instruction[20:16],WB_writeDataReg,writeData,WB_regWrite,clk,rst,readData1,readData2);

/*  signext
    input  [15:0]   instruction;
    input  [1:0]    extType;
    output [31:0]   signExtNumber;
    */
    wire [31:0] signExtNumber;
    signext Signext(ID_instruction[15:0],extType,signExtNumber);

//加入ID_EX寄存器
    wire [14:0] ctrl_result;
    mux2_15 Mux_2_15_1({regDst,jump,branch,memRead,memToReg,aluOp,
    memWrite,aluSrc,regWrite},15'b0,stall_info,ctrl_result);
    //ctrl_result 是控制器前面的选择器的输出

    id_ex Id_ex(clk,rst,ID_fourPC,ctrl_result[14:13],ctrl_result[12:11],ctrl_result[10:9],ctrl_result[8],ctrl_result[7:6],
    ctrl_result[5:3],ctrl_result[2],ctrl_result[1],ctrl_result[0],readData1,readData2,ID_instruction[20:16],
    ID_instruction[15:11],signExtNumber,ID_instruction,
    EX_regDst,EX_jump,EX_branch,EX_memRead,
    EX_memToReg,EX_aluOp,EX_aluSrc,EX_regWrite,EX_memWrite,EX_readData1,EX_readData2,
    EX_extNumber,EX_instruction1,EX_instruction2,EX_fourPC,EX_instruction);

/*  alu
    input  [2:0]    aluOp;
    input  [31:0]   data1,data2;
    output          zero;
    output [31:0]   result;
*/
    wire [31:0]  mux_data;
    wire [31:0]  data1;
    wire [31:0]  data2;
    wire         zero;
    wire [31:0]  aluResult;
    mux2_32 Mux2_32_1(mux_data,EX_extNumber,EX_aluSrc,data2);  //送入alu的数据的选择 是i指令还是r指令
    alu Alu(EX_aluOp,data1,data2,zero,aluResult);
    wire [4:0] writeRegister;//写入的寄存器地址
    mux3_5 Mux3_5_1(EX_instruction1,EX_instruction2,5'b11111,EX_regDst,writeRegister); //寄存器前面的那个选择器
//加入forward 模块
    wire [1:0]  forward_A;
    wire [1:0]  forward_B;
    wire [4:0]  EX_MEM_Rd;
    wire [4:0]  MEM_WB_Rd;
    mux2_5 Mux2_5_1(MEM_instruction[15:11],MEM_instruction[20:16],MEM_instruction[31:26],EX_MEM_Rd);
    mux2_5 Mux2_5_2(WB_instruction[15:11],WB_instruction[20:16],WB_instruction[31:26],MEM_WB_Rd);
    forwarding_unit_alu Forwarding_unit(EX_instruction[25:21],EX_instruction[20:16],EX_MEM_Rd,MEM_WB_Rd,
    MEM_regWrite,WB_regWrite,forward_A,forward_B);
    //这个转发要注意 判断的条件 后面两个流水寄存器的目标寄存器 并不一定是20:16  所以要加一个mux
    mux3_32 Mux_3_32_3(EX_readData1,writeData,MEM_aluResult,forward_A,data1);
    mux3_32 Mux_3_32_4(EX_readData2,writeData,MEM_aluResult,forward_B,mux_data);


//加入EX_MEM寄存器
    ex_mem Ex_mem(clk,rst,EX_fourPC,EX_jump,EX_branch,EX_memRead,EX_memToReg,
    EX_memWrite,EX_regWrite,zero,aluResult,mux_data,
    writeRegister,EX_instruction,MEM_jump,MEM_branch,MEM_memRead,MEM_memToReg,MEM_memWrite,MEM_regWrite,//往后传输的数据
    MEM_zero,MEM_aluResult,MEM_readData2,MEM_writeDataReg,MEM_fourPC,MEM_instruction);

/*  dm
     input   [11:2]  addr;   
    input           we;     
    input           clk;    
    input   [31:0]  din;    
    output  [31:0]  dout;   
*/
    wire [31:0] dout;
    dm_4k Dm(MEM_aluResult[11:2],MEM_memWrite,clk,MEM_readData2,dout);

//加入MEM_WB寄存器
    mem_wb Mem_wb(clk,rst,MEM_fourPC,MEM_jump,MEM_memToReg,dout,MEM_aluResult,
    MEM_writeDataReg,MEM_regWrite,MEM_instruction,WB_jump,WB_memToReg,//往后传输的数据
    WB_readData,WB_aluResult,WB_writeDataReg,WB_regWrite,WB_fourPC,WB_instruction);

    mux3_32 Mux2_32_2(WB_readData,WB_aluResult,{WB_fourPC,2'b00},WB_memToReg,writeData); //dm后面那个mux

//加入beq前移的相关模块
//转发模块
    wire [1:0]   Forward_Rs;
    wire [1:0]   Forward_Rt;
  //  wire [31:0]  Branch_Forward_Data;
    wire [31:0]  Compare_Data1;
    wire [31:0]  Compare_Data2;
    wire         branch_zero;
    wire  [4:0]   ID_EX_Rd;
    mux2_5 Mux2_5_3 (EX_instruction[15:11],EX_instruction[20:16],EX_instruction[31:26],ID_EX_Rd);
    forwarding_unit_branch Forwarding_unit_branch (ID_instruction[25:21],ID_instruction[20:16]
    ,EX_MEM_Rd,MEM_regWrite,ID_EX_Rd,EX_regWrite,Forward_Rs,Forward_Rt);

    
   // mux2_32 Mux2_32_4(MEM_aluResult,dout,MEM_memRead,Branch_Forward_Data);//如果要读的话就说明是lw 所以我们取后面的
    mux3_32 Mux3_32_5(readData1,aluResult,MEM_aluResult,Forward_Rs,Compare_Data1);
    mux3_32 Mux3_32_6(readData2,aluResult,MEM_aluResult,Forward_Rt,Compare_Data2);
    compare Compare(Compare_Data1,Compare_Data2,branch_zero);
    add Add(branch,branch_zero,PCSrc);

endmodule