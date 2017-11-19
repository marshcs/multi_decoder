`timescale 1ns / 1ps
/* ====================================================================================
Company: 南京大学
Engineer: 胡光辉

---------------------------------------------------------------------------------------
Create Date: 2017-04-05 10:42:30
Design Name: data_delay.v
Project Name: 

---------------------------------------------------------------------------------------
Description:	信号延迟模块
				
---------------------------------------------------------------------------------------
Revision: 0.01

Revision 0.01 - File Created

==================================================================================== */


module data_delay #(
	parameter DATA_WIDTH	= 0	,	// 信号位宽
	parameter LATENCY 		= 0		// 延迟周期数
)(
	input 							clk			,	// 时钟信号
	input 							rst_n		,	// 复位信号，低电平复位
	
	input 		[DATA_WIDTH-1:0]	i_data		,	// 输入数据
	output 		[DATA_WIDTH-1:0] 	o_data_dly		// 输出数据/延迟后的数据
);

// 根据延迟的时钟周期数对信号进行延迟
generate 
	if(LATENCY == 0) begin

		assign o_data_dly = (~rst_n)? 0 : i_data;

	end
	else if(LATENCY == 1) begin
		
		// 对信号进行缓存，实现延迟
		reg [DATA_WIDTH-1:0] r_data_buffer;

		always @(posedge clk) begin
			if(~rst_n)				r_data_buffer <= 0;
			else 					r_data_buffer <= i_data;
		end

		assign o_data_dly = r_data_buffer;

	end
	else begin
		
		reg [LATENCY*DATA_WIDTH-1:0] r_data_buffer;

		always @(posedge clk) begin
			if(~rst_n)				r_data_buffer <= 0;
			else 					r_data_buffer <= {r_data_buffer[(LATENCY-1)*DATA_WIDTH-1:0],i_data};
		end

		assign o_data_dly = r_data_buffer[LATENCY*DATA_WIDTH-1:(LATENCY-1)*DATA_WIDTH];

	end
endgenerate 

endmodule
