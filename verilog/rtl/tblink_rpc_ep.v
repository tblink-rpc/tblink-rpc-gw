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

	reg[3:0]			net_o_state;
	reg[7:0]			neto_dat_r;
	
	initial begin
		if (ADDR == 0) begin
			$display("%m Error: ADDR==0 is reserved");
			$finish;
		end
	end

	reg[3:0]			net_i_state;
	reg[7:0]			net_i_dat_tmp;
	reg[8:0]			net_i_count;
	
	assign neti_ready = (
			net_i_state == 4'b0000 ||
			net_i_state == 4'b0010 ||
			net_i_state == 4'b0100 ||
			net_i_state == 4'b1000 ||
			net_i_state == 4'b1011
		);
			
	
	// TODO: need to pipeline interactions to prevent 
	// inserting a bubble
		
	/*
	 * Network-in management process
	 * - Accept data from network-in 
	 * - Route it either to either the TIP or network
	 * 
	 */
	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			net_i_state <= 4'b0;
			net_i_dat_tmp <= {8{1'b0}};
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
							net_i_dat_tmp <= neti_dat;
							net_i_state <= 4'b0001;
						end
					end
				end
				
				// Target: Network Output
				4'b0001: begin // Network Output: Re-send header
					if (neto_valid && neto_ready) begin
						net_i_state <= 4'b0010;
					end
				end
				4'b0010: begin // Network Output: Capture the count
					if (neti_valid && neti_ready) begin
						net_i_count <= (neti_dat + 1'b1);
						net_i_dat_tmp <= neti_dat;
						net_i_state <= 4'b0011;
					end
				end
				4'b0011: begin // Network Output: Send data to network
					if (neto_valid && neto_ready) begin
						if (net_i_count == 9'b0) begin
							// Packet complete. Back to beginning
							net_i_state <= 4'b0000;
						end else begin
							// Capture next byte
							net_i_state <= 4'b0100;
						end
						net_i_count <= net_i_count - 1'b1;
					end
				end
				
				4'b0100: begin // Network Output: Capture input data
					if (neti_valid && neti_ready) begin
						net_i_dat_tmp <= neti_dat;
						net_i_state <= 4'b0011;
					end
				end
				
				// Target: TIP
				
				4'b1000: begin // TIP Output: Capture the count
					if (neti_valid && neti_ready) begin
						net_i_count <= (neti_dat + 1'b1);
						net_i_dat_tmp <= neti_dat;
						net_i_state <= 4'b1001;
					end
				end
				
				4'b1001: begin // TIP Output: Send data to TIP
					if (neto_valid && neto_ready) begin
						if (net_i_count == 9'b0) begin
							// Packet complete
							net_i_state <= 4'b0000;
						end else begin
							net_i_state <= 4'b1011;
						end
						net_i_count <= net_i_count - 1'b1;
					end
				end
				
				4'b1011: begin // TIP Output: Capture next input
					if (neti_valid && neti_ready) begin
						net_i_dat_tmp <= neti_dat;
						net_i_state <= 4'b1001;
					end
				end
			endcase
		end
	end
	
	assign neto_valid = (net_i_state == 4'b1001);
	
	/*
	 * Network-out management process
	 */
	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			net_o_state <= 4'b0;
		end else begin
			case (net_o_state)
				4'b0000: begin // Wait for an incoming request
				end
			endcase
		end
	end

endmodule


