/****************************************************************************
 * tblink_rpc_ep.v
 ****************************************************************************/
`include "rv_macros.svh"

/**
 * Module: tblink_rpc_ep
 * 
 * Passthrough endpoint that manages routing traffic to/from TIP
 */
module tblink_rpc_ep #(parameter ADDR=1) (
		input			uclock,
		input			reset,
		input			hreq_i,			// Halt request input
		output			hreq_o,			// Halt request output
		`RV_TARGET_PORT(neti_, 8),		// Input from the network
		`RV_INITIATOR_PORT(neto_, 8),	// Output to the network
		`RV_INITIATOR_PORT(tipo_, 8),	// Output to the TIP
		`RV_TARGET_PORT(tipi_, 8)		// Input from the TIP
		);

	initial begin
		if (ADDR == 0) begin
			$display("%m Error: ADDR==0 is reserved");
			$finish;
		end
	end

	reg[3:0]			net_i_state;
	reg[8:0]			net_i_count;
	
	// TODO: need to pipeline interactions to prevent 
	// inserting a bubble
	
	`RV_WIRES(neti2neto_b_, 8);
	`RV_WIRES(neti_b2neto_, 8);
	`RV_WIRES(neti2tipo_b_, 8);
	
	`RV_WIRES(tipi2neto_b_, 8);
	`RV_WIRES(tipi_b2neto_, 8);
	
	assign tipi2neto_b_dat = tipi_dat;
	assign tipi_ready = tipi2neto_b_ready;
	assign tipi2neto_b_valid = tipi_valid;
	
	fw_rv_buffer #(
		.WIDTH    (8   )
		) u_neti2neto_b (
		.clock    (uclock  ), 
		.reset    (reset   ), 
		`RV_CONNECT(i_, neti2neto_b_),
		`RV_CONNECT(o_, neti_b2neto_)
		);
	
	assign neti2neto_b_dat = neti_dat;
	
	assign neti_ready = (
			(net_i_state == 4'b0000) ||
 			(net_i_state == 4'b0001 && neti2neto_b_ready) ||
 			(net_i_state == 4'b0010 && neti2neto_b_ready) ||
 			(net_i_state == 4'b0011 && neti2neto_b_ready) ||
 			((net_i_state == 4'b1000 ||
 				net_i_state == 4'b1001) && neti2tipo_b_ready)
		);
	assign neti2neto_b_valid = (
			((net_i_state == 4'b0000 && neti_dat[6:0] != ADDR) ||
			(net_i_state == 4'b0010) ||
			(net_i_state == 4'b0011)
			) & neti_valid & neti_ready
		);
	
	`RV_WIRES(tipo_b2tipo_, 8);
	
	fw_rv_buffer #(
		.WIDTH    (8   )
		) u_neti2tipo_b (
		.clock    (uclock  ), 
		.reset    (reset   ), 
		`RV_CONNECT(i_, neti2tipo_b_),
		`RV_CONNECT(o_, tipo_b2tipo_)
		);
	
	assign neti2tipo_b_valid = (
			(net_i_state == 4'b1000 ||
				net_i_state == 4'b1001
			) & neti_valid & neti_ready
		);
	assign neti2tipo_b_dat = neti_dat;

	fw_rv_buffer #(
		.WIDTH    (8   )
		) u_tipi2neto_b (
		.clock    (uclock  ), 
		.reset    (reset   ), 
		`RV_CONNECT(i_, tipi2neto_b_),
		`RV_CONNECT(o_, tipi_b2neto_)
		);
		
	/*
	 * Network-in management process
	 * - Accept data from network-in 
	 * - Route it either to either the TIP or network
	 * 
	 */
	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			net_i_state <= 4'b0;
			net_i_count <= {9{1'b0}};
		end else begin
			case (net_i_state)
				4'b0000: begin // Receive header
					if (neti_valid && neti_ready) begin
						// Received the header. Based on the 
						// destination, we either propagate to 
						// the local TIP or to the next EP on
						// the network.
						if (neti_dat[6:0] == ADDR) begin
							// This goes to the local TIP. The TIP
							// doesn't care about the address header, so
							// proceed by sending the 'count'
							net_i_state <= 4'b1000;
						end else begin
							// Direct to the net-out interface. We
							// must preserve the header in this case.
							net_i_state <= 4'b0010;
						end
					end
				end

				4'b0010: begin // Network Output: Capture the count
					if (neti_valid && neti_ready) begin
						net_i_count <= neti_dat;
						net_i_state <= 4'b0011;
					end
				end
				4'b0011: begin // Network Output: Send data to network
					if (neti_valid && neti_ready) begin
						if (net_i_count == 9'b0) begin
							// Packet complete. Back to beginning
							net_i_state <= 4'b0000;
						end
						net_i_count <= net_i_count - 1'b1;
					end
				end
				
				// Target: TIP
			
				4'b1000: begin // TIP Output: Capture the count
					if (neti_valid && neti_ready) begin
						net_i_count <= (neti_dat+1'b1);
						net_i_state <= 4'b1001;
					end
				end
				
				4'b1001: begin // TIP Output: Send data to TIP
					if (tipo_valid && tipo_ready) begin
						if (net_i_count == 9'b0) begin
							// Packet complete
							net_i_state <= 4'b0000;
						end
						net_i_count <= net_i_count - 1'b1;
					end
				end
			endcase
		end
	end

	assign tipo_valid = tipo_b2tipo_valid;
	assign tipo_b2tipo_ready = tipo_ready;
	assign tipo_dat = tipo_b2tipo_dat;

	/*
	 * Network-out management process. Because net-o has
	 * two possible sources, this process implementations
	 * arbitration
	 */
	
	reg[3:0]			net_o_state;
	reg[7:0]			net_o_count;
	
	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			net_o_state <= 4'b0;
			net_o_count <= {8{1'b0}};
		end else begin
			case (net_o_state)
				4'b0000: begin // Wait for an incoming request
					if (neti_b2neto_valid) begin
						net_o_state <= 4'b0001;
					end else if (tipi_b2neto_valid) begin
						net_o_state <= 4'b0100;
					end
				end
				4'b0001: begin // neti->neto header
					if (neti_b2neto_valid && neti_b2neto_ready) begin
						net_o_state <= 4'b0010;
					end
				end
				4'b0010: begin // neti->neto size
					if (neti_b2neto_valid && neti_b2neto_ready) begin
						net_o_state <= 4'b0011;
						net_o_count <= neto_dat;
					end
				end
				4'b0011: begin // neti->neto payload
					if (neti_b2neto_valid && neti_b2neto_ready) begin
						if (net_o_count == 0) begin
							net_o_state <= 4'b0000;
						end
						net_o_count <= net_o_count - 1'b1;
					end
				end
				4'b0100: begin // tipi-neto header
					if (tipi_b2neto_valid && tipi_b2neto_ready) begin
						net_o_state <= 4'b0101;
					end
				end
				4'b0101: begin // tipi-neto size
					if (tipi_b2neto_valid && tipi_b2neto_ready) begin
						net_o_state <= 4'b0110;
						net_o_count <= neto_dat;
					end
				end
				4'b0110: begin // tipi->neto payload
					if (tipi_b2neto_valid && tipi_b2neto_ready) begin
						if (net_o_count == 0) begin
							net_o_state <= 4'b0000;
						end
						net_o_count <= net_o_count - 1'b1;
					end
				end
			endcase
		end
	end
	
	assign neto_valid = (
			(net_o_state[2] == 1'b0 & |net_o_state[1:0] & neti_b2neto_valid) ||
			(net_o_state[2] == 1'b1 & tipi_b2neto_valid));
	assign neti_b2neto_ready = (
			(net_o_state[2] == 1'b0 & |net_o_state[1:0] & neto_ready)
		);
	assign tipi_b2neto_ready = (
			(net_o_state[2] == 1'b1 & neto_ready)
		);
	assign neto_dat = (net_o_state[2])?tipi_b2neto_dat:neti_b2neto_dat;
	
endmodule


