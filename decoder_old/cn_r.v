// CN-recover unit :
// 	recover r-msg from the memory bank of q-msg

module cn_r #(
	parameter	MSG_WIDTH	=	0	,
	parameter	COL_CNT_WID	=	0
)(
	input						i_clk			,
	input						i_rst_n			,

	input	[MSG_WIDTH-2:0]		i_v2c_abs_0		,
	input	[MSG_WIDTH-2:0]		i_v2c_abs_1		,
	input	[COL_CNT_WID-1:0]	i_idx_0			,

	input						i_v2c_sign		,		// sign of last q-msg at current position;
	input						i_v2c_sign_tot	,		// total sign of all q-msg in a line;
	input	[COL_CNT_WID-1:0]	i_col_cnt		,
	input						i_is_first_iter	,

	output	reg	[MSG_WIDTH-1:0]	o_c2v			
);

	localparam	ABS_WID	= MSG_WIDTH-1		;

	wire 	[ABS_WID-1:0]			w_v2c_abs	;

	assign	w_v2c_abs = (i_col_cnt == i_idx_0) ? i_v2c_abs_1 : i_v2c_abs_0;

//--------------->> Offset >>--------------------
	wire	[ABS_WID+1:0]		w_offset_c2v_tmp;
	wire	[ABS_WID-1:0]		w_offset_c2v;

	assign	w_offset_c2v_tmp = w_v2c_abs * 3;
	assign	w_offset_c2v = w_offset_c2v_tmp >> 2;
//---------------<< Offset <<--------------------

// sign
	wire	w_c2v_sign;
	assign	w_c2v_sign = i_v2c_sign ^ i_v2c_sign_tot;

// s_to_t

	wire	[MSG_WIDTH-1:0]		w_c2v;
	assign	w_c2v = w_c2v_sign == 0 ? {1'b0, w_offset_c2v} : ~{1'b0, w_offset_c2v}+1;

	always@(posedge i_clk)	begin
	  if(~i_rst_n)											o_c2v <= 'd0		;
	  else if(i_is_first_iter)								o_c2v <= 'd0		;
	  else													o_c2v <= w_c2v		;
	end

endmodule