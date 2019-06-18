`timescale 10 us / 1 us

module data_stream(
	input							rst_n,
	input							clk,
	
	input			[35:0]			i_l_data,
	input							i_l_valid,
	output							o_l_ready,
	
	input			[35:0]			i_r_data,
	input							i_r_valid,
	output							o_r_ready,
	
	input							i_sync,
	
	output							o_sync_pulse,
	
	output			[15:0]			o_out_data_len,
	
	output			[31:0]			o_out_data,
	output							o_out_valid,
	input							i_out_ready	
);

	assign o_out_data_len = out_data_len;
	
	wire			[31:0]			wr_data;
	wire			[15:0]			wr_addr;
	wire							wr_en;
	
	wire							i_valid;
	assign i_valid = buf_half == 1'b0 ? i_l_valid : i_r_valid;
	
	wire			[35:0]			i_data;
	assign i_data = buf_half == 1'b0 ? i_l_data : i_r_data;
	
	
	
	assign wr_en = ~ch_cntr[ch_number][7] & i_valid;
	assign wr_data = i_data[31:0];
	wire			[4:0]			ch_number;
	assign ch_number = {buf_half, i_data[35:32]};
	assign wr_addr = {ch_number, ch_cntr[ch_number][6:0]};
	
	assign o_l_ready = ~buf_half;
	assign o_r_ready = buf_half;
	
	wire			[31:0]			rd_data;
	wire			[15:0]			rd_addr;

	data_buf data_buf_unit(
		.clock(clk),
		.data(wr_data),
		.wraddress(wr_addr),
		.wren(wr_en),
		
		.rdaddress(rd_addr),
		.q(rd_data)
	);
	
	reg			[0:0]			prev_sync;
	always @ (posedge clk) prev_sync <= i_sync;
	
	wire						sync_pulse;
	assign sync_pulse = ~prev_sync & i_sync ? 1'b1 : 1'b0;
	
	assign o_sync_pulse = sync_pulse;
		
	reg			[0:0]			buf_half;
	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			buf_half <= 1'b0;
		else
			buf_half <= ((i_l_valid & buf_half) | (i_r_valid & ~buf_half)) ? ~buf_half : buf_half;
	
	wire		[15:0]			data_length;
	assign data_length = 16'd8 +
		ch_cntr[0]  + ch_cntr[1]  + ch_cntr[2]  + ch_cntr[3]  + ch_cntr[4]  + ch_cntr[5]  + ch_cntr[6]  + ch_cntr[7]  +
		ch_cntr[8]  + ch_cntr[9]  + ch_cntr[10] + ch_cntr[11] + ch_cntr[12] + ch_cntr[13] + ch_cntr[14] + ch_cntr[15] +
		ch_cntr[16] + ch_cntr[17] + ch_cntr[18] + ch_cntr[19] + ch_cntr[20] + ch_cntr[21] + ch_cntr[22] + ch_cntr[23] +
		ch_cntr[24] + ch_cntr[25] + ch_cntr[26] + ch_cntr[27] + ch_cntr[28] + ch_cntr[29] + ch_cntr[30] + ch_cntr[31];
										
	reg			[7:0]			ch_cntr[0:31];
	reg			[7:0]			ch_mask[0:31];
	reg			[15:0]			out_data_len;
	integer i;
	
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin
			out_data_len <= 16'd0;
			for(i = 0; i < 32; i = i + 1) begin
				ch_cntr[i] <= 8'd0;
				ch_mask[i] <= 8'd0;
			end
		end
		else begin
			if(sync_pulse) begin
				out_data_len <= data_length;
				for(i = 0; i < 32; i = i + 1) begin
					ch_mask[i] <= ch_cntr[i];
					ch_cntr[i] <= 8'd0;
				end
			end
			else 
				if(i_valid)
					if(~&{ch_cntr[ch_number][6:0]})		// ch_cntr[ch] < 128
						ch_cntr[ch_number] <= ch_cntr[ch_number] + 8'd1;
		end
		
	assign o_out_data =
		rd_step == 4'd0 ? {ch_mask[0],  ch_mask[1],  ch_mask[2],  ch_mask[3]}  :
		rd_step == 4'd1 ? {ch_mask[4],  ch_mask[5],  ch_mask[6],  ch_mask[7]}  :
		rd_step == 4'd2 ? {ch_mask[8],  ch_mask[9],  ch_mask[10], ch_mask[11]} :
		rd_step == 4'd3 ? {ch_mask[12], ch_mask[13], ch_mask[14], ch_mask[15]} :
		rd_step == 4'd4 ? {ch_mask[16], ch_mask[17], ch_mask[18], ch_mask[19]} :
		rd_step == 4'd5 ? {ch_mask[20], ch_mask[21], ch_mask[22], ch_mask[23]} :
		rd_step == 4'd6 ? {ch_mask[24], ch_mask[25], ch_mask[26], ch_mask[27]} :
		rd_step == 4'd7 ? {ch_mask[28], ch_mask[29], ch_mask[30], ch_mask[31]} : rd_data;
		
	assign o_out_valid = 
		(rd_step >= 4'd0 && rd_step <= 4'd7) ? 1'b1 : 
		(rd_step == 4'd8 && out_wn < ch_mask[out_ch]) ? 1'b1 : 1'b0;
		
	reg			[1:0]			mem_ws;
	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			mem_ws <= 2'd0;
		else begin
			mem_ws <= {mem_ws[0], 1'b1};
		end
		
	assign rd_addr = {4'd0, out_ch, out_wn[6:0]};
		
	reg			[4:0]			out_ch;
	reg			[7:0]			out_wn;

	reg			[3:0]			rd_step;
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin
			rd_step <= 4'hF;
			out_ch <= 5'd0;
			out_wn <= 8'd0;
		end
		else
			if(sync_pulse) begin
				rd_step <= 4'd0;
				out_ch <= 5'd0;
				out_wn <= 8'd0;
			end
			else
				if(i_out_ready)
					if(~&{rd_step}) begin
						if(~rd_step[3])
							rd_step <= rd_step + 4'd1;
						else begin
							if(out_wn + 8'd1 < ch_mask[out_ch])
								out_wn <= out_wn + 8'd1;
							else
								if(~&{out_ch}) begin
									out_ch <= out_ch + 5'd1;
									out_wn <= 8'd0;
								end
								else
									rd_step <= 4'hF;
						end
					end
endmodule

