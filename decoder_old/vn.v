module vn #(
	parameter	MSG_WIDTH 	=	0	,
	parameter	PCM_ROWN	=	0			// # column blocks
) (
	input									i_clk		,
	input									i_rst_n		,
	
	input	[MSG_WIDTH-1:0]					i_llr		,
	input	[MSG_WIDTH*PCM_ROWN-1:0]		i_c2v_bus	,
	
	output	reg								o_app		,			
	output	reg	[MSG_WIDTH*PCM_ROWN-1:0]	o_v2c_bus	
);


// ------------------------v Input assign v--------------------
wire	signed	[MSG_WIDTH-1:0]	w_c2v [0:PCM_ROWN-1];
wire	signed	[MSG_WIDTH-1:0]	w_i_llr;
assign w_i_llr = i_llr;

genvar i;
generate
	for(i=0; i<PCM_ROWN; i=i+1)	begin: INPUT_ASSIGN
		assign	w_c2v[i] = i_c2v_bus[MSG_WIDTH*(i+1)-1:MSG_WIDTH*i];
	end
endgenerate


// ------------------------v Input assign v--------------------

// ------------------------v Add up v--------------------------
localparam	POS_MAX = (1 << MSG_WIDTH-1)-1	;
localparam	NEG_MAX = - POS_MAX				;

wire signed	[MSG_WIDTH + PCM_ROWN-1:0]	w_sum;
generate
	if(PCM_ROWN == 6)	begin
		assign	w_sum = w_c2v[0] + w_c2v[1] + w_c2v[2] + w_c2v[3]+ w_c2v[4]+ w_c2v[5] + w_i_llr; 
	end
	else;
endgenerate

wire	signed	[MSG_WIDTH + (PCM_ROWN+1)-1 : 0]	w_v2c_pre	[0:PCM_ROWN-1];
wire	signed	[MSG_WIDTH-1:0]						w_v2c		[0:PCM_ROWN-1];
generate
	for(i=0; i<PCM_ROWN; i=i+1) begin: SUB
		assign	w_v2c_pre[i] 	= w_sum - w_c2v[i];
		assign	w_v2c[i]		= w_v2c_pre[i] > POS_MAX ? POS_MAX : w_v2c_pre[i] < NEG_MAX ? NEG_MAX : w_v2c_pre[i]; 
	end
endgenerate
// ------------------------^ Add up ^--------------------------

// ------------------------v T_to_S v--------------------------
wire	[MSG_WIDTH-1:0]	w_v2c_sign_mag	[0:PCM_ROWN-1];
generate
	for(i=0; i<PCM_ROWN; i=i+1)	begin: T_to_S
		assign	w_v2c_sign_mag[i] = w_v2c[i][MSG_WIDTH-1]
										? {w_v2c[i][MSG_WIDTH-1], ~w_v2c[i][MSG_WIDTH-2:0]+1}
										: w_v2c[i];

		always@(posedge i_clk)	begin
			if(~i_rst_n)				o_v2c_bus[(i+1)*MSG_WIDTH-1:i*MSG_WIDTH] <= 'd0;
			else						o_v2c_bus[(i+1)*MSG_WIDTH-1:i*MSG_WIDTH] <= w_v2c_sign_mag[i];
		end
	end
endgenerate

always @(posedge i_clk)	begin
	if(~i_rst_n)			o_app <= 0;
	else					o_app <= w_sum[MSG_WIDTH + PCM_ROWN - 1];
end
// ------------------------^ T_to_S ^--------------------------

endmodule