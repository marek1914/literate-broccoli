module tb_fpga();
	// Test ports
	reg A, B;
	reg carryin;
	wire out;
	wire testout;
	wire carryout;
	// Configuration ports
	reg [899:0] brbselect;
	reg [1727:0] bsbselect;
	reg [79:0] lbselect;
	reg [29:0] leftioselect;
	reg [29:0] rightioselect;
	reg [29:0] topioselect;
	reg [29:0] bottomioselect;

	wire [4:0] left, right, top, bottom;

	assign bottom[0] = A;
	assign bottom[2] = B;
	assign bottom[4] = carryin;
	assign out = top[0];
	assign testout = top[1];
	assign carryout = top[4];

	fpga_top f1(
		clk, 
		brbselect, bsbselect, lbselect, 
		leftioselect, rightioselect, topioselect, bottomioselect, 
		left, right, top, bottom
	);
	reg k;
	initial begin
		brbselect = 900'b0;
		bsbselect = 1728'b0;
		lbselect = 80'b0;
		leftioselect = 30'b0;
		rightioselect = 30'b0;
		topioselect = 30'b0;
		bottomioselect = 30'b0;
		$display("initialized memory");

		set_bottom_io_cfg(0, 0, 1); // Bottom left in (A)
		set_bottom_io_cfg(2, 1, 1); // Bottom middle in (B)
		set_bottom_io_cfg(4, 2, 1); // Bottom right in (Carry in)
		set_top_io_cfg(0, 0, 2); // Top left out (Sum)
			set_top_io_cfg(1, 1, 2); // test out

		// Route A from BL to (4, 0) and turn right
		set_brb_cfg(0, 0, 0, 3, 1);
		set_brb_cfg(1, 0, 0, 3, 1);
		set_brb_cfg(2, 0, 0, 3, 1);
		set_brb_cfg(3, 0, 0, 3, 1);
		set_brb_cfg(4, 0, 0, 5, 2);
		// set_brb_cfg(4, 0, 0, 3, 1);
		
		// Route B from BM to (4, 1) and turn left 
		set_brb_cfg(0, 2, 1, 3, 1);
		set_brb_cfg(1, 2, 1, 3, 1);
		set_brb_cfg(2, 2, 1, 3, 1);
		set_brb_cfg(3, 2, 1, 3, 1);
		// set_brb_cfg(4, 2, 1, 3, 1);
		set_brb_cfg(4, 2, 1, 2, 1);
		
		set_bsb_cfg(3, 1, 1, 2, 1, 1);
		set_bsb_cfg(3, 1, 1, 1, 1, 1);
		set_bsb_cfg(3, 1, 1, 0, 1, 1);
		
		// set_brb_cfg(4, 1, 1, 4, 1);
		set_brb_cfg(4, 1, 1, 1, 1);

		// Route XOR out to top left
		// Accept a signal from the right and put it out the top
		set_brb_cfg(4, 0, 2, 5, 2);

		// Configure the switch block above the top left logic cell
		// signal zero
		set_bsb_cfg(3, 0, 0, 0, 2, 2); // left to bottom
		// signal one
		set_bsb_cfg(3, 0, 1, 2, 1, 1); // right to left
		set_bsb_cfg(3, 0, 1, 1, 5, 2); // right to bottom
		set_bsb_cfg(3, 0, 0, 1, 3, 2); // top to bottom
		// signal two
		set_bsb_cfg(3, 0, 0, 2, 3, 1); // bottom to top
		set_bsb_cfg(3, 0, 1, 2, 3, 1); // bottom to top
		set_bsb_cfg(3, 0, 2, 2, 2, 1); // bottom to left
		set_bsb_cfg(3, 0, 2, 1, 1, 1); // right to left
		set_bsb_cfg(3, 0, 2, 0, 1, 1); // right to left

		// Place "gates"
		// XOR
		set_lb_cfg(3, 0, 4'b0110, 1'b0);

		$display("finished setting bits.");

		A = 1'b0; B = 1'b0; carryin = 1'b0;
		$monitor("A = %b, B = %b, out = %b, testout = %b",
				A, B, out, testout);
		#10 A = 1'b0; B = 1'b0;
		#10 A = 1'b1; B = 1'b0;
		#10 A = 1'b0; B = 1'b1;
		#10 A = 1'b1; B = 1'b1;
	end
	task set_top_io_cfg;
		input integer io_index, io_line, io_dir;
		begin
			if (io_dir == 0) begin // Off
				topioselect[io_index*6+io_line*2+0] = 1'b0;
				topioselect[io_index*6+io_line*2+1] = 1'b0;
			end else if (io_dir == 1) begin // Out
				$display("set bit %d in top", io_index*6+io_line*2+1);
				topioselect[io_index*6+io_line*2+0] = 1'b0;
				topioselect[io_index*6+io_line*2+1] = 1'b1;
			end else if (io_dir == 2) begin // In
				$display("set bit %d in top", io_index*6+io_line*2+0);
				topioselect[io_index*6+io_line*2+0] = 1'b1;
				topioselect[io_index*6+io_line*2+1] = 1'b0;
			end
		end
	endtask

	task set_bottom_io_cfg;
		input integer io_index, io_line, io_dir;
		begin
			if (io_dir == 0) begin // Off
				bottomioselect[io_index*6+io_line*2+0] = 1'b0;
				bottomioselect[io_index*6+io_line*2+1] = 1'b0;
			end else if (io_dir == 1) begin // Out
				$display("set bit %d in bottom", io_index*6+io_line*2+1);
				bottomioselect[io_index*6+io_line*2+0] = 1'b0;
				bottomioselect[io_index*6+io_line*2+1] = 1'b1;
			end else if (io_dir == 2) begin // In
				$display("set bit %d in bottom", io_index*6+io_line*2+0);
				bottomioselect[io_index*6+io_line*2+0] = 1'b1;
				bottomioselect[io_index*6+io_line*2+1] = 1'b0;
			end
		end
	endtask

	task set_left_io_cfg;
		input integer io_index, io_line, io_dir;
		begin
			if (io_dir == 0) begin // Off
				leftioselect[io_index*6+io_line*2+0] = 1'b0;
				leftioselect[io_index*6+io_line*2+1] = 1'b0;
			end else if (io_dir == 1) begin // Out
				$display("set bit %d in left", io_index*6+io_line*2+1);
				leftioselect[io_index*6+io_line*2+0] = 1'b0;
				leftioselect[io_index*6+io_line*2+1] = 1'b1;
			end else if (io_dir == 2) begin // In
				$display("set bit %d in left", io_index*6+io_line*2+0);
				leftioselect[io_index*6+io_line*2+0] = 1'b1;
				leftioselect[io_index*6+io_line*2+1] = 1'b0;
			end
		end
	endtask

	task set_right_io_cfg;
		input integer io_index, io_line, io_dir;
		begin
			if (io_dir == 0) begin // Off
				rightioselect[io_index*6+io_line*2+0] = 1'b0;
				rightioselect[io_index*6+io_line*2+1] = 1'b0;
			end else if (io_dir == 1) begin // Out
				$display("set bit %d in right", io_index*6+io_line*2+1);
				rightioselect[io_index*6+io_line*2+0] = 1'b0;
				rightioselect[io_index*6+io_line*2+1] = 1'b1;
			end else if (io_dir == 2) begin // In
				$display("set bit %d in right", io_index*6+io_line*2+0);
				rightioselect[io_index*6+io_line*2+0] = 1'b1;
				rightioselect[io_index*6+io_line*2+1] = 1'b0;
			end
		end
	endtask

	task set_brb_cfg;
		input integer row, col;
		// which switch element, which internal switch
		input integer s_index, s_sel;
		input integer dir;
		begin
			if (dir == 0) begin // Off
				brbselect[col*36 + row*180 + s_index*12 + s_sel*2] = 1'b0;
				brbselect[col*36 + row*180 + s_index*12 + s_sel*2 + 1] = 1'b0;
			end else if (dir == 1) begin // In
				brbselect[col*36 + row*180 + s_index*12 + s_sel*2] = 1'b0;
				brbselect[col*36 + row*180 + s_index*12 + s_sel*2 + 1] = 1'b1;
			end else if (dir == 2) begin // Out
				brbselect[col*36 + row*180 + s_index*12 + s_sel*2] = 1'b1;
				brbselect[col*36 + row*180 + s_index*12 + s_sel*2 + 1] = 1'b0;
			end
		end
	endtask

	task set_bsb_cfg;
		input integer row, col;
		// which switch element, which internal switch
		input integer s_row, s_col, s_sel;
		input integer dir;
		begin
			if (dir == 0) begin // Off
				bsbselect[col*108 + row*432 + s_col*12 + s_row*36 + s_sel*2] = 1'b0;
				bsbselect[col*108 + row*432 + s_col*12 + s_row*36 + s_sel*2 + 1] = 1'b0;
			end else if (dir == 1) begin // In
				bsbselect[col*108 + row*432 + s_col*12 + s_row*36 + s_sel*2] = 1'b0;
				bsbselect[col*108 + row*432 + s_col*12 + s_row*36 + s_sel*2 + 1] = 1'b1;
			end else if (dir == 2) begin // Out
				bsbselect[col*108 + row*432 + s_col*12 + s_row*36 + s_sel*2] = 1'b1;
				bsbselect[col*108 + row*432 + s_col*12 + s_row*36 + s_sel*2 + 1] = 1'b0;
			end
		end
	endtask

	task set_lb_cfg;
		input integer row, col;
		input [3:0] truth_tbl;
		input sync;
		begin
			lbselect[col*5 + row * 20] = truth_tbl[0];
			lbselect[col*5 + row * 20 + 1] = truth_tbl[1];
			lbselect[col*5 + row * 20 + 2] = truth_tbl[2];
			lbselect[col*5 + row * 20 + 3] = truth_tbl[3];
			lbselect[col*5 + row * 20 + 4] = sync;
		end
	endtask

endmodule

