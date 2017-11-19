module	min #(
	parameter	ABS_WID = 6,
	parameter	IN_NUM	= 4,
	parameter	MIN_NUM = 3,
	parameter	IDX_WID = 3,
	parameter	COM_RES_WID = 3
) (
	input	[ABS_WID*IN_NUM-1:0]	i_data,
	
	output	[ABS_WID*MIN_NUM-1:0]	o_data,		// minimum numbers at LSB;
	output	[IDX_WID*MIN_NUM-1:0]	o_idx		// index of minimum numbers at LSB;
);


wire [ABS_WID-1:0]	w_data [0:IN_NUM-1];
reg		[ABS_WID-1:0]		r_new_min				[MIN_NUM-1:0]	;
reg 	[IDX_WID-1:0]		r_new_min_idx			[MIN_NUM-1:0]	;

// Input assignment
genvar i;
generate
	for(i=0;i<IN_NUM; i=i+1)	begin
		assign w_data[i] = i_data[ABS_WID*(i+1)-1:ABS_WID*i];
	end
endgenerate

// Cross-compare
reg [IN_NUM-1:0] r_cross_comp [0:IN_NUM-1];
genvar j;
generate
	for(i=0; i<IN_NUM; i=i+1)	begin: Cross_Compare
		for(j=0; j<IN_NUM; j=j+1)	begin
			if(i<=j)	begin
				always@(*)	r_cross_comp[i][j] = (w_data[i] <= w_data[j]);
			end 
			else begin
				always@(*)	r_cross_comp[i][j] = (w_data[i] < w_data[j]);
			end
		end
	end
endgenerate

// Sort
wire	[COM_RES_WID-1:0]	w_comp_result_sum[0:IN_NUM-1];

generate
	if(IN_NUM == 4)	begin
		
		assign w_comp_result_sum[3] = r_cross_comp[3][3] + r_cross_comp[3][2] + r_cross_comp[3][1] + r_cross_comp[3][0];
		assign w_comp_result_sum[2] = r_cross_comp[2][3] + r_cross_comp[2][2] + r_cross_comp[2][1] + r_cross_comp[2][0];
		assign w_comp_result_sum[1] = r_cross_comp[1][3] + r_cross_comp[1][2] + r_cross_comp[1][1] + r_cross_comp[1][0];
		assign w_comp_result_sum[0] = r_cross_comp[0][3] + r_cross_comp[0][2] + r_cross_comp[0][1] + r_cross_comp[0][0];

		for(i=0; i<MIN_NUM; i=i+1)	begin: find_min

			always@(*)	begin
				if(w_comp_result_sum[0] == IN_NUM-i)	begin
					r_new_min[i] = w_data[0]	;
					r_new_min_idx[i] = 0		;
				end
				else if(w_comp_result_sum[1] == IN_NUM-i)	begin
					r_new_min[i] = w_data[1]	;
					r_new_min_idx[i] = 1		;
				end
				else if(w_comp_result_sum[2] == IN_NUM-i)	begin
					r_new_min[i] = w_data[2]	;
					r_new_min_idx[i] = 2		;
				end
				else begin
					r_new_min[i] = w_data[3]	;
					r_new_min_idx[i] = 3		;
				end
			end
		end
	end
endgenerate

// Output assign
generate
	for(i=0; i< MIN_NUM; i=i+1)	begin: out_assign
		assign	o_data[(i+1)*ABS_WID-1:i*ABS_WID] = r_new_min[i];
		assign	o_idx[(i+1)*IDX_WID-1:i*IDX_WID] = r_new_min_idx[i];
	end
endgenerate

endmodule

