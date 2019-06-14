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
	
	wire		[7:0]			ch_addr;
	wire		[31:0]			ch_data;
	wire						ch_wr_n;
	
	reg			[7:0]			sch;
	initial begin
		sch <= 8'd10;
		#10000
		#10000
		#10000
		#10000
		sch <= 8'd12;
		#10000
		sch <= 8'd11;
		#10000
		#10000
		sch <= 8'd1;
		#10000
		sch <= 8'd12;
	end

	data_stream data_stream_unit(
		.rst_n(rst_n),
		.clk(clk),
		
		.i_sync(sync)
	);
	
endmodule

