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
	
	output			[15:0]			o_out_data_len,
	
	output			[31:0]			o_out_data,
	output							o_out_valid,
	input							i_out_ready	
);

	assign o_out_data_len = out_data_len;

	data_buf data_buf_unit(
		.clock(clk),
		.data()
	);
	
	reg			[0:0]			prev_sync;
	always @ (posedge clk) prev_sync <= i_sync;
	
	wire						sync_pulse;
	assign sync_pulse = ~prev_sync & i_sync ? 1'b1 : 1'b0;
	
	reg			[7:0]			r_step;
	
	reg			[0:0]			buf_half;
	
	wire		[15:0]			data_length
	assign data_length = 
		ch_cntr[0]  + ch_cntr[1]  + ch_cntr[2]  + ch_cntr[3]  + ch_cntr[4]  + ch_cntr[5]  + ch_cntr[6]  + ch_cntr[7]  +
		ch_cntr[8]  + ch_cntr[9]  + ch_cntr[10] + ch_cntr[11] + ch_cntr[12] + ch_cntr[13] + ch_cntr[14] + ch_cntr[15] +
		ch_cntr[16] + ch_cntr[17] + ch_cntr[18] + ch_cntr[19] + ch_cntr[20] + ch_cntr[21] + ch_cntr[22] + ch_cntr[23] +
		ch_cntr[24] + ch_cntr[25] + ch_cntr[26] + ch_cntr[27] + ch_cntr[28] + ch_cntr[29] + ch_cntr[30] + ch_cntr[31];
			
	wire						data_vld;
	assign data_vld = buf_half == 1'b0 ? i_l_valid : i_r_valid;
	
	wire		[35:0]			data;
	assign data = buf_half == 1'b0 ? i_l_data : i_r_data;
	
	wire		[4:0]			ch;
	assign ch = {buf_half, data[35:32]};
	
	wire		[15:0]			mem_wr_addr;
	assign mem_wr_addr = (buf_half == 1'b0 ? 15'd0 : 15'd4096) + ch ;
	
	wire						data_valid;
	assign mem_wr = ~&{ch_cntr[ch][5:0]} ? data_vld;
		
		
	wire						wr_rdy;
	assign wr_rdy = i_l_valid;
	reg			[1:0]			wr_ws;
	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			wr_ws <= 2'd0;
		else
			wr_ws <= {wr_ws[0], wr_rdy};
	
	reg			[7:0]			ch_cntr[0:31];
	reg			[7:0]			ch_mask[0:31];
	reg			[15:0]			out_data_len;
	reg			[7:0]			ch_num;
	reg			[7:0]			wd_num;
	integer i;
	
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin
			r_step <= 8'd0;
			buf_half <= 1'b0;
			out_data_len <= 16'd0;
			ch_num <= 8'd0;
			wd_num <= 8'd0;
			for(i = 0; i < 32; i = i + 1) begin
				ch_cntr[i] <= 8'd0;
				ch_mask[i] <= 8'd0;
			end
		end
		else begin
			if(sync_pulse) begin
				r_step <= 8'd1;
				out_data_len <= data_length;
				ch_num <= 8'd0;
				wd_num <= 8'd0;
				for(i = 0; i < 32; i = i + 1) begin
					ch_mask[i] <= ch_cntr[i];
					ch_cntr[i] <= 8'd0;
				end
			end
			else begin				
				if(r_step == 8'd1) begin
				end
				else begin
				end
			end
		end
		
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin
		end

endmodule
