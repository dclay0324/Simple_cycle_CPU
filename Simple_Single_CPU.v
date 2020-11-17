`timescale 1ns / 1ps
module Simple_Single_CPU(
    clk_i,
	rst_i
);
		
//I/O port
input         clk_i;
input         rst_i;

//Internal Signles
wire [32-1:0] instr_w; 
wire [64-1:0] pc_addr_w;
wire [64-1:0] Imm_Gen_w; 
wire [64-1:0] shift_left_w;
wire [64-1:0] mux_alusrc_w;
wire [64-1:0] mux_pc_result_w;
wire [64-1:0] add2_sum_w;
wire [4-1:0]  alu_control_w; 
wire [64-1:0] alu_result_w;
wire [64-1:0] dataMem_read_w;
wire [64-1:0] mux_dataMem_result_w; 
wire [64-1:0] rf_rs1_data_w;
wire [64-1:0] rf_rs2_data_w;
wire [64-1:0] add1_result_w;
wire [64-1:0] add1_source_w;
assign add1_source_w = 64'd4;
wire [2-1:0]  ctrl_alu_op_w; 
wire ctrl_write_mux_w;
wire ctrl_register_write_w; 
wire ctrl_branch_w;
wire ctrl_alu_mux_w;
wire and_result_w;
wire alu_zero_w;
wire ctrl_mem_write_w;
wire ctrl_mem_read_w;
wire ctrl_mem_mux_w;
wire and_mux;

//Create components
ProgramCounter PC(
        .clk_i(clk_i),      
	    .rst_i (rst_i),     
	    .pc_in_i(mux_pc_result_w[63:0]) ,   
	    .pc_out_o(pc_addr_w[63:0]) 
	    );
	
Adder Adder1(
        .src1_i(pc_addr_w[63:0]),
	    .src2_i(add1_source_w),     
	    .sum_o(add1_result_w[63:0])    
	    );
	
Instr_Mem IM(
        .pc_addr_i(pc_addr_w[63:0]),  
	    .instr_o(instr_w[31:0])    
	    );

//DO NOT MODIFY	.RDdata_i && .RegWrite_i
Reg_File RF(
        .clk_i(clk_i),
		.rst_i(rst_i),
		.RS1addr_i(instr_w[19:15]) ,
		.RS2addr_i(instr_w[24:20]) ,
		.RDaddr_i(instr_w[11:7]) ,
		.RDdata_i(mux_dataMem_result_w[64-1:0]),
		.RegWrite_i(ctrl_register_write_w),
		.RS1data_o(rf_rs1_data_w[63:0]) ,
		.RS2data_o(rf_rs2_data_w[63:0])
        );
	
//DO NOT MODIFY	.RegWrite_o
Control Control(
        .instr_op_i(instr_w[6:0]),
		.Branch_o(ctrl_branch_w),
		.MemRead_o(ctrl_mem_read_w),
		.MemtoReg_o(ctrl_mem_mux_w),
	    .ALU_op_o(ctrl_alu_op_w[1:0]),
		.MemWrite_o(ctrl_mem_write_w),
	    .ALUSrc_o(ctrl_alu_mux_w),
	    .RegWrite_o(ctrl_register_write_w)
	    );

ALU_Ctrl AC(
        .funct_i({instr_w[30], instr_w[14:12]}),   
        .ALUOp_i(ctrl_alu_op_w[2-1:0]),   
        .ALUCtrl_o(alu_control_w[4-1:0]) 
        );
	
Imm_Gen IG(
        .data_i(instr_w[32-1:0]),
        .data_o(Imm_Gen_w[64-1:0])
        );

MUX_2to1 #(.size(64)) Mux_ALUSrc(
        .data0_i(rf_rs2_data_w[63:0]),
        .data1_i(Imm_Gen_w[64-1:0]),
        .select_i(ctrl_alu_mux_w),
        .data_o(mux_alusrc_w[63:0])
        );	
		
ALU ALU(
        .src1_i(rf_rs1_data_w[63:0]),
	    .src2_i(mux_alusrc_w[63:0]),
	    .ctrl_i(alu_control_w[4-1:0]),
	    .result_o(alu_result_w[63:0]),
		.zero_o(alu_zero_w)
	    );
		
Adder Adder2(
        .src1_i(pc_addr_w[63:0]),     
	    .src2_i(shift_left_w[63:0]),     
	    .sum_o(add2_sum_w[63:0])      
	    );
		
Shift_Left_One_64 Shifter(
        .data_i(Imm_Gen_w[64-1:0]),
        .data_o(shift_left_w[63:0])
        ); 		

assign and_mux = ctrl_branch_w & alu_zero_w;
MUX_2to1 #(.size(64)) Mux_PC_Source(
        .data0_i(add1_result_w[63:0]),
        .data1_i(add2_sum_w[63:0]),
        .select_i(and_mux),
        .data_o(mux_pc_result_w[63:0])
        );	
		
		
Data_Mem DataMemory(
		.clk_i(clk_i),
		.rst_i(rst_i),
		.addr_i(alu_result_w[63:0]),
		.data_i(rf_rs2_data_w[63:0]),
		.MemRead_i(ctrl_mem_read_w),
		.MemWrite_i(ctrl_mem_write_w),
		.data_o(dataMem_read_w[63:0])
		);

//DO NOT MODIFY	.data_o
 MUX_2to1 #(.size(64)) Mux_DataMem_Read(
        .data0_i(alu_result_w[63:0]),
        .data1_i(dataMem_read_w[63:0]),
        .select_i(ctrl_mem_mux_w),
        .data_o(mux_dataMem_result_w)
		);

endmodule