`timescale 10 us / 1 us

module data_buf(
	input							clock,
	input			[31:0]			data,
	input			[15:0]			rdaddress,
	input			[15:0]			wraddress,
	input							wren,
	output			[31:0]			q
);

	reg				[31:0]			mem_buf[0:8192];
	
	assign q = mem_buf[rdaddress];
	
	always @ (posedge clock)
		if(wren)
			mem_buf[wraddress] <= data;

endmodule

