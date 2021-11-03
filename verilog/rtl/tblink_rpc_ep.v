/****************************************************************************
 * tblink_rpc_ep.v
 ****************************************************************************/
`include "rv_macros.svh"

  
/**
 * Module: tblink_rpc_ep
 * 
 * TODO: Add module documentation
 */
module tblink_rpc_ep #(
		parameter N_INTERFACE_INSTS=1
		) (
		input			clock,
		input			reset,
		output			cclock,
		`RV_TARGET_PORT(t_, 8),
		`RV_INITIATOR_PORT(i_, 8),
		input[7:0]		dat_i
		);

	reg			cclock_r;
	assign cclock = cclock_r;
	
	always @(posedge clock or posedge reset) begin
		if (reset) begin
			cclock_r <= 0;
		end else begin
			if (cclock_en) begin
				cclock_r <= ~cclock_r;
			end
		end
	end
	
	reg[3:0]   	state;
	reg[7:0] 	clk_count;
	reg[7:0]	cmd;
	reg[7:0]	adv_amt;
	reg[7:0]	i_dat_r;
	
	assign cclock_en = (state == 2 && |clk_count);
	
	assign t_ready = (state == 0);
	assign i_valid = (state == 3);
	
	reg[7:0]	rsp[1:0];
	reg[1:0]	rsp_cnt;
	reg[0:0]	rsp_idx;
	assign i_dat = rsp[rsp_idx];
	
	always @(posedge clock or posedge reset) begin
		if (reset) begin
			state <= 4'b0;
			cmd <= {8{1'b0}};
			clk_count <= {8{1'b0}};
			i_dat_r <= {8{1'b0}};
			rsp_cnt <= {2{1'b0}};
			rsp_idx <= {1{1'b0}};
		end else begin
			case (state) 
				0: begin // Idle
					// Wait for a command
					if (t_valid) begin
						cmd <= t_dat;
						state <= 1;
					end
				end
				
				1: begin // Decode command
					case (cmd[1:0]) 
						2'b00: begin // Capture input data
							rsp[0] <= 0; // Data response
							rsp[1] <= dat_i; // Data
							rsp_cnt <= 1;
							rsp_idx <= 0;
							state <= 3; // Send data
						end
						2'b01: begin // Advance for N clocks
							clk_count <= cmd[7:2];
							state <= 2;
						end
					endcase
				end
				2: begin // Advance for N cycles
					if (clk_count == 0) begin
						// Respond
						rsp[0] <= 1; // Event response
						rsp_cnt <= 0;
						rsp_idx <= 0;
						state <= 3; // Send response
					end else begin
						clk_count <= clk_count - 1;
					end
				end
				
				3: begin // Send response data
					if (i_ready && i_valid) begin
						if (rsp_idx == rsp_cnt) begin
							state <= 0;
						end else begin
							rsp_idx <= rsp_idx - 1;
						end
					end
				end
			endcase
		end
	end
endmodule


