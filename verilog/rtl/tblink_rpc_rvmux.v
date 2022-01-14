/****************************************************************************
 * tblink_rpc_rvmux.v
 ****************************************************************************/
`include "rv_macros.svh"

  
/**
 * Module: tblink_rpc_rvmux
 * 
 * TODO: Add module documentation
 */
module tblink_rpc_rvmux(
		input			clock,
		input			reset,
		`RV_TARGET_PORT(i0_, 8),
		`RV_TARGET_PORT(i1_, 8),
		`RV_INITIATOR_PORT(o_, 8)
		);
	
	reg i_en;
	reg[1:0]		state;
	reg[7:0]		count;
	
	assign o_dat = (i_en)?i1_dat:i0_dat;
	assign o_valid = (|state & ((i_en & i1_valid) | (!i_en & i0_valid)));
	assign i0_ready = (|state & !i_en & o_ready);
	assign i1_ready = (|state & i_en & o_ready);
	
	always @(posedge clock or posedge reset) begin
		if (reset) begin
			i_en <= 1'b0;
			state <= 2'b00;
			count <= {8{1'b0}};
		end else begin
			case (state) 
				2'b00: begin // Wait for an incoming request
					// TODO: likely want to add in round-robin arbitration
					if (i0_valid) begin
						i_en <= 1'b0;
						state <= 2'b01;
					end else if (i1_valid) begin
						i_en <= 1'b1;
						state <= 2'b01;
					end
				end
				
				2'b01: begin // Complete header transfer
					if (o_ready && o_valid) begin
						state <= 2'b10;
					end
				end
				
				2'b10: begin // Capture size
					if (o_ready && o_valid) begin
						state <= 2'b11;
						count <= o_dat;
					end
				end
				
				2'b11: begin // Complete payload
					if (o_ready && o_valid) begin
						if (count == 8'b0) begin
							state <= 2'b00;
						end
						count <= count - 1'b1;
					end
				end
			endcase
		end
	end

endmodule

