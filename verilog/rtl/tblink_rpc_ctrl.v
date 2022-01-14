/****************************************************************************
 * tblink_rpc_ctrl.v
 ****************************************************************************/
`include "rv_macros.svh"

  
/**
 * Module: tblink_rpc_ctrl
 * 
 * TODO: Add module documentation
 */
module tblink_rpc_ctrl(
		input			uclock,
		input			reset,
		output			cclock,
		input			hreq_i,
		
		`RV_TARGET_PORT(t_, 8),
		`RV_INITIATOR_PORT(i_, 8),
		
		`RV_TARGET_PORT(neti_, 8),
		`RV_INITIATOR_PORT(neto_, 8)
		);
	
	`RV_WIRES(t2demux_, 8);
	`RV_WIRES(demux2local_, 8);
	`RV_WIRES(demux2ntipi_, 8); // Output to the network

	tblink_rpc_rvdemux #(
		.ADDR      (0     )
		) u_tdemux (
		.clock     (uclock   ), 
		.reset     (reset    ), 
		`RV_CONNECT(i_, t_),
		`RV_CONNECT(oa_, demux2local_),
		`RV_CONNECT(op_, demux2ntipi_)
		);
	
	assign demux2local_ready = 1'b0;
	
	`RV_WIRES(ntipo2mux_, 8);
	`RV_WIRES(local2mux_, 8);
	
	tblink_rpc_rvmux u_imux (
		.clock     (uclock   ), 
		.reset     (reset    ), 
		`RV_CONNECT(i0_, ntipo2mux_),
		`RV_CONNECT(i1_, local2mux_),
		`RV_CONNECT(o_, i_)
		);
	
	/**
	 * EP connected to host interface
	 */
	tblink_rpc_ep #(
		.ADDR        (0       )
		) u_ep (
		.uclock      (uclock     ), 
		.reset       (reset      ), 
		.hreq_i      (1'b0       ), 
//		.hreq_o      (hreq_o     ), 
		`RV_CONNECT(neti_, neti_),
		`RV_CONNECT(neto_, neto_),
		`RV_CONNECT(tipi_, demux2ntipi_),
		`RV_CONNECT(tipo_, ntipo2mux_)
		);

	wire cclock_en;
	reg[63:0]		cclock_count;
	reg				cclock_r;
	reg				cclock_en_r;
	assign cclock = cclock_r;
	reg[31:0]		cclock_div;
	reg[31:0]		cclock_div_cnt;
	
	assign cclock_en = (cclock_en_r & (cclock_div == cclock_div_cnt));

	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			cclock_r <= 0;
			cclock_div_cnt <= {32{1'b0}};
			cclock_count <= {64{1'b0}};
		end else begin
			if (cclock_en) begin
				if (!cclock_r) begin
					// Count rising clock edges
					cclock_count <= cclock_count + 1'b1;
				end
				cclock_r <= ~cclock_r;
				cclock_div_cnt <= {32{1'b0}};
			end else begin
				cclock_div_cnt <= cclock_div_cnt + 1'b1;
			end
		end
	end
	
	reg[3:0]		local_state;
	
	reg[7:0]		req_buf[5:0];
	reg[2:0]		req_buf_cnt;
	reg[2:0]		req_msg_size;
	
	reg[7:0]		rsp_buf[11:0];
	reg[3:0]		rsp_buf_cnt;
	
	wire req_buf_en;
	assign demux2local_ready = (~local_state[3]);
	assign req_buf_en = (!local_state[3] & demux2local_ready & demux2local_valid);
	
	integer req_buf_i;
	
	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			req_buf_cnt <= 4'b0000;
			local_state <= 4'b0000;
			req_msg_size <= 3'b000;
			cclock_div <= {32{1'b0}};
			cclock_en_r <= 1'b0;
			
			/*
			for (req_buf_i=0; req_buf_i<6; req_buf_i=req_buf_i+1) begin
				req_buf[i] <= req_buf[i-1];
			end
			 */
		end else begin
			// Shift in a new byte when enabled
			if (req_buf_en) begin
				for (req_buf_i=5; req_buf_i>0; req_buf_i=req_buf_i-1) begin
					req_buf[req_buf_i] <= req_buf[req_buf_i-1];
				end
				req_buf[0] <= demux2local_dat;
			end
			case (local_state)
				4'b0000: begin
					if (demux2local_ready && demux2local_valid) begin
						// Receive header
						req_buf_cnt <= 6;
						local_state <= 4'b0001;
					end
				end
				4'b0001: begin // Receive size
					req_msg_size <= demux2local_dat[2:0];
					local_state <= 4'b0010;
				end
				4'b0010: begin // Receive remainder of data
					if (demux2local_ready & demux2local_valid) begin
						if (req_msg_size == 0) begin
							if (|req_buf_cnt) begin
								// Need to handle balance of message shifts
								local_state <= 4'b0011;
							end else begin
								// Shifts are complete
								local_state <= 4'b0100;
							end
						end
						req_buf_cnt <= req_buf_cnt - 1;
						req_msg_size <= req_msg_size - 1;
					end
				end
				4'b0011: begin // Handle remainder of buffer shifts
					if (!(|req_buf_cnt)) begin
						local_state <= 4'b0100;
					end
					req_buf_cnt <= req_buf_cnt-1;
				end
				4'b0100: begin // Handle the command
					rsp_buf[0] <= 8'h00; // DS
					// rsp_buf[1]: total payload size
					rsp_buf[2] <= 8'h01; // RSP
					rsp_buf[3] <= req_buf[1]; // ID
					
					case (req_buf[0][2:0])
						3'b001: begin // GetTime
							rsp_buf[1] <= 8'd10; // Total payload size-1
							rsp_buf[4] <= cclock_count[7:0];
							rsp_buf[5] <= cclock_count[15:8];
							rsp_buf[6] <= cclock_count[23:16];
							rsp_buf[7] <= cclock_count[31:24];
							rsp_buf[8] <= cclock_count[39:32];
							rsp_buf[9] <= cclock_count[47:40];
							rsp_buf[10] <= cclock_count[55:48];
							rsp_buf[11] <= cclock_count[63:56];
							rsp_buf_cnt <= 11;
						end
						3'b010: begin // SetTimer
						end
						3'b011: begin // Release
							// Re-enable clock
							cclock_en_r <= 1'b1;
							rsp_buf[1] <= 8'd00; // Total payload size-1
						end
					endcase
					local_state <= 4'b1000; 
				end
				4'b1000: begin // Send response
					if (1) begin
						if (!(|rsp_buf_cnt)) begin
							if (cclock_en_r) begin
								local_state <= 4'b1001;
							end else begin
								local_state <= 4'b0000;
							end
						end
						rsp_buf_cnt <= rsp_buf_cnt - 1'b1;
					end
				end
				4'b1001: begin // Waiting for an event
					// TODO: timer
					if (hreq_i) begin
						cclock_en_r <= 1'b0;
						local_state <= 4'b0000;
					end
				end
			endcase
		end
	end
	
endmodule


