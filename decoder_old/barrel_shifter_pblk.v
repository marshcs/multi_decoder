`timescale 1ns / 1ps
/* ====================================================================================
Company: 南京大学
Engineer: 胡光�???

---------------------------------------------------------------------------------------
Create Date: 2017-04-05 13:09:53
Design Name: barrel_shifter_pblk.v
Project Name: 

---------------------------------------------------------------------------------------
Description:	该模块完�??? DATA_NUM * DATA_WIDTH bit 信号的循环移位功�???
				每次移位�??? DATA_WIDTH bit 为单位，每次�??? i_shift_offset �??? SHIFT_STEP bit 进行处理
				
				�??? i_shift_offset = 6'b10_11_01 (6'd45)�??? SHIFT_STEP = 2
				第一次取 01	单位步长�??? 1 * DATA_WIDTH 移动步长�??? 1*1*DATA_WDITH bit
				第二次取 11 	单位步长�??? 4 	* DATA_WIDTH 移动步长�??? 3*4*DATA_WDITH bit
				第一次取 10 	单位步长�??? 16 * DATA_WIDTH 移动步长�??? 2*16*DATA_WDITH bit
				�???共移�??? 45*DATA_WIDTH bit
				
				i_blk_ena 控制模块工作状�??
				i_blk_ena = 1 模块正常工作
				i_blk_ena = 0 模块不工作，将输入数据直接输�???
            
---------------------------------------------------------------------------------------
Revision: 0.01

Revision 0.01 - File Created

==================================================================================== */

/*	Cycle right shifter
*/

module barrel_shifter_pblk #(
	parameter DATA_WIDTH 			= 4	,	// 单个数据位宽
	parameter DATA_NUM				= 32,	// 数据的总数
	parameter SHIFT_OFFSET_WIDTH 	= 5		// 移位值的位宽
)(	
	input 										i_blk_ena		,	// 该信号的每一位表�??? QC Block 列中每个 QC Block 的使能信号，低电平表示对应的 QC Block 被全零矩阵掩�???
	
	input 		[SHIFT_OFFSET_WIDTH-1:0]		i_shift_offset	,	// 移位�???

	input		[DATA_NUM*DATA_WIDTH-1:0]		i_data			,	// 输入数据
	output 		[DATA_NUM*DATA_WIDTH-1:0]		o_shift_data		// 移位后的数据
);

// -------------------------v 每次移动的步�??? v-------------------------

localparam SHIFT_STEP = 8; // 每次�??? i_shift_offset �??? SHIFT_STEP bit 进行操作 

localparam SHIFT_CYCLE = (SHIFT_OFFSET_WIDTH == SHIFT_OFFSET_WIDTH / SHIFT_STEP * SHIFT_STEP)? 
							SHIFT_OFFSET_WIDTH / SHIFT_STEP : // SHIFT_OFFSET_WIDTH �??? SHIFT_STEP 整除
							SHIFT_OFFSET_WIDTH / SHIFT_STEP + 1; // SHIFT_OFFSET_WIDTH 不能�??? SHIFT_STEP 整除

wire [SHIFT_CYCLE*SHIFT_STEP-1:0] w_shift_offset_expand;	// 如果移位值是7bit的，展成12bit的数�??? SHIFT_CYCLE = 2

assign w_shift_offset_expand = i_shift_offset;

wire [SHIFT_STEP-1:0] w_offset_per_cycle [SHIFT_CYCLE-1:0];

genvar i;

generate
	for(i = 0; i < SHIFT_CYCLE; i = i + 1) begin: offset_per_cycle

		assign w_offset_per_cycle[i] = w_shift_offset_expand[(i+1)*SHIFT_STEP-1:i*SHIFT_STEP];

	end
endgenerate

// -------------------------^ 每次移动的步�??? ^-------------------------

reg [DATA_NUM*DATA_WIDTH-1:0] r_shift_data [SHIFT_CYCLE:0];

assign o_shift_data = i_blk_ena ? r_shift_data[SHIFT_CYCLE] : i_data;

always @(*) begin
	r_shift_data[0] = i_data;
end

// {0:d}:	r_shift_data[i] = r_shift_data[i-1][{0:d}*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:{0:d}*SHIFT_BITNUM*DATA_WIDTH];

// -------------------------v 每次处理 1 bit v-------------------------

generate
	if(SHIFT_STEP == 1) begin
		
		for(i = 1; i <= SHIFT_CYCLE; i = i + 1) begin: shift_data_assign

			// 每次的单位步长为 (2^SHIFT_STEP)^(i-1)
			localparam SHIFT_BITNUM = (1 << (SHIFT_STEP*(i-1)));
	
			always @(*) begin
				if(w_offset_per_cycle[i-1] == 0)		r_shift_data[i] = r_shift_data[i-1];
				else 									r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
			end

		end
	end
endgenerate

// -------------------------^ 每次处理 1 bit ^-------------------------

// -------------------------v 每次处理 2 bit v-------------------------

generate
	if(SHIFT_STEP == 2) begin
		
		for(i = 1; i <= SHIFT_CYCLE; i = i + 1) begin: shift_data_assign

			// 每次的单位步长为 (2^SHIFT_STEP)^(i-1)
			localparam SHIFT_BITNUM = (1 << (SHIFT_STEP*(i-1)));

			if((i == SHIFT_CYCLE)&&(SHIFT_CYCLE * SHIFT_STEP != SHIFT_OFFSET_WIDTH)) begin 
				
				always @(*) begin
					if(w_offset_per_cycle[i-1] == 1)		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};	
					else 									r_shift_data[i] = r_shift_data[i-1];
				end

			end
			else begin
				
				always @(*) begin
					if(w_offset_per_cycle[i-1] == 1)		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 2)	r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 3)	r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
					else 									r_shift_data[i] = r_shift_data[i-1];
				end
	
			end
		end
	end
endgenerate

// -------------------------^ 每次处理 2 bit ^-------------------------

// -------------------------v 每次处理 3 bit v-------------------------

generate
	if(SHIFT_STEP == 3) begin
		
		for(i = 1; i <= SHIFT_CYCLE; i = i + 1) begin: shift_data_assign

			// 每次的单位步长为 (2^SHIFT_STEP)^(i-1)
			localparam SHIFT_BITNUM = (1 << (SHIFT_STEP*(i-1)));

			if((i == SHIFT_CYCLE)&&(SHIFT_CYCLE * SHIFT_STEP != SHIFT_OFFSET_WIDTH)) begin 
				
				if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 2) begin

					always @(*) begin
						if(w_offset_per_cycle[i-1] == 1)		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};	
						else 									r_shift_data[i] = r_shift_data[i-1];
					end
	
				end
				else if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 1) begin
	
					always @(*) begin
						if(w_offset_per_cycle[i-1] == 1)		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 2)	r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 3)	r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
						else 									r_shift_data[i] = r_shift_data[i-1];
					end
	
				end
			end
			else begin
				
				always @(*) begin
					if(w_offset_per_cycle[i-1] == 1)			r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};		
					else if(w_offset_per_cycle[i-1] == 2)		r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};		
					else if(w_offset_per_cycle[i-1] == 3)		r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 4)		r_shift_data[i] = {r_shift_data[i-1][4*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:4*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 5)		r_shift_data[i] = {r_shift_data[i-1][5*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:5*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 6)		r_shift_data[i] = {r_shift_data[i-1][6*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:6*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 7)		r_shift_data[i] = {r_shift_data[i-1][7*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:7*SHIFT_BITNUM*DATA_WIDTH]};	
					else 										r_shift_data[i] = r_shift_data[i-1];				
				end
	
			end
		end
	end
endgenerate

// -------------------------^ 每次处理 3 bit ^-------------------------

// -------------------------v 每次处理 6 bit v-------------------------

generate
	if(SHIFT_STEP == 6) begin
		
		for(i = 1; i <= SHIFT_CYCLE; i = i + 1) begin: shift_data_assign

			// 每次的单位步长为 (2^SHIFT_STEP)^(i-1)
			localparam SHIFT_BITNUM = (1 << (SHIFT_STEP*(i-1)));

			if((i == SHIFT_CYCLE)&&(SHIFT_CYCLE * SHIFT_STEP != SHIFT_OFFSET_WIDTH)) begin 
				
				if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 5) begin

					always @(*) begin
						if(w_offset_per_cycle[i-1] == 1)		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};	
						else 									r_shift_data[i] = r_shift_data[i-1];
					end
	
				end
				else if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 4) begin

					always @(*) begin
						if(w_offset_per_cycle[i-1] == 1)		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 2)	r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 3)	r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
						else 									r_shift_data[i] = r_shift_data[i-1];
					end
	
				end
				else if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 3) begin

					always @(*) begin
						if(w_offset_per_cycle[i-1] == 1)		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};		
						else if(w_offset_per_cycle[i-1] == 2)	r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};		
						else if(w_offset_per_cycle[i-1] == 3)	r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 4)	r_shift_data[i] = {r_shift_data[i-1][4*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:4*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 5)	r_shift_data[i] = {r_shift_data[i-1][5*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:5*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 6)	r_shift_data[i] = {r_shift_data[i-1][6*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:6*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 7)	r_shift_data[i] = {r_shift_data[i-1][7*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:7*SHIFT_BITNUM*DATA_WIDTH]};	
						else 									r_shift_data[i] = r_shift_data[i-1];				
					end
	
				end
				else if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 2) begin

					always @(*) begin
						if(w_offset_per_cycle[i-1] == 1)		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};			
						else if(w_offset_per_cycle[i-1] == 2)	r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};		
						else if(w_offset_per_cycle[i-1] == 3)	r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};		
						else if(w_offset_per_cycle[i-1] == 4)	r_shift_data[i] = {r_shift_data[i-1][4*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:4*SHIFT_BITNUM*DATA_WIDTH]};		
						else if(w_offset_per_cycle[i-1] == 5)	r_shift_data[i] = {r_shift_data[i-1][5*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:5*SHIFT_BITNUM*DATA_WIDTH]};		
						else if(w_offset_per_cycle[i-1] == 6)	r_shift_data[i] = {r_shift_data[i-1][6*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:6*SHIFT_BITNUM*DATA_WIDTH]};		
						else if(w_offset_per_cycle[i-1] == 7)	r_shift_data[i] = {r_shift_data[i-1][7*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:7*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 8)	r_shift_data[i] = {r_shift_data[i-1][8*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:8*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 9)	r_shift_data[i] = {r_shift_data[i-1][9*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:9*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 10)	r_shift_data[i] = {r_shift_data[i-1][10*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:10*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 11)	r_shift_data[i] = {r_shift_data[i-1][11*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:11*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 12)	r_shift_data[i] = {r_shift_data[i-1][12*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:12*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 13)	r_shift_data[i] = {r_shift_data[i-1][13*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:13*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 14)	r_shift_data[i] = {r_shift_data[i-1][14*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:14*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 15)	r_shift_data[i] = {r_shift_data[i-1][15*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:15*SHIFT_BITNUM*DATA_WIDTH]};
						else 									r_shift_data[i] = r_shift_data[i-1];						
					end
	
				end
				else if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 1) begin
	
					always @(*) begin
						if(w_offset_per_cycle[i-1] == 1)		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 2)	r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 3)	r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 4)	r_shift_data[i] = {r_shift_data[i-1][4*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:4*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 5)	r_shift_data[i] = {r_shift_data[i-1][5*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:5*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 6)	r_shift_data[i] = {r_shift_data[i-1][6*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:6*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 7)	r_shift_data[i] = {r_shift_data[i-1][7*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:7*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 8)	r_shift_data[i] = {r_shift_data[i-1][8*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:8*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 9)	r_shift_data[i] = {r_shift_data[i-1][9*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:9*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 10)	r_shift_data[i] = {r_shift_data[i-1][10*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:10*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 11)	r_shift_data[i] = {r_shift_data[i-1][11*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:11*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 12)	r_shift_data[i] = {r_shift_data[i-1][12*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:12*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 13)	r_shift_data[i] = {r_shift_data[i-1][13*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:13*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 14)	r_shift_data[i] = {r_shift_data[i-1][14*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:14*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 15)	r_shift_data[i] = {r_shift_data[i-1][15*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:15*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 16)	r_shift_data[i] = {r_shift_data[i-1][16*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:16*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 17)	r_shift_data[i] = {r_shift_data[i-1][17*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:17*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 18)	r_shift_data[i] = {r_shift_data[i-1][18*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:18*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 19)	r_shift_data[i] = {r_shift_data[i-1][19*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:19*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 20)	r_shift_data[i] = {r_shift_data[i-1][20*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:20*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 21)	r_shift_data[i] = {r_shift_data[i-1][21*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:21*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 22)	r_shift_data[i] = {r_shift_data[i-1][22*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:22*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 23)	r_shift_data[i] = {r_shift_data[i-1][23*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:23*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 24)	r_shift_data[i] = {r_shift_data[i-1][24*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:24*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 25)	r_shift_data[i] = {r_shift_data[i-1][25*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:25*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 26)	r_shift_data[i] = {r_shift_data[i-1][26*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:26*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 27)	r_shift_data[i] = {r_shift_data[i-1][27*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:27*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 28)	r_shift_data[i] = {r_shift_data[i-1][28*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:28*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 29)	r_shift_data[i] = {r_shift_data[i-1][29*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:29*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 30)	r_shift_data[i] = {r_shift_data[i-1][30*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:30*SHIFT_BITNUM*DATA_WIDTH]};
						else if(w_offset_per_cycle[i-1] == 31)	r_shift_data[i] = {r_shift_data[i-1][31*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:31*SHIFT_BITNUM*DATA_WIDTH]};
						else 									r_shift_data[i] = r_shift_data[i-1];
					end
	
				end
			end
			else begin
				
				always @(*) begin
					if(w_offset_per_cycle[i-1] == 1)		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 2)	r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 3)	r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 4)	r_shift_data[i] = {r_shift_data[i-1][4*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:4*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 5)	r_shift_data[i] = {r_shift_data[i-1][5*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:5*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 6)	r_shift_data[i] = {r_shift_data[i-1][6*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:6*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 7)	r_shift_data[i] = {r_shift_data[i-1][7*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:7*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 8)	r_shift_data[i] = {r_shift_data[i-1][8*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:8*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 9)	r_shift_data[i] = {r_shift_data[i-1][9*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:9*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 10)	r_shift_data[i] = {r_shift_data[i-1][10*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:10*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 11)	r_shift_data[i] = {r_shift_data[i-1][11*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:11*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 12)	r_shift_data[i] = {r_shift_data[i-1][12*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:12*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 13)	r_shift_data[i] = {r_shift_data[i-1][13*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:13*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 14)	r_shift_data[i] = {r_shift_data[i-1][14*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:14*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 15)	r_shift_data[i] = {r_shift_data[i-1][15*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:15*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 16)	r_shift_data[i] = {r_shift_data[i-1][16*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:16*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 17)	r_shift_data[i] = {r_shift_data[i-1][17*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:17*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 18)	r_shift_data[i] = {r_shift_data[i-1][18*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:18*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 19)	r_shift_data[i] = {r_shift_data[i-1][19*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:19*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 20)	r_shift_data[i] = {r_shift_data[i-1][20*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:20*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 21)	r_shift_data[i] = {r_shift_data[i-1][21*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:21*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 22)	r_shift_data[i] = {r_shift_data[i-1][22*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:22*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 23)	r_shift_data[i] = {r_shift_data[i-1][23*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:23*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 24)	r_shift_data[i] = {r_shift_data[i-1][24*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:24*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 25)	r_shift_data[i] = {r_shift_data[i-1][25*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:25*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 26)	r_shift_data[i] = {r_shift_data[i-1][26*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:26*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 27)	r_shift_data[i] = {r_shift_data[i-1][27*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:27*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 28)	r_shift_data[i] = {r_shift_data[i-1][28*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:28*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 29)	r_shift_data[i] = {r_shift_data[i-1][29*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:29*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 30)	r_shift_data[i] = {r_shift_data[i-1][30*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:30*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 31)	r_shift_data[i] = {r_shift_data[i-1][31*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:31*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 32)	r_shift_data[i] = {r_shift_data[i-1][32*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:32*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 33)	r_shift_data[i] = {r_shift_data[i-1][33*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:33*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 34)	r_shift_data[i] = {r_shift_data[i-1][34*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:34*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 35)	r_shift_data[i] = {r_shift_data[i-1][35*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:35*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 36)	r_shift_data[i] = {r_shift_data[i-1][36*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:36*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 37)	r_shift_data[i] = {r_shift_data[i-1][37*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:37*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 38)	r_shift_data[i] = {r_shift_data[i-1][38*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:38*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 39)	r_shift_data[i] = {r_shift_data[i-1][39*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:39*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 40)	r_shift_data[i] = {r_shift_data[i-1][40*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:40*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 41)	r_shift_data[i] = {r_shift_data[i-1][41*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:41*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 42)	r_shift_data[i] = {r_shift_data[i-1][42*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:42*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 43)	r_shift_data[i] = {r_shift_data[i-1][43*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:43*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 44)	r_shift_data[i] = {r_shift_data[i-1][44*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:44*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 45)	r_shift_data[i] = {r_shift_data[i-1][45*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:45*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 46)	r_shift_data[i] = {r_shift_data[i-1][46*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:46*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 47)	r_shift_data[i] = {r_shift_data[i-1][47*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:47*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 48)	r_shift_data[i] = {r_shift_data[i-1][48*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:48*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 49)	r_shift_data[i] = {r_shift_data[i-1][49*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:49*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 50)	r_shift_data[i] = {r_shift_data[i-1][50*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:50*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 51)	r_shift_data[i] = {r_shift_data[i-1][51*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:51*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 52)	r_shift_data[i] = {r_shift_data[i-1][52*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:52*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 53)	r_shift_data[i] = {r_shift_data[i-1][53*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:53*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 54)	r_shift_data[i] = {r_shift_data[i-1][54*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:54*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 55)	r_shift_data[i] = {r_shift_data[i-1][55*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:55*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 56)	r_shift_data[i] = {r_shift_data[i-1][56*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:56*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 57)	r_shift_data[i] = {r_shift_data[i-1][57*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:57*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 58)	r_shift_data[i] = {r_shift_data[i-1][58*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:58*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 59)	r_shift_data[i] = {r_shift_data[i-1][59*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:59*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 60)	r_shift_data[i] = {r_shift_data[i-1][60*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:60*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 61)	r_shift_data[i] = {r_shift_data[i-1][61*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:61*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 62)	r_shift_data[i] = {r_shift_data[i-1][62*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:62*SHIFT_BITNUM*DATA_WIDTH]};
					else if(w_offset_per_cycle[i-1] == 63)	r_shift_data[i] = {r_shift_data[i-1][63*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:63*SHIFT_BITNUM*DATA_WIDTH]};
					else 									r_shift_data[i] = r_shift_data[i-1];					
				end

			end
		end
	end
endgenerate

// -------------------------^ 每次处理 6 bit ^-------------------------

// ------------------------->> 每次处理 8 bit>> ------------------------
generate
	if(SHIFT_STEP == 8) begin
		
		for(i = 1; i <= SHIFT_CYCLE; i = i + 1) begin: shift_data_assign

			// 每次的单位步长为 (2^SHIFT_STEP)^(i-1)
			localparam SHIFT_BITNUM = (1 << (SHIFT_STEP*(i-1)));

			if((i == SHIFT_CYCLE)&&(SHIFT_CYCLE * SHIFT_STEP != SHIFT_OFFSET_WIDTH)) begin
				if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 7) begin

					always @(*) begin case(w_offset_per_cycle[i-1])
						8'd1:		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
						default:	r_shift_data[i] = r_shift_data[i-1];
						endcase
					end
				end
				else if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 6) begin
				
					always @(*) begin case(w_offset_per_cycle[i-1])
						8'd1:		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
						8'd2:		r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
						8'd3:		r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
						default:	r_shift_data[i] = r_shift_data[i-1];
						endcase
					end
				end
				else if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 5) begin
				
					always @(*) begin case(w_offset_per_cycle[i-1])
						8'd1:		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
						8'd2:		r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
						8'd3:		r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
						8'd4:		r_shift_data[i] = {r_shift_data[i-1][4*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:4*SHIFT_BITNUM*DATA_WIDTH]};
						8'd5:		r_shift_data[i] = {r_shift_data[i-1][5*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:5*SHIFT_BITNUM*DATA_WIDTH]};
						8'd6:		r_shift_data[i] = {r_shift_data[i-1][6*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:6*SHIFT_BITNUM*DATA_WIDTH]};
						8'd7:		r_shift_data[i] = {r_shift_data[i-1][7*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:7*SHIFT_BITNUM*DATA_WIDTH]};
						default:	r_shift_data[i] = r_shift_data[i-1];
						endcase
					end
				end
				else if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 4) begin
				
					always @(*) begin case(w_offset_per_cycle[i-1])
						8'd1:		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
						8'd2:		r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
						8'd3:		r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
						8'd4:		r_shift_data[i] = {r_shift_data[i-1][4*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:4*SHIFT_BITNUM*DATA_WIDTH]};
						8'd5:		r_shift_data[i] = {r_shift_data[i-1][5*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:5*SHIFT_BITNUM*DATA_WIDTH]};
						8'd6:		r_shift_data[i] = {r_shift_data[i-1][6*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:6*SHIFT_BITNUM*DATA_WIDTH]};
						8'd7:		r_shift_data[i] = {r_shift_data[i-1][7*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:7*SHIFT_BITNUM*DATA_WIDTH]};
						8'd8:		r_shift_data[i] = {r_shift_data[i-1][8*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:8*SHIFT_BITNUM*DATA_WIDTH]};
						8'd9:		r_shift_data[i] = {r_shift_data[i-1][9*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:9*SHIFT_BITNUM*DATA_WIDTH]};
						8'd10:		r_shift_data[i] = {r_shift_data[i-1][10*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:10*SHIFT_BITNUM*DATA_WIDTH]};
						8'd11:		r_shift_data[i] = {r_shift_data[i-1][11*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:11*SHIFT_BITNUM*DATA_WIDTH]};
						8'd12:		r_shift_data[i] = {r_shift_data[i-1][12*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:12*SHIFT_BITNUM*DATA_WIDTH]};
						8'd13:		r_shift_data[i] = {r_shift_data[i-1][13*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:13*SHIFT_BITNUM*DATA_WIDTH]};
						8'd14:		r_shift_data[i] = {r_shift_data[i-1][14*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:14*SHIFT_BITNUM*DATA_WIDTH]};
						8'd15:		r_shift_data[i] = {r_shift_data[i-1][15*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:15*SHIFT_BITNUM*DATA_WIDTH]};
						default:	r_shift_data[i] = r_shift_data[i-1];
						endcase
					end
				end
				else if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 3) begin
				
					always @(*) begin case(w_offset_per_cycle[i-1])
						8'd1:		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
						8'd2:		r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
						8'd3:		r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
						8'd4:		r_shift_data[i] = {r_shift_data[i-1][4*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:4*SHIFT_BITNUM*DATA_WIDTH]};
						8'd5:		r_shift_data[i] = {r_shift_data[i-1][5*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:5*SHIFT_BITNUM*DATA_WIDTH]};
						8'd6:		r_shift_data[i] = {r_shift_data[i-1][6*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:6*SHIFT_BITNUM*DATA_WIDTH]};
						8'd7:		r_shift_data[i] = {r_shift_data[i-1][7*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:7*SHIFT_BITNUM*DATA_WIDTH]};
						8'd8:		r_shift_data[i] = {r_shift_data[i-1][8*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:8*SHIFT_BITNUM*DATA_WIDTH]};
						8'd9:		r_shift_data[i] = {r_shift_data[i-1][9*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:9*SHIFT_BITNUM*DATA_WIDTH]};
						8'd10:		r_shift_data[i] = {r_shift_data[i-1][10*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:10*SHIFT_BITNUM*DATA_WIDTH]};
						8'd11:		r_shift_data[i] = {r_shift_data[i-1][11*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:11*SHIFT_BITNUM*DATA_WIDTH]};
						8'd12:		r_shift_data[i] = {r_shift_data[i-1][12*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:12*SHIFT_BITNUM*DATA_WIDTH]};
						8'd13:		r_shift_data[i] = {r_shift_data[i-1][13*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:13*SHIFT_BITNUM*DATA_WIDTH]};
						8'd14:		r_shift_data[i] = {r_shift_data[i-1][14*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:14*SHIFT_BITNUM*DATA_WIDTH]};
						8'd15:		r_shift_data[i] = {r_shift_data[i-1][15*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:15*SHIFT_BITNUM*DATA_WIDTH]};
						8'd16:		r_shift_data[i] = {r_shift_data[i-1][16*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:16*SHIFT_BITNUM*DATA_WIDTH]};
						8'd17:		r_shift_data[i] = {r_shift_data[i-1][17*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:17*SHIFT_BITNUM*DATA_WIDTH]};
						8'd18:		r_shift_data[i] = {r_shift_data[i-1][18*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:18*SHIFT_BITNUM*DATA_WIDTH]};
						8'd19:		r_shift_data[i] = {r_shift_data[i-1][19*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:19*SHIFT_BITNUM*DATA_WIDTH]};
						8'd20:		r_shift_data[i] = {r_shift_data[i-1][20*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:20*SHIFT_BITNUM*DATA_WIDTH]};
						8'd21:		r_shift_data[i] = {r_shift_data[i-1][21*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:21*SHIFT_BITNUM*DATA_WIDTH]};
						8'd22:		r_shift_data[i] = {r_shift_data[i-1][22*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:22*SHIFT_BITNUM*DATA_WIDTH]};
						8'd23:		r_shift_data[i] = {r_shift_data[i-1][23*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:23*SHIFT_BITNUM*DATA_WIDTH]};
						8'd24:		r_shift_data[i] = {r_shift_data[i-1][24*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:24*SHIFT_BITNUM*DATA_WIDTH]};
						8'd25:		r_shift_data[i] = {r_shift_data[i-1][25*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:25*SHIFT_BITNUM*DATA_WIDTH]};
						8'd26:		r_shift_data[i] = {r_shift_data[i-1][26*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:26*SHIFT_BITNUM*DATA_WIDTH]};
						8'd27:		r_shift_data[i] = {r_shift_data[i-1][27*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:27*SHIFT_BITNUM*DATA_WIDTH]};
						8'd28:		r_shift_data[i] = {r_shift_data[i-1][28*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:28*SHIFT_BITNUM*DATA_WIDTH]};
						8'd29:		r_shift_data[i] = {r_shift_data[i-1][29*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:29*SHIFT_BITNUM*DATA_WIDTH]};
						8'd30:		r_shift_data[i] = {r_shift_data[i-1][30*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:30*SHIFT_BITNUM*DATA_WIDTH]};
						8'd31:		r_shift_data[i] = {r_shift_data[i-1][31*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:31*SHIFT_BITNUM*DATA_WIDTH]};
						default:	r_shift_data[i] = r_shift_data[i-1];
						endcase
					end
				end
				else if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 2) begin
				
					always @(*) begin case(w_offset_per_cycle[i-1])
						8'd1:		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
						8'd2:		r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
						8'd3:		r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
						8'd4:		r_shift_data[i] = {r_shift_data[i-1][4*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:4*SHIFT_BITNUM*DATA_WIDTH]};
						8'd5:		r_shift_data[i] = {r_shift_data[i-1][5*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:5*SHIFT_BITNUM*DATA_WIDTH]};
						8'd6:		r_shift_data[i] = {r_shift_data[i-1][6*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:6*SHIFT_BITNUM*DATA_WIDTH]};
						8'd7:		r_shift_data[i] = {r_shift_data[i-1][7*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:7*SHIFT_BITNUM*DATA_WIDTH]};
						8'd8:		r_shift_data[i] = {r_shift_data[i-1][8*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:8*SHIFT_BITNUM*DATA_WIDTH]};
						8'd9:		r_shift_data[i] = {r_shift_data[i-1][9*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:9*SHIFT_BITNUM*DATA_WIDTH]};
						8'd10:		r_shift_data[i] = {r_shift_data[i-1][10*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:10*SHIFT_BITNUM*DATA_WIDTH]};
						8'd11:		r_shift_data[i] = {r_shift_data[i-1][11*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:11*SHIFT_BITNUM*DATA_WIDTH]};
						8'd12:		r_shift_data[i] = {r_shift_data[i-1][12*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:12*SHIFT_BITNUM*DATA_WIDTH]};
						8'd13:		r_shift_data[i] = {r_shift_data[i-1][13*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:13*SHIFT_BITNUM*DATA_WIDTH]};
						8'd14:		r_shift_data[i] = {r_shift_data[i-1][14*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:14*SHIFT_BITNUM*DATA_WIDTH]};
						8'd15:		r_shift_data[i] = {r_shift_data[i-1][15*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:15*SHIFT_BITNUM*DATA_WIDTH]};
						8'd16:		r_shift_data[i] = {r_shift_data[i-1][16*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:16*SHIFT_BITNUM*DATA_WIDTH]};
						8'd17:		r_shift_data[i] = {r_shift_data[i-1][17*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:17*SHIFT_BITNUM*DATA_WIDTH]};
						8'd18:		r_shift_data[i] = {r_shift_data[i-1][18*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:18*SHIFT_BITNUM*DATA_WIDTH]};
						8'd19:		r_shift_data[i] = {r_shift_data[i-1][19*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:19*SHIFT_BITNUM*DATA_WIDTH]};
						8'd20:		r_shift_data[i] = {r_shift_data[i-1][20*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:20*SHIFT_BITNUM*DATA_WIDTH]};
						8'd21:		r_shift_data[i] = {r_shift_data[i-1][21*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:21*SHIFT_BITNUM*DATA_WIDTH]};
						8'd22:		r_shift_data[i] = {r_shift_data[i-1][22*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:22*SHIFT_BITNUM*DATA_WIDTH]};
						8'd23:		r_shift_data[i] = {r_shift_data[i-1][23*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:23*SHIFT_BITNUM*DATA_WIDTH]};
						8'd24:		r_shift_data[i] = {r_shift_data[i-1][24*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:24*SHIFT_BITNUM*DATA_WIDTH]};
						8'd25:		r_shift_data[i] = {r_shift_data[i-1][25*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:25*SHIFT_BITNUM*DATA_WIDTH]};
						8'd26:		r_shift_data[i] = {r_shift_data[i-1][26*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:26*SHIFT_BITNUM*DATA_WIDTH]};
						8'd27:		r_shift_data[i] = {r_shift_data[i-1][27*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:27*SHIFT_BITNUM*DATA_WIDTH]};
						8'd28:		r_shift_data[i] = {r_shift_data[i-1][28*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:28*SHIFT_BITNUM*DATA_WIDTH]};
						8'd29:		r_shift_data[i] = {r_shift_data[i-1][29*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:29*SHIFT_BITNUM*DATA_WIDTH]};
						8'd30:		r_shift_data[i] = {r_shift_data[i-1][30*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:30*SHIFT_BITNUM*DATA_WIDTH]};
						8'd31:		r_shift_data[i] = {r_shift_data[i-1][31*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:31*SHIFT_BITNUM*DATA_WIDTH]};
						8'd32:		r_shift_data[i] = {r_shift_data[i-1][32*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:32*SHIFT_BITNUM*DATA_WIDTH]};
						8'd33:		r_shift_data[i] = {r_shift_data[i-1][33*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:33*SHIFT_BITNUM*DATA_WIDTH]};
						8'd34:		r_shift_data[i] = {r_shift_data[i-1][34*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:34*SHIFT_BITNUM*DATA_WIDTH]};
						8'd35:		r_shift_data[i] = {r_shift_data[i-1][35*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:35*SHIFT_BITNUM*DATA_WIDTH]};
						8'd36:		r_shift_data[i] = {r_shift_data[i-1][36*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:36*SHIFT_BITNUM*DATA_WIDTH]};
						8'd37:		r_shift_data[i] = {r_shift_data[i-1][37*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:37*SHIFT_BITNUM*DATA_WIDTH]};
						8'd38:		r_shift_data[i] = {r_shift_data[i-1][38*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:38*SHIFT_BITNUM*DATA_WIDTH]};
						8'd39:		r_shift_data[i] = {r_shift_data[i-1][39*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:39*SHIFT_BITNUM*DATA_WIDTH]};
						8'd40:		r_shift_data[i] = {r_shift_data[i-1][40*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:40*SHIFT_BITNUM*DATA_WIDTH]};
						8'd41:		r_shift_data[i] = {r_shift_data[i-1][41*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:41*SHIFT_BITNUM*DATA_WIDTH]};
						8'd42:		r_shift_data[i] = {r_shift_data[i-1][42*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:42*SHIFT_BITNUM*DATA_WIDTH]};
						8'd43:		r_shift_data[i] = {r_shift_data[i-1][43*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:43*SHIFT_BITNUM*DATA_WIDTH]};
						8'd44:		r_shift_data[i] = {r_shift_data[i-1][44*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:44*SHIFT_BITNUM*DATA_WIDTH]};
						8'd45:		r_shift_data[i] = {r_shift_data[i-1][45*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:45*SHIFT_BITNUM*DATA_WIDTH]};
						8'd46:		r_shift_data[i] = {r_shift_data[i-1][46*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:46*SHIFT_BITNUM*DATA_WIDTH]};
						8'd47:		r_shift_data[i] = {r_shift_data[i-1][47*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:47*SHIFT_BITNUM*DATA_WIDTH]};
						8'd48:		r_shift_data[i] = {r_shift_data[i-1][48*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:48*SHIFT_BITNUM*DATA_WIDTH]};
						8'd49:		r_shift_data[i] = {r_shift_data[i-1][49*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:49*SHIFT_BITNUM*DATA_WIDTH]};
						8'd50:		r_shift_data[i] = {r_shift_data[i-1][50*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:50*SHIFT_BITNUM*DATA_WIDTH]};
						8'd51:		r_shift_data[i] = {r_shift_data[i-1][51*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:51*SHIFT_BITNUM*DATA_WIDTH]};
						8'd52:		r_shift_data[i] = {r_shift_data[i-1][52*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:52*SHIFT_BITNUM*DATA_WIDTH]};
						8'd53:		r_shift_data[i] = {r_shift_data[i-1][53*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:53*SHIFT_BITNUM*DATA_WIDTH]};
						8'd54:		r_shift_data[i] = {r_shift_data[i-1][54*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:54*SHIFT_BITNUM*DATA_WIDTH]};
						8'd55:		r_shift_data[i] = {r_shift_data[i-1][55*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:55*SHIFT_BITNUM*DATA_WIDTH]};
						8'd56:		r_shift_data[i] = {r_shift_data[i-1][56*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:56*SHIFT_BITNUM*DATA_WIDTH]};
						8'd57:		r_shift_data[i] = {r_shift_data[i-1][57*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:57*SHIFT_BITNUM*DATA_WIDTH]};
						8'd58:		r_shift_data[i] = {r_shift_data[i-1][58*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:58*SHIFT_BITNUM*DATA_WIDTH]};
						8'd59:		r_shift_data[i] = {r_shift_data[i-1][59*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:59*SHIFT_BITNUM*DATA_WIDTH]};
						8'd60:		r_shift_data[i] = {r_shift_data[i-1][60*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:60*SHIFT_BITNUM*DATA_WIDTH]};
						8'd61:		r_shift_data[i] = {r_shift_data[i-1][61*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:61*SHIFT_BITNUM*DATA_WIDTH]};
						8'd62:		r_shift_data[i] = {r_shift_data[i-1][62*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:62*SHIFT_BITNUM*DATA_WIDTH]};
						8'd63:		r_shift_data[i] = {r_shift_data[i-1][63*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:63*SHIFT_BITNUM*DATA_WIDTH]};
						default:	r_shift_data[i] = r_shift_data[i-1];
						endcase
					end
				end
				else if(SHIFT_CYCLE * SHIFT_STEP - SHIFT_OFFSET_WIDTH == 1) begin
				
					always @(*) begin case(w_offset_per_cycle[i-1])
						8'd1:		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
						8'd2:		r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
						8'd3:		r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
						8'd4:		r_shift_data[i] = {r_shift_data[i-1][4*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:4*SHIFT_BITNUM*DATA_WIDTH]};
						8'd5:		r_shift_data[i] = {r_shift_data[i-1][5*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:5*SHIFT_BITNUM*DATA_WIDTH]};
						8'd6:		r_shift_data[i] = {r_shift_data[i-1][6*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:6*SHIFT_BITNUM*DATA_WIDTH]};
						8'd7:		r_shift_data[i] = {r_shift_data[i-1][7*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:7*SHIFT_BITNUM*DATA_WIDTH]};
						8'd8:		r_shift_data[i] = {r_shift_data[i-1][8*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:8*SHIFT_BITNUM*DATA_WIDTH]};
						8'd9:		r_shift_data[i] = {r_shift_data[i-1][9*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:9*SHIFT_BITNUM*DATA_WIDTH]};
						8'd10:		r_shift_data[i] = {r_shift_data[i-1][10*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:10*SHIFT_BITNUM*DATA_WIDTH]};
						8'd11:		r_shift_data[i] = {r_shift_data[i-1][11*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:11*SHIFT_BITNUM*DATA_WIDTH]};
						8'd12:		r_shift_data[i] = {r_shift_data[i-1][12*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:12*SHIFT_BITNUM*DATA_WIDTH]};
						8'd13:		r_shift_data[i] = {r_shift_data[i-1][13*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:13*SHIFT_BITNUM*DATA_WIDTH]};
						8'd14:		r_shift_data[i] = {r_shift_data[i-1][14*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:14*SHIFT_BITNUM*DATA_WIDTH]};
						8'd15:		r_shift_data[i] = {r_shift_data[i-1][15*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:15*SHIFT_BITNUM*DATA_WIDTH]};
						8'd16:		r_shift_data[i] = {r_shift_data[i-1][16*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:16*SHIFT_BITNUM*DATA_WIDTH]};
						8'd17:		r_shift_data[i] = {r_shift_data[i-1][17*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:17*SHIFT_BITNUM*DATA_WIDTH]};
						8'd18:		r_shift_data[i] = {r_shift_data[i-1][18*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:18*SHIFT_BITNUM*DATA_WIDTH]};
						8'd19:		r_shift_data[i] = {r_shift_data[i-1][19*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:19*SHIFT_BITNUM*DATA_WIDTH]};
						8'd20:		r_shift_data[i] = {r_shift_data[i-1][20*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:20*SHIFT_BITNUM*DATA_WIDTH]};
						8'd21:		r_shift_data[i] = {r_shift_data[i-1][21*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:21*SHIFT_BITNUM*DATA_WIDTH]};
						8'd22:		r_shift_data[i] = {r_shift_data[i-1][22*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:22*SHIFT_BITNUM*DATA_WIDTH]};
						8'd23:		r_shift_data[i] = {r_shift_data[i-1][23*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:23*SHIFT_BITNUM*DATA_WIDTH]};
						8'd24:		r_shift_data[i] = {r_shift_data[i-1][24*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:24*SHIFT_BITNUM*DATA_WIDTH]};
						8'd25:		r_shift_data[i] = {r_shift_data[i-1][25*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:25*SHIFT_BITNUM*DATA_WIDTH]};
						8'd26:		r_shift_data[i] = {r_shift_data[i-1][26*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:26*SHIFT_BITNUM*DATA_WIDTH]};
						8'd27:		r_shift_data[i] = {r_shift_data[i-1][27*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:27*SHIFT_BITNUM*DATA_WIDTH]};
						8'd28:		r_shift_data[i] = {r_shift_data[i-1][28*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:28*SHIFT_BITNUM*DATA_WIDTH]};
						8'd29:		r_shift_data[i] = {r_shift_data[i-1][29*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:29*SHIFT_BITNUM*DATA_WIDTH]};
						8'd30:		r_shift_data[i] = {r_shift_data[i-1][30*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:30*SHIFT_BITNUM*DATA_WIDTH]};
						8'd31:		r_shift_data[i] = {r_shift_data[i-1][31*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:31*SHIFT_BITNUM*DATA_WIDTH]};
						8'd32:		r_shift_data[i] = {r_shift_data[i-1][32*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:32*SHIFT_BITNUM*DATA_WIDTH]};
						8'd33:		r_shift_data[i] = {r_shift_data[i-1][33*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:33*SHIFT_BITNUM*DATA_WIDTH]};
						8'd34:		r_shift_data[i] = {r_shift_data[i-1][34*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:34*SHIFT_BITNUM*DATA_WIDTH]};
						8'd35:		r_shift_data[i] = {r_shift_data[i-1][35*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:35*SHIFT_BITNUM*DATA_WIDTH]};
						8'd36:		r_shift_data[i] = {r_shift_data[i-1][36*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:36*SHIFT_BITNUM*DATA_WIDTH]};
						8'd37:		r_shift_data[i] = {r_shift_data[i-1][37*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:37*SHIFT_BITNUM*DATA_WIDTH]};
						8'd38:		r_shift_data[i] = {r_shift_data[i-1][38*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:38*SHIFT_BITNUM*DATA_WIDTH]};
						8'd39:		r_shift_data[i] = {r_shift_data[i-1][39*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:39*SHIFT_BITNUM*DATA_WIDTH]};
						8'd40:		r_shift_data[i] = {r_shift_data[i-1][40*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:40*SHIFT_BITNUM*DATA_WIDTH]};
						8'd41:		r_shift_data[i] = {r_shift_data[i-1][41*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:41*SHIFT_BITNUM*DATA_WIDTH]};
						8'd42:		r_shift_data[i] = {r_shift_data[i-1][42*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:42*SHIFT_BITNUM*DATA_WIDTH]};
						8'd43:		r_shift_data[i] = {r_shift_data[i-1][43*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:43*SHIFT_BITNUM*DATA_WIDTH]};
						8'd44:		r_shift_data[i] = {r_shift_data[i-1][44*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:44*SHIFT_BITNUM*DATA_WIDTH]};
						8'd45:		r_shift_data[i] = {r_shift_data[i-1][45*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:45*SHIFT_BITNUM*DATA_WIDTH]};
						8'd46:		r_shift_data[i] = {r_shift_data[i-1][46*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:46*SHIFT_BITNUM*DATA_WIDTH]};
						8'd47:		r_shift_data[i] = {r_shift_data[i-1][47*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:47*SHIFT_BITNUM*DATA_WIDTH]};
						8'd48:		r_shift_data[i] = {r_shift_data[i-1][48*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:48*SHIFT_BITNUM*DATA_WIDTH]};
						8'd49:		r_shift_data[i] = {r_shift_data[i-1][49*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:49*SHIFT_BITNUM*DATA_WIDTH]};
						8'd50:		r_shift_data[i] = {r_shift_data[i-1][50*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:50*SHIFT_BITNUM*DATA_WIDTH]};
						8'd51:		r_shift_data[i] = {r_shift_data[i-1][51*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:51*SHIFT_BITNUM*DATA_WIDTH]};
						8'd52:		r_shift_data[i] = {r_shift_data[i-1][52*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:52*SHIFT_BITNUM*DATA_WIDTH]};
						8'd53:		r_shift_data[i] = {r_shift_data[i-1][53*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:53*SHIFT_BITNUM*DATA_WIDTH]};
						8'd54:		r_shift_data[i] = {r_shift_data[i-1][54*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:54*SHIFT_BITNUM*DATA_WIDTH]};
						8'd55:		r_shift_data[i] = {r_shift_data[i-1][55*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:55*SHIFT_BITNUM*DATA_WIDTH]};
						8'd56:		r_shift_data[i] = {r_shift_data[i-1][56*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:56*SHIFT_BITNUM*DATA_WIDTH]};
						8'd57:		r_shift_data[i] = {r_shift_data[i-1][57*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:57*SHIFT_BITNUM*DATA_WIDTH]};
						8'd58:		r_shift_data[i] = {r_shift_data[i-1][58*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:58*SHIFT_BITNUM*DATA_WIDTH]};
						8'd59:		r_shift_data[i] = {r_shift_data[i-1][59*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:59*SHIFT_BITNUM*DATA_WIDTH]};
						8'd60:		r_shift_data[i] = {r_shift_data[i-1][60*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:60*SHIFT_BITNUM*DATA_WIDTH]};
						8'd61:		r_shift_data[i] = {r_shift_data[i-1][61*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:61*SHIFT_BITNUM*DATA_WIDTH]};
						8'd62:		r_shift_data[i] = {r_shift_data[i-1][62*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:62*SHIFT_BITNUM*DATA_WIDTH]};
						8'd63:		r_shift_data[i] = {r_shift_data[i-1][63*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:63*SHIFT_BITNUM*DATA_WIDTH]};
						8'd64:		r_shift_data[i] = {r_shift_data[i-1][64*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:64*SHIFT_BITNUM*DATA_WIDTH]};
						8'd65:		r_shift_data[i] = {r_shift_data[i-1][65*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:65*SHIFT_BITNUM*DATA_WIDTH]};
						8'd66:		r_shift_data[i] = {r_shift_data[i-1][66*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:66*SHIFT_BITNUM*DATA_WIDTH]};
						8'd67:		r_shift_data[i] = {r_shift_data[i-1][67*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:67*SHIFT_BITNUM*DATA_WIDTH]};
						8'd68:		r_shift_data[i] = {r_shift_data[i-1][68*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:68*SHIFT_BITNUM*DATA_WIDTH]};
						8'd69:		r_shift_data[i] = {r_shift_data[i-1][69*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:69*SHIFT_BITNUM*DATA_WIDTH]};
						8'd70:		r_shift_data[i] = {r_shift_data[i-1][70*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:70*SHIFT_BITNUM*DATA_WIDTH]};
						8'd71:		r_shift_data[i] = {r_shift_data[i-1][71*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:71*SHIFT_BITNUM*DATA_WIDTH]};
						8'd72:		r_shift_data[i] = {r_shift_data[i-1][72*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:72*SHIFT_BITNUM*DATA_WIDTH]};
						8'd73:		r_shift_data[i] = {r_shift_data[i-1][73*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:73*SHIFT_BITNUM*DATA_WIDTH]};
						8'd74:		r_shift_data[i] = {r_shift_data[i-1][74*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:74*SHIFT_BITNUM*DATA_WIDTH]};
						8'd75:		r_shift_data[i] = {r_shift_data[i-1][75*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:75*SHIFT_BITNUM*DATA_WIDTH]};
						8'd76:		r_shift_data[i] = {r_shift_data[i-1][76*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:76*SHIFT_BITNUM*DATA_WIDTH]};
						8'd77:		r_shift_data[i] = {r_shift_data[i-1][77*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:77*SHIFT_BITNUM*DATA_WIDTH]};
						8'd78:		r_shift_data[i] = {r_shift_data[i-1][78*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:78*SHIFT_BITNUM*DATA_WIDTH]};
						8'd79:		r_shift_data[i] = {r_shift_data[i-1][79*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:79*SHIFT_BITNUM*DATA_WIDTH]};
						8'd80:		r_shift_data[i] = {r_shift_data[i-1][80*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:80*SHIFT_BITNUM*DATA_WIDTH]};
						8'd81:		r_shift_data[i] = {r_shift_data[i-1][81*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:81*SHIFT_BITNUM*DATA_WIDTH]};
						8'd82:		r_shift_data[i] = {r_shift_data[i-1][82*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:82*SHIFT_BITNUM*DATA_WIDTH]};
						8'd83:		r_shift_data[i] = {r_shift_data[i-1][83*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:83*SHIFT_BITNUM*DATA_WIDTH]};
						8'd84:		r_shift_data[i] = {r_shift_data[i-1][84*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:84*SHIFT_BITNUM*DATA_WIDTH]};
						8'd85:		r_shift_data[i] = {r_shift_data[i-1][85*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:85*SHIFT_BITNUM*DATA_WIDTH]};
						8'd86:		r_shift_data[i] = {r_shift_data[i-1][86*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:86*SHIFT_BITNUM*DATA_WIDTH]};
						8'd87:		r_shift_data[i] = {r_shift_data[i-1][87*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:87*SHIFT_BITNUM*DATA_WIDTH]};
						8'd88:		r_shift_data[i] = {r_shift_data[i-1][88*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:88*SHIFT_BITNUM*DATA_WIDTH]};
						8'd89:		r_shift_data[i] = {r_shift_data[i-1][89*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:89*SHIFT_BITNUM*DATA_WIDTH]};
						8'd90:		r_shift_data[i] = {r_shift_data[i-1][90*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:90*SHIFT_BITNUM*DATA_WIDTH]};
						8'd91:		r_shift_data[i] = {r_shift_data[i-1][91*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:91*SHIFT_BITNUM*DATA_WIDTH]};
						8'd92:		r_shift_data[i] = {r_shift_data[i-1][92*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:92*SHIFT_BITNUM*DATA_WIDTH]};
						8'd93:		r_shift_data[i] = {r_shift_data[i-1][93*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:93*SHIFT_BITNUM*DATA_WIDTH]};
						8'd94:		r_shift_data[i] = {r_shift_data[i-1][94*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:94*SHIFT_BITNUM*DATA_WIDTH]};
						8'd95:		r_shift_data[i] = {r_shift_data[i-1][95*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:95*SHIFT_BITNUM*DATA_WIDTH]};
						8'd96:		r_shift_data[i] = {r_shift_data[i-1][96*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:96*SHIFT_BITNUM*DATA_WIDTH]};
						8'd97:		r_shift_data[i] = {r_shift_data[i-1][97*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:97*SHIFT_BITNUM*DATA_WIDTH]};
						8'd98:		r_shift_data[i] = {r_shift_data[i-1][98*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:98*SHIFT_BITNUM*DATA_WIDTH]};
						8'd99:		r_shift_data[i] = {r_shift_data[i-1][99*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:99*SHIFT_BITNUM*DATA_WIDTH]};
						8'd100:		r_shift_data[i] = {r_shift_data[i-1][100*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:100*SHIFT_BITNUM*DATA_WIDTH]};
						8'd101:		r_shift_data[i] = {r_shift_data[i-1][101*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:101*SHIFT_BITNUM*DATA_WIDTH]};
						8'd102:		r_shift_data[i] = {r_shift_data[i-1][102*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:102*SHIFT_BITNUM*DATA_WIDTH]};
						8'd103:		r_shift_data[i] = {r_shift_data[i-1][103*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:103*SHIFT_BITNUM*DATA_WIDTH]};
						8'd104:		r_shift_data[i] = {r_shift_data[i-1][104*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:104*SHIFT_BITNUM*DATA_WIDTH]};
						8'd105:		r_shift_data[i] = {r_shift_data[i-1][105*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:105*SHIFT_BITNUM*DATA_WIDTH]};
						8'd106:		r_shift_data[i] = {r_shift_data[i-1][106*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:106*SHIFT_BITNUM*DATA_WIDTH]};
						8'd107:		r_shift_data[i] = {r_shift_data[i-1][107*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:107*SHIFT_BITNUM*DATA_WIDTH]};
						8'd108:		r_shift_data[i] = {r_shift_data[i-1][108*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:108*SHIFT_BITNUM*DATA_WIDTH]};
						8'd109:		r_shift_data[i] = {r_shift_data[i-1][109*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:109*SHIFT_BITNUM*DATA_WIDTH]};
						8'd110:		r_shift_data[i] = {r_shift_data[i-1][110*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:110*SHIFT_BITNUM*DATA_WIDTH]};
						8'd111:		r_shift_data[i] = {r_shift_data[i-1][111*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:111*SHIFT_BITNUM*DATA_WIDTH]};
						8'd112:		r_shift_data[i] = {r_shift_data[i-1][112*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:112*SHIFT_BITNUM*DATA_WIDTH]};
						8'd113:		r_shift_data[i] = {r_shift_data[i-1][113*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:113*SHIFT_BITNUM*DATA_WIDTH]};
						8'd114:		r_shift_data[i] = {r_shift_data[i-1][114*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:114*SHIFT_BITNUM*DATA_WIDTH]};
						8'd115:		r_shift_data[i] = {r_shift_data[i-1][115*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:115*SHIFT_BITNUM*DATA_WIDTH]};
						8'd116:		r_shift_data[i] = {r_shift_data[i-1][116*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:116*SHIFT_BITNUM*DATA_WIDTH]};
						8'd117:		r_shift_data[i] = {r_shift_data[i-1][117*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:117*SHIFT_BITNUM*DATA_WIDTH]};
						8'd118:		r_shift_data[i] = {r_shift_data[i-1][118*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:118*SHIFT_BITNUM*DATA_WIDTH]};
						8'd119:		r_shift_data[i] = {r_shift_data[i-1][119*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:119*SHIFT_BITNUM*DATA_WIDTH]};
						8'd120:		r_shift_data[i] = {r_shift_data[i-1][120*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:120*SHIFT_BITNUM*DATA_WIDTH]};
						8'd121:		r_shift_data[i] = {r_shift_data[i-1][121*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:121*SHIFT_BITNUM*DATA_WIDTH]};
						8'd122:		r_shift_data[i] = {r_shift_data[i-1][122*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:122*SHIFT_BITNUM*DATA_WIDTH]};
						8'd123:		r_shift_data[i] = {r_shift_data[i-1][123*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:123*SHIFT_BITNUM*DATA_WIDTH]};
						8'd124:		r_shift_data[i] = {r_shift_data[i-1][124*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:124*SHIFT_BITNUM*DATA_WIDTH]};
						8'd125:		r_shift_data[i] = {r_shift_data[i-1][125*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:125*SHIFT_BITNUM*DATA_WIDTH]};
						8'd126:		r_shift_data[i] = {r_shift_data[i-1][126*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:126*SHIFT_BITNUM*DATA_WIDTH]};
						//8'd127:		r_shift_data[i] = {r_shift_data[i-1][127*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:127*SHIFT_BITNUM*DATA_WIDTH]};
						default:	r_shift_data[i] = r_shift_data[i-1];
						endcase
					end
				end
			end
			else begin
			
				always @(*) begin case(w_offset_per_cycle[i-1])
					8'd1:		r_shift_data[i] = {r_shift_data[i-1][1*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:1*SHIFT_BITNUM*DATA_WIDTH]};
					8'd2:		r_shift_data[i] = {r_shift_data[i-1][2*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:2*SHIFT_BITNUM*DATA_WIDTH]};
					8'd3:		r_shift_data[i] = {r_shift_data[i-1][3*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:3*SHIFT_BITNUM*DATA_WIDTH]};
					8'd4:		r_shift_data[i] = {r_shift_data[i-1][4*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:4*SHIFT_BITNUM*DATA_WIDTH]};
					8'd5:		r_shift_data[i] = {r_shift_data[i-1][5*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:5*SHIFT_BITNUM*DATA_WIDTH]};
					8'd6:		r_shift_data[i] = {r_shift_data[i-1][6*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:6*SHIFT_BITNUM*DATA_WIDTH]};
					8'd7:		r_shift_data[i] = {r_shift_data[i-1][7*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:7*SHIFT_BITNUM*DATA_WIDTH]};
					8'd8:		r_shift_data[i] = {r_shift_data[i-1][8*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:8*SHIFT_BITNUM*DATA_WIDTH]};
					8'd9:		r_shift_data[i] = {r_shift_data[i-1][9*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:9*SHIFT_BITNUM*DATA_WIDTH]};
					8'd10:		r_shift_data[i] = {r_shift_data[i-1][10*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:10*SHIFT_BITNUM*DATA_WIDTH]};
					8'd11:		r_shift_data[i] = {r_shift_data[i-1][11*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:11*SHIFT_BITNUM*DATA_WIDTH]};
					8'd12:		r_shift_data[i] = {r_shift_data[i-1][12*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:12*SHIFT_BITNUM*DATA_WIDTH]};
					8'd13:		r_shift_data[i] = {r_shift_data[i-1][13*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:13*SHIFT_BITNUM*DATA_WIDTH]};
					8'd14:		r_shift_data[i] = {r_shift_data[i-1][14*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:14*SHIFT_BITNUM*DATA_WIDTH]};
					8'd15:		r_shift_data[i] = {r_shift_data[i-1][15*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:15*SHIFT_BITNUM*DATA_WIDTH]};
					8'd16:		r_shift_data[i] = {r_shift_data[i-1][16*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:16*SHIFT_BITNUM*DATA_WIDTH]};
					8'd17:		r_shift_data[i] = {r_shift_data[i-1][17*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:17*SHIFT_BITNUM*DATA_WIDTH]};
					8'd18:		r_shift_data[i] = {r_shift_data[i-1][18*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:18*SHIFT_BITNUM*DATA_WIDTH]};
					8'd19:		r_shift_data[i] = {r_shift_data[i-1][19*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:19*SHIFT_BITNUM*DATA_WIDTH]};
					8'd20:		r_shift_data[i] = {r_shift_data[i-1][20*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:20*SHIFT_BITNUM*DATA_WIDTH]};
					8'd21:		r_shift_data[i] = {r_shift_data[i-1][21*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:21*SHIFT_BITNUM*DATA_WIDTH]};
					8'd22:		r_shift_data[i] = {r_shift_data[i-1][22*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:22*SHIFT_BITNUM*DATA_WIDTH]};
					8'd23:		r_shift_data[i] = {r_shift_data[i-1][23*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:23*SHIFT_BITNUM*DATA_WIDTH]};
					8'd24:		r_shift_data[i] = {r_shift_data[i-1][24*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:24*SHIFT_BITNUM*DATA_WIDTH]};
					8'd25:		r_shift_data[i] = {r_shift_data[i-1][25*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:25*SHIFT_BITNUM*DATA_WIDTH]};
					8'd26:		r_shift_data[i] = {r_shift_data[i-1][26*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:26*SHIFT_BITNUM*DATA_WIDTH]};
					8'd27:		r_shift_data[i] = {r_shift_data[i-1][27*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:27*SHIFT_BITNUM*DATA_WIDTH]};
					8'd28:		r_shift_data[i] = {r_shift_data[i-1][28*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:28*SHIFT_BITNUM*DATA_WIDTH]};
					8'd29:		r_shift_data[i] = {r_shift_data[i-1][29*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:29*SHIFT_BITNUM*DATA_WIDTH]};
					8'd30:		r_shift_data[i] = {r_shift_data[i-1][30*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:30*SHIFT_BITNUM*DATA_WIDTH]};
					8'd31:		r_shift_data[i] = {r_shift_data[i-1][31*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:31*SHIFT_BITNUM*DATA_WIDTH]};
					8'd32:		r_shift_data[i] = {r_shift_data[i-1][32*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:32*SHIFT_BITNUM*DATA_WIDTH]};
					8'd33:		r_shift_data[i] = {r_shift_data[i-1][33*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:33*SHIFT_BITNUM*DATA_WIDTH]};
					8'd34:		r_shift_data[i] = {r_shift_data[i-1][34*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:34*SHIFT_BITNUM*DATA_WIDTH]};
					8'd35:		r_shift_data[i] = {r_shift_data[i-1][35*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:35*SHIFT_BITNUM*DATA_WIDTH]};
					8'd36:		r_shift_data[i] = {r_shift_data[i-1][36*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:36*SHIFT_BITNUM*DATA_WIDTH]};
					8'd37:		r_shift_data[i] = {r_shift_data[i-1][37*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:37*SHIFT_BITNUM*DATA_WIDTH]};
					8'd38:		r_shift_data[i] = {r_shift_data[i-1][38*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:38*SHIFT_BITNUM*DATA_WIDTH]};
					8'd39:		r_shift_data[i] = {r_shift_data[i-1][39*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:39*SHIFT_BITNUM*DATA_WIDTH]};
					8'd40:		r_shift_data[i] = {r_shift_data[i-1][40*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:40*SHIFT_BITNUM*DATA_WIDTH]};
					8'd41:		r_shift_data[i] = {r_shift_data[i-1][41*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:41*SHIFT_BITNUM*DATA_WIDTH]};
					8'd42:		r_shift_data[i] = {r_shift_data[i-1][42*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:42*SHIFT_BITNUM*DATA_WIDTH]};
					8'd43:		r_shift_data[i] = {r_shift_data[i-1][43*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:43*SHIFT_BITNUM*DATA_WIDTH]};
					8'd44:		r_shift_data[i] = {r_shift_data[i-1][44*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:44*SHIFT_BITNUM*DATA_WIDTH]};
					8'd45:		r_shift_data[i] = {r_shift_data[i-1][45*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:45*SHIFT_BITNUM*DATA_WIDTH]};
					8'd46:		r_shift_data[i] = {r_shift_data[i-1][46*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:46*SHIFT_BITNUM*DATA_WIDTH]};
					8'd47:		r_shift_data[i] = {r_shift_data[i-1][47*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:47*SHIFT_BITNUM*DATA_WIDTH]};
					8'd48:		r_shift_data[i] = {r_shift_data[i-1][48*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:48*SHIFT_BITNUM*DATA_WIDTH]};
					8'd49:		r_shift_data[i] = {r_shift_data[i-1][49*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:49*SHIFT_BITNUM*DATA_WIDTH]};
					8'd50:		r_shift_data[i] = {r_shift_data[i-1][50*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:50*SHIFT_BITNUM*DATA_WIDTH]};
					8'd51:		r_shift_data[i] = {r_shift_data[i-1][51*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:51*SHIFT_BITNUM*DATA_WIDTH]};
					8'd52:		r_shift_data[i] = {r_shift_data[i-1][52*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:52*SHIFT_BITNUM*DATA_WIDTH]};
					8'd53:		r_shift_data[i] = {r_shift_data[i-1][53*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:53*SHIFT_BITNUM*DATA_WIDTH]};
					8'd54:		r_shift_data[i] = {r_shift_data[i-1][54*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:54*SHIFT_BITNUM*DATA_WIDTH]};
					8'd55:		r_shift_data[i] = {r_shift_data[i-1][55*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:55*SHIFT_BITNUM*DATA_WIDTH]};
					8'd56:		r_shift_data[i] = {r_shift_data[i-1][56*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:56*SHIFT_BITNUM*DATA_WIDTH]};
					8'd57:		r_shift_data[i] = {r_shift_data[i-1][57*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:57*SHIFT_BITNUM*DATA_WIDTH]};
					8'd58:		r_shift_data[i] = {r_shift_data[i-1][58*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:58*SHIFT_BITNUM*DATA_WIDTH]};
					8'd59:		r_shift_data[i] = {r_shift_data[i-1][59*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:59*SHIFT_BITNUM*DATA_WIDTH]};
					8'd60:		r_shift_data[i] = {r_shift_data[i-1][60*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:60*SHIFT_BITNUM*DATA_WIDTH]};
					8'd61:		r_shift_data[i] = {r_shift_data[i-1][61*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:61*SHIFT_BITNUM*DATA_WIDTH]};
					8'd62:		r_shift_data[i] = {r_shift_data[i-1][62*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:62*SHIFT_BITNUM*DATA_WIDTH]};
					8'd63:		r_shift_data[i] = {r_shift_data[i-1][63*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:63*SHIFT_BITNUM*DATA_WIDTH]};
					8'd64:		r_shift_data[i] = {r_shift_data[i-1][64*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:64*SHIFT_BITNUM*DATA_WIDTH]};
					8'd65:		r_shift_data[i] = {r_shift_data[i-1][65*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:65*SHIFT_BITNUM*DATA_WIDTH]};
					8'd66:		r_shift_data[i] = {r_shift_data[i-1][66*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:66*SHIFT_BITNUM*DATA_WIDTH]};
					8'd67:		r_shift_data[i] = {r_shift_data[i-1][67*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:67*SHIFT_BITNUM*DATA_WIDTH]};
					8'd68:		r_shift_data[i] = {r_shift_data[i-1][68*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:68*SHIFT_BITNUM*DATA_WIDTH]};
					8'd69:		r_shift_data[i] = {r_shift_data[i-1][69*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:69*SHIFT_BITNUM*DATA_WIDTH]};
					8'd70:		r_shift_data[i] = {r_shift_data[i-1][70*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:70*SHIFT_BITNUM*DATA_WIDTH]};
					8'd71:		r_shift_data[i] = {r_shift_data[i-1][71*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:71*SHIFT_BITNUM*DATA_WIDTH]};
					8'd72:		r_shift_data[i] = {r_shift_data[i-1][72*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:72*SHIFT_BITNUM*DATA_WIDTH]};
					8'd73:		r_shift_data[i] = {r_shift_data[i-1][73*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:73*SHIFT_BITNUM*DATA_WIDTH]};
					8'd74:		r_shift_data[i] = {r_shift_data[i-1][74*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:74*SHIFT_BITNUM*DATA_WIDTH]};
					8'd75:		r_shift_data[i] = {r_shift_data[i-1][75*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:75*SHIFT_BITNUM*DATA_WIDTH]};
					8'd76:		r_shift_data[i] = {r_shift_data[i-1][76*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:76*SHIFT_BITNUM*DATA_WIDTH]};
					8'd77:		r_shift_data[i] = {r_shift_data[i-1][77*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:77*SHIFT_BITNUM*DATA_WIDTH]};
					8'd78:		r_shift_data[i] = {r_shift_data[i-1][78*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:78*SHIFT_BITNUM*DATA_WIDTH]};
					8'd79:		r_shift_data[i] = {r_shift_data[i-1][79*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:79*SHIFT_BITNUM*DATA_WIDTH]};
					8'd80:		r_shift_data[i] = {r_shift_data[i-1][80*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:80*SHIFT_BITNUM*DATA_WIDTH]};
					8'd81:		r_shift_data[i] = {r_shift_data[i-1][81*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:81*SHIFT_BITNUM*DATA_WIDTH]};
					8'd82:		r_shift_data[i] = {r_shift_data[i-1][82*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:82*SHIFT_BITNUM*DATA_WIDTH]};
					8'd83:		r_shift_data[i] = {r_shift_data[i-1][83*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:83*SHIFT_BITNUM*DATA_WIDTH]};
					8'd84:		r_shift_data[i] = {r_shift_data[i-1][84*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:84*SHIFT_BITNUM*DATA_WIDTH]};
					8'd85:		r_shift_data[i] = {r_shift_data[i-1][85*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:85*SHIFT_BITNUM*DATA_WIDTH]};
					8'd86:		r_shift_data[i] = {r_shift_data[i-1][86*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:86*SHIFT_BITNUM*DATA_WIDTH]};
					8'd87:		r_shift_data[i] = {r_shift_data[i-1][87*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:87*SHIFT_BITNUM*DATA_WIDTH]};
					8'd88:		r_shift_data[i] = {r_shift_data[i-1][88*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:88*SHIFT_BITNUM*DATA_WIDTH]};
					8'd89:		r_shift_data[i] = {r_shift_data[i-1][89*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:89*SHIFT_BITNUM*DATA_WIDTH]};
					8'd90:		r_shift_data[i] = {r_shift_data[i-1][90*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:90*SHIFT_BITNUM*DATA_WIDTH]};
					8'd91:		r_shift_data[i] = {r_shift_data[i-1][91*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:91*SHIFT_BITNUM*DATA_WIDTH]};
					8'd92:		r_shift_data[i] = {r_shift_data[i-1][92*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:92*SHIFT_BITNUM*DATA_WIDTH]};
					8'd93:		r_shift_data[i] = {r_shift_data[i-1][93*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:93*SHIFT_BITNUM*DATA_WIDTH]};
					8'd94:		r_shift_data[i] = {r_shift_data[i-1][94*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:94*SHIFT_BITNUM*DATA_WIDTH]};
					8'd95:		r_shift_data[i] = {r_shift_data[i-1][95*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:95*SHIFT_BITNUM*DATA_WIDTH]};
					8'd96:		r_shift_data[i] = {r_shift_data[i-1][96*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:96*SHIFT_BITNUM*DATA_WIDTH]};
					8'd97:		r_shift_data[i] = {r_shift_data[i-1][97*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:97*SHIFT_BITNUM*DATA_WIDTH]};
					8'd98:		r_shift_data[i] = {r_shift_data[i-1][98*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:98*SHIFT_BITNUM*DATA_WIDTH]};
					8'd99:		r_shift_data[i] = {r_shift_data[i-1][99*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:99*SHIFT_BITNUM*DATA_WIDTH]};
					8'd100:		r_shift_data[i] = {r_shift_data[i-1][100*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:100*SHIFT_BITNUM*DATA_WIDTH]};
					8'd101:		r_shift_data[i] = {r_shift_data[i-1][101*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:101*SHIFT_BITNUM*DATA_WIDTH]};
					8'd102:		r_shift_data[i] = {r_shift_data[i-1][102*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:102*SHIFT_BITNUM*DATA_WIDTH]};
					8'd103:		r_shift_data[i] = {r_shift_data[i-1][103*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:103*SHIFT_BITNUM*DATA_WIDTH]};
					8'd104:		r_shift_data[i] = {r_shift_data[i-1][104*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:104*SHIFT_BITNUM*DATA_WIDTH]};
					8'd105:		r_shift_data[i] = {r_shift_data[i-1][105*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:105*SHIFT_BITNUM*DATA_WIDTH]};
					8'd106:		r_shift_data[i] = {r_shift_data[i-1][106*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:106*SHIFT_BITNUM*DATA_WIDTH]};
					8'd107:		r_shift_data[i] = {r_shift_data[i-1][107*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:107*SHIFT_BITNUM*DATA_WIDTH]};
					8'd108:		r_shift_data[i] = {r_shift_data[i-1][108*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:108*SHIFT_BITNUM*DATA_WIDTH]};
					8'd109:		r_shift_data[i] = {r_shift_data[i-1][109*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:109*SHIFT_BITNUM*DATA_WIDTH]};
					8'd110:		r_shift_data[i] = {r_shift_data[i-1][110*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:110*SHIFT_BITNUM*DATA_WIDTH]};
					8'd111:		r_shift_data[i] = {r_shift_data[i-1][111*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:111*SHIFT_BITNUM*DATA_WIDTH]};
					8'd112:		r_shift_data[i] = {r_shift_data[i-1][112*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:112*SHIFT_BITNUM*DATA_WIDTH]};
					8'd113:		r_shift_data[i] = {r_shift_data[i-1][113*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:113*SHIFT_BITNUM*DATA_WIDTH]};
					8'd114:		r_shift_data[i] = {r_shift_data[i-1][114*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:114*SHIFT_BITNUM*DATA_WIDTH]};
					8'd115:		r_shift_data[i] = {r_shift_data[i-1][115*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:115*SHIFT_BITNUM*DATA_WIDTH]};
					8'd116:		r_shift_data[i] = {r_shift_data[i-1][116*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:116*SHIFT_BITNUM*DATA_WIDTH]};
					8'd117:		r_shift_data[i] = {r_shift_data[i-1][117*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:117*SHIFT_BITNUM*DATA_WIDTH]};
					8'd118:		r_shift_data[i] = {r_shift_data[i-1][118*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:118*SHIFT_BITNUM*DATA_WIDTH]};
					8'd119:		r_shift_data[i] = {r_shift_data[i-1][119*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:119*SHIFT_BITNUM*DATA_WIDTH]};
					8'd120:		r_shift_data[i] = {r_shift_data[i-1][120*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:120*SHIFT_BITNUM*DATA_WIDTH]};
					8'd121:		r_shift_data[i] = {r_shift_data[i-1][121*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:121*SHIFT_BITNUM*DATA_WIDTH]};
					8'd122:		r_shift_data[i] = {r_shift_data[i-1][122*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:122*SHIFT_BITNUM*DATA_WIDTH]};
					8'd123:		r_shift_data[i] = {r_shift_data[i-1][123*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:123*SHIFT_BITNUM*DATA_WIDTH]};
					8'd124:		r_shift_data[i] = {r_shift_data[i-1][124*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:124*SHIFT_BITNUM*DATA_WIDTH]};
					8'd125:		r_shift_data[i] = {r_shift_data[i-1][125*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:125*SHIFT_BITNUM*DATA_WIDTH]};
					8'd126:		r_shift_data[i] = {r_shift_data[i-1][126*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:126*SHIFT_BITNUM*DATA_WIDTH]};
					8'd127:		r_shift_data[i] = {r_shift_data[i-1][127*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:127*SHIFT_BITNUM*DATA_WIDTH]};
					8'd128:		r_shift_data[i] = {r_shift_data[i-1][128*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:128*SHIFT_BITNUM*DATA_WIDTH]};
					8'd129:		r_shift_data[i] = {r_shift_data[i-1][129*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:129*SHIFT_BITNUM*DATA_WIDTH]};
					8'd130:		r_shift_data[i] = {r_shift_data[i-1][130*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:130*SHIFT_BITNUM*DATA_WIDTH]};
					8'd131:		r_shift_data[i] = {r_shift_data[i-1][131*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:131*SHIFT_BITNUM*DATA_WIDTH]};
					8'd132:		r_shift_data[i] = {r_shift_data[i-1][132*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:132*SHIFT_BITNUM*DATA_WIDTH]};
					8'd133:		r_shift_data[i] = {r_shift_data[i-1][133*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:133*SHIFT_BITNUM*DATA_WIDTH]};
					8'd134:		r_shift_data[i] = {r_shift_data[i-1][134*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:134*SHIFT_BITNUM*DATA_WIDTH]};
					8'd135:		r_shift_data[i] = {r_shift_data[i-1][135*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:135*SHIFT_BITNUM*DATA_WIDTH]};
					8'd136:		r_shift_data[i] = {r_shift_data[i-1][136*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:136*SHIFT_BITNUM*DATA_WIDTH]};
					8'd137:		r_shift_data[i] = {r_shift_data[i-1][137*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:137*SHIFT_BITNUM*DATA_WIDTH]};
					8'd138:		r_shift_data[i] = {r_shift_data[i-1][138*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:138*SHIFT_BITNUM*DATA_WIDTH]};
					8'd139:		r_shift_data[i] = {r_shift_data[i-1][139*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:139*SHIFT_BITNUM*DATA_WIDTH]};
					8'd140:		r_shift_data[i] = {r_shift_data[i-1][140*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:140*SHIFT_BITNUM*DATA_WIDTH]};
					8'd141:		r_shift_data[i] = {r_shift_data[i-1][141*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:141*SHIFT_BITNUM*DATA_WIDTH]};
					8'd142:		r_shift_data[i] = {r_shift_data[i-1][142*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:142*SHIFT_BITNUM*DATA_WIDTH]};
					8'd143:		r_shift_data[i] = {r_shift_data[i-1][143*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:143*SHIFT_BITNUM*DATA_WIDTH]};
					8'd144:		r_shift_data[i] = {r_shift_data[i-1][144*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:144*SHIFT_BITNUM*DATA_WIDTH]};
					8'd145:		r_shift_data[i] = {r_shift_data[i-1][145*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:145*SHIFT_BITNUM*DATA_WIDTH]};
					8'd146:		r_shift_data[i] = {r_shift_data[i-1][146*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:146*SHIFT_BITNUM*DATA_WIDTH]};
					8'd147:		r_shift_data[i] = {r_shift_data[i-1][147*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:147*SHIFT_BITNUM*DATA_WIDTH]};
					8'd148:		r_shift_data[i] = {r_shift_data[i-1][148*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:148*SHIFT_BITNUM*DATA_WIDTH]};
					8'd149:		r_shift_data[i] = {r_shift_data[i-1][149*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:149*SHIFT_BITNUM*DATA_WIDTH]};
					8'd150:		r_shift_data[i] = {r_shift_data[i-1][150*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:150*SHIFT_BITNUM*DATA_WIDTH]};
					8'd151:		r_shift_data[i] = {r_shift_data[i-1][151*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:151*SHIFT_BITNUM*DATA_WIDTH]};
					8'd152:		r_shift_data[i] = {r_shift_data[i-1][152*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:152*SHIFT_BITNUM*DATA_WIDTH]};
					8'd153:		r_shift_data[i] = {r_shift_data[i-1][153*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:153*SHIFT_BITNUM*DATA_WIDTH]};
					8'd154:		r_shift_data[i] = {r_shift_data[i-1][154*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:154*SHIFT_BITNUM*DATA_WIDTH]};
					8'd155:		r_shift_data[i] = {r_shift_data[i-1][155*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:155*SHIFT_BITNUM*DATA_WIDTH]};
					8'd156:		r_shift_data[i] = {r_shift_data[i-1][156*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:156*SHIFT_BITNUM*DATA_WIDTH]};
					8'd157:		r_shift_data[i] = {r_shift_data[i-1][157*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:157*SHIFT_BITNUM*DATA_WIDTH]};
					8'd158:		r_shift_data[i] = {r_shift_data[i-1][158*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:158*SHIFT_BITNUM*DATA_WIDTH]};
					8'd159:		r_shift_data[i] = {r_shift_data[i-1][159*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:159*SHIFT_BITNUM*DATA_WIDTH]};
					8'd160:		r_shift_data[i] = {r_shift_data[i-1][160*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:160*SHIFT_BITNUM*DATA_WIDTH]};
					8'd161:		r_shift_data[i] = {r_shift_data[i-1][161*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:161*SHIFT_BITNUM*DATA_WIDTH]};
					8'd162:		r_shift_data[i] = {r_shift_data[i-1][162*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:162*SHIFT_BITNUM*DATA_WIDTH]};
					8'd163:		r_shift_data[i] = {r_shift_data[i-1][163*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:163*SHIFT_BITNUM*DATA_WIDTH]};
					8'd164:		r_shift_data[i] = {r_shift_data[i-1][164*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:164*SHIFT_BITNUM*DATA_WIDTH]};
					8'd165:		r_shift_data[i] = {r_shift_data[i-1][165*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:165*SHIFT_BITNUM*DATA_WIDTH]};
					8'd166:		r_shift_data[i] = {r_shift_data[i-1][166*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:166*SHIFT_BITNUM*DATA_WIDTH]};
					8'd167:		r_shift_data[i] = {r_shift_data[i-1][167*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:167*SHIFT_BITNUM*DATA_WIDTH]};
					8'd168:		r_shift_data[i] = {r_shift_data[i-1][168*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:168*SHIFT_BITNUM*DATA_WIDTH]};
					8'd169:		r_shift_data[i] = {r_shift_data[i-1][169*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:169*SHIFT_BITNUM*DATA_WIDTH]};
					8'd170:		r_shift_data[i] = {r_shift_data[i-1][170*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:170*SHIFT_BITNUM*DATA_WIDTH]};
					8'd171:		r_shift_data[i] = {r_shift_data[i-1][171*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:171*SHIFT_BITNUM*DATA_WIDTH]};
					8'd172:		r_shift_data[i] = {r_shift_data[i-1][172*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:172*SHIFT_BITNUM*DATA_WIDTH]};
					8'd173:		r_shift_data[i] = {r_shift_data[i-1][173*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:173*SHIFT_BITNUM*DATA_WIDTH]};
					8'd174:		r_shift_data[i] = {r_shift_data[i-1][174*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:174*SHIFT_BITNUM*DATA_WIDTH]};
					8'd175:		r_shift_data[i] = {r_shift_data[i-1][175*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:175*SHIFT_BITNUM*DATA_WIDTH]};
					8'd176:		r_shift_data[i] = {r_shift_data[i-1][176*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:176*SHIFT_BITNUM*DATA_WIDTH]};
					8'd177:		r_shift_data[i] = {r_shift_data[i-1][177*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:177*SHIFT_BITNUM*DATA_WIDTH]};
					8'd178:		r_shift_data[i] = {r_shift_data[i-1][178*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:178*SHIFT_BITNUM*DATA_WIDTH]};
					8'd179:		r_shift_data[i] = {r_shift_data[i-1][179*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:179*SHIFT_BITNUM*DATA_WIDTH]};
					8'd180:		r_shift_data[i] = {r_shift_data[i-1][180*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:180*SHIFT_BITNUM*DATA_WIDTH]};
					8'd181:		r_shift_data[i] = {r_shift_data[i-1][181*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:181*SHIFT_BITNUM*DATA_WIDTH]};
					8'd182:		r_shift_data[i] = {r_shift_data[i-1][182*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:182*SHIFT_BITNUM*DATA_WIDTH]};
					8'd183:		r_shift_data[i] = {r_shift_data[i-1][183*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:183*SHIFT_BITNUM*DATA_WIDTH]};
					8'd184:		r_shift_data[i] = {r_shift_data[i-1][184*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:184*SHIFT_BITNUM*DATA_WIDTH]};
					8'd185:		r_shift_data[i] = {r_shift_data[i-1][185*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:185*SHIFT_BITNUM*DATA_WIDTH]};
					8'd186:		r_shift_data[i] = {r_shift_data[i-1][186*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:186*SHIFT_BITNUM*DATA_WIDTH]};
					8'd187:		r_shift_data[i] = {r_shift_data[i-1][187*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:187*SHIFT_BITNUM*DATA_WIDTH]};
					8'd188:		r_shift_data[i] = {r_shift_data[i-1][188*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:188*SHIFT_BITNUM*DATA_WIDTH]};
					8'd189:		r_shift_data[i] = {r_shift_data[i-1][189*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:189*SHIFT_BITNUM*DATA_WIDTH]};
					8'd190:		r_shift_data[i] = {r_shift_data[i-1][190*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:190*SHIFT_BITNUM*DATA_WIDTH]};
					8'd191:		r_shift_data[i] = {r_shift_data[i-1][191*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:191*SHIFT_BITNUM*DATA_WIDTH]};
					8'd192:		r_shift_data[i] = {r_shift_data[i-1][192*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:192*SHIFT_BITNUM*DATA_WIDTH]};
					8'd193:		r_shift_data[i] = {r_shift_data[i-1][193*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:193*SHIFT_BITNUM*DATA_WIDTH]};
					8'd194:		r_shift_data[i] = {r_shift_data[i-1][194*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:194*SHIFT_BITNUM*DATA_WIDTH]};
					8'd195:		r_shift_data[i] = {r_shift_data[i-1][195*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:195*SHIFT_BITNUM*DATA_WIDTH]};
					8'd196:		r_shift_data[i] = {r_shift_data[i-1][196*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:196*SHIFT_BITNUM*DATA_WIDTH]};
					8'd197:		r_shift_data[i] = {r_shift_data[i-1][197*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:197*SHIFT_BITNUM*DATA_WIDTH]};
					8'd198:		r_shift_data[i] = {r_shift_data[i-1][198*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:198*SHIFT_BITNUM*DATA_WIDTH]};
					8'd199:		r_shift_data[i] = {r_shift_data[i-1][199*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:199*SHIFT_BITNUM*DATA_WIDTH]};
					8'd200:		r_shift_data[i] = {r_shift_data[i-1][200*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:200*SHIFT_BITNUM*DATA_WIDTH]};
					8'd201:		r_shift_data[i] = {r_shift_data[i-1][201*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:201*SHIFT_BITNUM*DATA_WIDTH]};
					8'd202:		r_shift_data[i] = {r_shift_data[i-1][202*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:202*SHIFT_BITNUM*DATA_WIDTH]};
					8'd203:		r_shift_data[i] = {r_shift_data[i-1][203*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:203*SHIFT_BITNUM*DATA_WIDTH]};
					8'd204:		r_shift_data[i] = {r_shift_data[i-1][204*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:204*SHIFT_BITNUM*DATA_WIDTH]};
					8'd205:		r_shift_data[i] = {r_shift_data[i-1][205*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:205*SHIFT_BITNUM*DATA_WIDTH]};
					8'd206:		r_shift_data[i] = {r_shift_data[i-1][206*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:206*SHIFT_BITNUM*DATA_WIDTH]};
					8'd207:		r_shift_data[i] = {r_shift_data[i-1][207*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:207*SHIFT_BITNUM*DATA_WIDTH]};
					8'd208:		r_shift_data[i] = {r_shift_data[i-1][208*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:208*SHIFT_BITNUM*DATA_WIDTH]};
					8'd209:		r_shift_data[i] = {r_shift_data[i-1][209*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:209*SHIFT_BITNUM*DATA_WIDTH]};
					8'd210:		r_shift_data[i] = {r_shift_data[i-1][210*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:210*SHIFT_BITNUM*DATA_WIDTH]};
					8'd211:		r_shift_data[i] = {r_shift_data[i-1][211*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:211*SHIFT_BITNUM*DATA_WIDTH]};
					8'd212:		r_shift_data[i] = {r_shift_data[i-1][212*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:212*SHIFT_BITNUM*DATA_WIDTH]};
					8'd213:		r_shift_data[i] = {r_shift_data[i-1][213*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:213*SHIFT_BITNUM*DATA_WIDTH]};
					8'd214:		r_shift_data[i] = {r_shift_data[i-1][214*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:214*SHIFT_BITNUM*DATA_WIDTH]};
					8'd215:		r_shift_data[i] = {r_shift_data[i-1][215*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:215*SHIFT_BITNUM*DATA_WIDTH]};
					8'd216:		r_shift_data[i] = {r_shift_data[i-1][216*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:216*SHIFT_BITNUM*DATA_WIDTH]};
					8'd217:		r_shift_data[i] = {r_shift_data[i-1][217*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:217*SHIFT_BITNUM*DATA_WIDTH]};
					8'd218:		r_shift_data[i] = {r_shift_data[i-1][218*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:218*SHIFT_BITNUM*DATA_WIDTH]};
					8'd219:		r_shift_data[i] = {r_shift_data[i-1][219*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:219*SHIFT_BITNUM*DATA_WIDTH]};
					8'd220:		r_shift_data[i] = {r_shift_data[i-1][220*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:220*SHIFT_BITNUM*DATA_WIDTH]};
					8'd221:		r_shift_data[i] = {r_shift_data[i-1][221*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:221*SHIFT_BITNUM*DATA_WIDTH]};
					8'd222:		r_shift_data[i] = {r_shift_data[i-1][222*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:222*SHIFT_BITNUM*DATA_WIDTH]};
					8'd223:		r_shift_data[i] = {r_shift_data[i-1][223*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:223*SHIFT_BITNUM*DATA_WIDTH]};
					8'd224:		r_shift_data[i] = {r_shift_data[i-1][224*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:224*SHIFT_BITNUM*DATA_WIDTH]};
					8'd225:		r_shift_data[i] = {r_shift_data[i-1][225*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:225*SHIFT_BITNUM*DATA_WIDTH]};
					8'd226:		r_shift_data[i] = {r_shift_data[i-1][226*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:226*SHIFT_BITNUM*DATA_WIDTH]};
					8'd227:		r_shift_data[i] = {r_shift_data[i-1][227*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:227*SHIFT_BITNUM*DATA_WIDTH]};
					8'd228:		r_shift_data[i] = {r_shift_data[i-1][228*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:228*SHIFT_BITNUM*DATA_WIDTH]};
					8'd229:		r_shift_data[i] = {r_shift_data[i-1][229*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:229*SHIFT_BITNUM*DATA_WIDTH]};
					8'd230:		r_shift_data[i] = {r_shift_data[i-1][230*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:230*SHIFT_BITNUM*DATA_WIDTH]};
					8'd231:		r_shift_data[i] = {r_shift_data[i-1][231*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:231*SHIFT_BITNUM*DATA_WIDTH]};
					8'd232:		r_shift_data[i] = {r_shift_data[i-1][232*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:232*SHIFT_BITNUM*DATA_WIDTH]};
					8'd233:		r_shift_data[i] = {r_shift_data[i-1][233*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:233*SHIFT_BITNUM*DATA_WIDTH]};
					8'd234:		r_shift_data[i] = {r_shift_data[i-1][234*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:234*SHIFT_BITNUM*DATA_WIDTH]};
					8'd235:		r_shift_data[i] = {r_shift_data[i-1][235*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:235*SHIFT_BITNUM*DATA_WIDTH]};
					8'd236:		r_shift_data[i] = {r_shift_data[i-1][236*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:236*SHIFT_BITNUM*DATA_WIDTH]};
					8'd237:		r_shift_data[i] = {r_shift_data[i-1][237*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:237*SHIFT_BITNUM*DATA_WIDTH]};
					8'd238:		r_shift_data[i] = {r_shift_data[i-1][238*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:238*SHIFT_BITNUM*DATA_WIDTH]};
					8'd239:		r_shift_data[i] = {r_shift_data[i-1][239*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:239*SHIFT_BITNUM*DATA_WIDTH]};
					8'd240:		r_shift_data[i] = {r_shift_data[i-1][240*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:240*SHIFT_BITNUM*DATA_WIDTH]};
					8'd241:		r_shift_data[i] = {r_shift_data[i-1][241*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:241*SHIFT_BITNUM*DATA_WIDTH]};
					8'd242:		r_shift_data[i] = {r_shift_data[i-1][242*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:242*SHIFT_BITNUM*DATA_WIDTH]};
					8'd243:		r_shift_data[i] = {r_shift_data[i-1][243*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:243*SHIFT_BITNUM*DATA_WIDTH]};
					8'd244:		r_shift_data[i] = {r_shift_data[i-1][244*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:244*SHIFT_BITNUM*DATA_WIDTH]};
					8'd245:		r_shift_data[i] = {r_shift_data[i-1][245*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:245*SHIFT_BITNUM*DATA_WIDTH]};
					8'd246:		r_shift_data[i] = {r_shift_data[i-1][246*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:246*SHIFT_BITNUM*DATA_WIDTH]};
					8'd247:		r_shift_data[i] = {r_shift_data[i-1][247*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:247*SHIFT_BITNUM*DATA_WIDTH]};
					8'd248:		r_shift_data[i] = {r_shift_data[i-1][248*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:248*SHIFT_BITNUM*DATA_WIDTH]};
					8'd249:		r_shift_data[i] = {r_shift_data[i-1][249*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:249*SHIFT_BITNUM*DATA_WIDTH]};
					8'd250:		r_shift_data[i] = {r_shift_data[i-1][250*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:250*SHIFT_BITNUM*DATA_WIDTH]};
					8'd251:		r_shift_data[i] = {r_shift_data[i-1][251*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:251*SHIFT_BITNUM*DATA_WIDTH]};
					8'd252:		r_shift_data[i] = {r_shift_data[i-1][252*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:252*SHIFT_BITNUM*DATA_WIDTH]};
					8'd253:		r_shift_data[i] = {r_shift_data[i-1][253*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:253*SHIFT_BITNUM*DATA_WIDTH]};
					8'd254:		r_shift_data[i] = {r_shift_data[i-1][254*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:254*SHIFT_BITNUM*DATA_WIDTH]};
					8'd255:		r_shift_data[i] = {r_shift_data[i-1][255*SHIFT_BITNUM*DATA_WIDTH-1:0],r_shift_data[i-1][DATA_NUM*DATA_WIDTH-1:255*SHIFT_BITNUM*DATA_WIDTH]};
					default:	r_shift_data[i] = r_shift_data[i-1];
					endcase
				end
			end
		end
	end
endgenerate
endmodule
