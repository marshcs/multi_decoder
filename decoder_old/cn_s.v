module cn_s #(
	parameter	MSG_WIDTH 	=	0	,
	parameter	MIN_NUM		=	0	,	// Length of the sorted queue;
	parameter	COL_CNT_WID = 	0	
) (
	input									i_clk			,
	input									i_rst_n			,
	input									i_decode_end	,
	input									i_vld			,
	input									i_is_first_iter	,

	input	[MSG_WIDTH-1:0]					i_v2c			,	// as sign-magnitude format;
	input	[COL_CNT_WID-1:0]				i_col_cnt		,
	input									i_v2c_sign_old	,

	output	[(MSG_WIDTH-1)*2-1:0]			o_v2c_abs		,
	output	[COL_CNT_WID-1:0]				o_v2c_idx		,
	output									o_v2c_sign		,
	output									o_v2c_sign_tot	
);

// ----------------v localparam v-------------------------
genvar i;
localparam	IDX_WID 		= 2;
localparam	COM_RES_WID 	= 3;
localparam ABS_WID = MSG_WIDTH-1;

wire	[ABS_WID*MIN_NUM-1:0]		w_v2c_sorted		;
wire	[IDX_WID	*MIN_NUM-1:0]	w_v2c_idx_sort		;
wire	[COL_CNT_WID*MIN_NUM-1:0]	w_v2c_idx_sorted	;
wire 								w_v2c_sign_old		;
// ----------------v localparam v-------------------------

// -----------v V2C queue v--------------------------------
reg		[ABS_WID-1:0]			r_v2c_queue		[0:MIN_NUM-1];
reg 	[COL_CNT_WID-1:0]		r_v2c_idx_queue	[0:MIN_NUM-1];

generate
	for(i=0; i<MIN_NUM; i=i+1)	begin: C2V_Queue
		always@(posedge i_clk)	begin
			if(~i_rst_n)				r_v2c_queue[i] <= {ABS_WID{1'b1}};
			else if(i_decode_end)		r_v2c_queue[i] <= {ABS_WID{1'b1}};
			else if(i_vld)				r_v2c_queue[i] <= w_v2c_sorted[ABS_WID*(i+1)-1:ABS_WID*i]	;
			else; 
		end

		always@(posedge i_clk)	begin
			if(~i_rst_n)				r_v2c_idx_queue[i] <= {COL_CNT_WID{1'b1}};
			else if(i_decode_end)		r_v2c_idx_queue[i] <= {COL_CNT_WID{1'b1}};
			else if(i_vld)				r_v2c_idx_queue[i] <= w_v2c_idx_sorted[COL_CNT_WID*(i+1)-1:COL_CNT_WID*i]	;
			else;
		end
	end
endgenerate
// -----------v V2C queue v--------------------------------

//----------->> Input assign >>-----------------------------
wire	[ABS_WID-1:0]			w_v2c_abs	[0:MIN_NUM]	;
wire	[COL_CNT_WID-1:0]		w_v2c_idx	[0:MIN_NUM]	;
wire	[MIN_NUM:0]				w_is_replace			;

generate
	for(i=0; i < MIN_NUM; i = i+1) begin
		assign	w_v2c_idx[i] = r_v2c_idx_queue[i];
		assign 	w_v2c_abs[i] = w_v2c_idx[i] == i_col_cnt ? i_v2c[ABS_WID-1:0] : r_v2c_queue[i];
		assign	w_is_replace[i] = i_col_cnt == w_v2c_idx[i];
	end
endgenerate

assign	w_is_replace[MIN_NUM] = |w_is_replace[MIN_NUM-1:0];
assign	w_v2c_abs[MIN_NUM] = w_is_replace[MIN_NUM] ? {ABS_WID{1'b1}} : i_v2c[ABS_WID-1:0];
assign	w_v2c_idx[MIN_NUM] = w_is_replace[MIN_NUM] ? {COL_CNT_WID{1'b1}} : i_col_cnt;
//----------->> Input assign >>-----------------------------
 
//----------->> Find Min >>---------------------------------
wire	[ABS_WID*(MIN_NUM+1)-1:0]	w_v2c_abs_bus		;
generate
	for(i=0; i<= MIN_NUM; i=i+1)	begin
		assign	w_v2c_abs_bus[ABS_WID*(i+1)-1:ABS_WID*i] = w_v2c_abs[i];
	end
endgenerate

min #(
	.ABS_WID	(ABS_WID),
	.IN_NUM		(MIN_NUM + 1),
	.MIN_NUM	(MIN_NUM	),
	.IDX_WID	(IDX_WID	),
	.COM_RES_WID(COM_RES_WID)
) min_inst (
	.i_data	(w_v2c_abs_bus	),
	.o_data	(w_v2c_sorted	),
	.o_idx	(w_v2c_idx_sort	)
);

generate
	for(i=0; i<MIN_NUM; i=i+1)	begin
		assign	w_v2c_idx_sorted[(i+1)*COL_CNT_WID-1:i*COL_CNT_WID] = w_v2c_idx[w_v2c_idx_sort[(i+1)*IDX_WID-1:i*IDX_WID]];		
	end
endgenerate

//----------->> Find Min >>---------------------------------

//----------->> Sign >>-------------------------------------
reg r_sign_tot;

assign	w_v2c_sign_old = i_is_first_iter ? 0 : i_v2c_sign_old;
always@(posedge i_clk)	begin
	if(~i_rst_n)			r_sign_tot <= 1'b0;
	else if(i_decode_end)	r_sign_tot <= 1'b0;
	else if(i_vld)			r_sign_tot <= i_v2c[MSG_WIDTH-1] ^ w_v2c_sign_old ^ r_sign_tot;
	else;
end
//----------->> Sign >>-------------------------------------

//----------->> Output assign >>----------------------------
assign	o_v2c_idx = r_v2c_idx_queue[0];
assign	o_v2c_abs = {r_v2c_queue[1], r_v2c_queue[0]};
assign	o_v2c_sign = i_v2c[MSG_WIDTH-1];
assign	o_v2c_sign_tot = r_sign_tot;
//----------->> Output assign >>----------------------------

endmodule