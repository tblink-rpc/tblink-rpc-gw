/****************************************************************************
 * tblink_rpc_rvdemux.v
 ****************************************************************************/
`include "rv_macros.svh"
  
/**
 * Module: tblink_rpc_rvdemux
 * 
 * TODO: Add module documentation
 */
module tblink_rpc_rvdemux #(parameter ADDR=0)(
		input			clock,
		input			reset,
		`RV_TARGET_PORT(i_, 8),
		`RV_INITIATOR_PORT(oa_, 8),
		`RV_INITIATOR_PORT(op_, 8)
		);

	reg sel_a;
	reg[7:0] count;
	reg[1:0] state;
	assign i_ready = (|state & (
				(sel_a&oa_ready)|(!sel_a & op_ready)));
	assign oa_valid = (|state & sel_a & i_valid);
	assign op_valid = (|state & !sel_a & i_valid);
	assign oa_dat = i_dat;
	assign op_dat = i_dat;

	/*
	 * Network-in management process
	 * - Accept data from network-in 
	 * - Route it either to either the TIP or network
	 * 
	 */
	always @(posedge clock or posedge reset) begin
		if (reset) begin
			sel_a <= 1'b0;
			count <= {8{1'b0}};
			state <= {2{1'b0}};
		end else begin
			case (state)
				2'b00: begin // Receive header
					if (i_valid) begin
						// Received the header. Based on the 
						// destination, we either propagate to 
						// the address-match interface or send
						// on to the passthrough
						sel_a = (i_dat[6:0] == ADDR);
						state <= 2'b01;
					end
				end
				
				2'b01: begin // Complete sending the header
					if (i_valid && i_ready) begin
						state <= 2'b10;
					end
				end

				2'b10: begin // Network Output: Capture the count
					if (i_valid && i_ready) begin
						count <= i_dat;
						state <= 2'b11;
					end
				end
				2'b11: begin // Network Output: Send data to network
					if (i_valid && i_ready) begin
						if (count == 8'b0) begin
							// Packet complete. Back to beginning
							state <= 2'b00;
						end
						count <= count - 1'b1;
					end
				end
			endcase
		end
	end

endmodule


