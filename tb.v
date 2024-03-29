`timescale 10 us / 1 us

module tb();

	reg			[0:0]			rst_n;
	reg			[0:0]			clk;
	
	initial begin
		$dumpfile("dumpfile_mem_copy.vcd");
		$dumpvars(0);
		rst_n <= 1'b0;
		clk <= 1'b0;
		#5
		rst_n <= 1'b1;
		forever begin
			#5
			clk <= ~clk;
		end
	end
	
	initial begin
		#100000
		$finish();
	end
	
	reg			[0:0]			sync;
	initial begin
		#5
		sync <= 1'b0;
		#20
		sync <= 1'b1;
		#2000
		sync <= 1'b0;
		#20
		sync <= 1'b1;
		#30000
		sync <= 1'b0;
		#20
		sync <= 1'b1;
		#30000
		sync <= 1'b0;
		#20
		sync <= 1'b1;
	end
	
	reg			[0:0]			rcv_rdy;
	initial begin
		rcv_rdy <= 1'b1;
		#34785
		rcv_rdy <= 1'b0;
		#100
		rcv_rdy <= 1'b1;
	end
	
	reg			[31:0]			data;
	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			data <= 32'h01020304;
		else
			data <= data + 32'd1;
			
	wire						sync_pulse;
	reg			[31:0]			data_len;
	reg			[3:0]			dl_dly;
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin
			data_len <= 32'd0;
			dl_dly <= 4'd0;
		end
		else
			if(sync_pulse) begin
				data_len <= 32'd0;
				dl_dly <= 4'd0;
			end
			else
				if(&{dl_dly}) begin
					data_len <= data_len + 1'd1;
					dl_dly <= 4'd0;
				end
				else
					dl_dly <= dl_dly + 4'd1;

	wire		[7:0]			rd_addr;
	wire		[31:0]			rd_data;
	
	wire						def_wr_n;
	
	reg			[0:0]			rd_dly;
	initial rd_dly <= 1'b0;
	always @ (posedge clk)
		rd_dly <= rd_addr[0];
	
	assign rd_data = def_wr_n == 1'b0 ? 32'hZZZZZZZZ : (rd_addr[0] ? data : data_len);
			
	reg			[7:0]		ch_data_l;
	reg			[3:0]		ch_number_l;
	reg			[31:0]		master_frame_l;
	reg			[0:0]		complite_l;
	
	reg			[7:0]		ch_data_r;
	reg			[3:0]		ch_number_r;
	reg			[31:0]		master_frame_r;
	reg			[0:0]		complite_r;
	
	wire					rdy_l;
	wire					rdy_r;
	
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin
			ch_data_l <= 8'd0;
			ch_number_l <= 4'd0;
			master_frame_l <= 32'd0;
			complite_l <= 1'b0;
		end
		else begin
			if(sync_pulse) begin
				ch_data_l <= 8'd0;
				ch_number_l <= 4'd0;
				master_frame_l <= 32'd0;
				complite_l <= 1'b0;
			end 
			else begin
				if(rdy_l) begin
					if(~&{ch_data_l[4:0]})
						ch_data_l <= ch_data_l + 4'd1;
					else begin
						if(~&{ch_number_l}) begin
							ch_data_l <= 8'd0;
							ch_number_l <= ch_number_l + 4'd1;
						end
						else
							complite_l <= 1'b1;
					end
				end
			end
		end
		
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin
			ch_data_r <= 8'd0;
			ch_number_r <= 4'd0;
			master_frame_r <= 32'd0;
			complite_r <= 1'b0;
		end
		else begin
			if(sync_pulse) begin
				ch_data_r <= 8'd0;
				ch_number_r <= 4'd0;
				master_frame_r <= 32'd0;
				complite_r <= 1'b0;
			end 
			else begin
				if(rdy_r) begin
					if(~&{ch_data_r[4:0]})
						ch_data_r <= ch_data_r + 4'd1;
					else begin
						if(~&{ch_number_r}) begin
							ch_data_r <= 8'd0;
							ch_number_r <= ch_number_r + 4'd1;
						end
						else
							complite_r <= 1'b1;
					end
				end
			end
		end
		
	reg			[0:0]			out_rdy;
	initial begin
		out_rdy <= 1'b1;
		#2195
		out_rdy <= 1'b0;
		#100
		out_rdy <= 1'b1;
	end
		
	data_stream data_stream_unit(
		.rst_n(rst_n),
		.clk(clk),
		
		.i_l_data({ ch_number_l, 24'd0, ch_data_l}),
		.i_l_valid(~complite_l),
		.o_l_ready(rdy_l),
		
		.i_r_data({ ch_number_r, 24'hFFFFFF, ch_data_r}),
		.i_r_valid(~complite_r),
		.o_r_ready(rdy_r),
		
		.o_sync_pulse(sync_pulse),
		
		.i_out_ready(out_rdy),
				
		.i_sync(sync)
	);
	
endmodule

