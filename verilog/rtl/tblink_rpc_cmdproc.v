/****************************************************************************
 * tblink_rpc_cmdproc.v
 ****************************************************************************/
`include "rv_macros.svh"
  
/**
 * Module: tblink_rpc_cmdproc
 * 
 * Manages input/output
 */
module tblink_rpc_cmdproc #(
		parameter CMD_IN_PARAMS_SZ = 1,
		parameter CMD_IN_RSP_SZ = 1,
		parameter CMD_OUT_PARAMS_SZ = 1,
		parameter CMD_OUT_RSP_SZ = 1
		) (
		input								uclock,
		input								reset,
		`RV_TARGET_PORT(tipo_, 8),
		`RV_INITIATOR_PORT(tipi_, 8),
		
		output[7:0]							cmd_in,
		output[7:0]							cmd_in_sz,
		output[(CMD_IN_PARAMS_SZ*8)-1:0]	cmd_in_params,
		output								cmd_in_put_i,
		input								cmd_in_get_i,
		input[(CMD_IN_RSP_SZ*8)-1:0]		cmd_in_rsp,
		input[7:0]							cmd_in_rsp_sz,
		
		input[7:0]							cmd_out,
		input[7:0]							cmd_out_sz,
		input[(CMD_OUT_PARAMS_SZ*8)-1:0]		cmd_out_params,
		input								cmd_out_put_i,
		output								cmd_out_get_i,
		output[(CMD_OUT_RSP_SZ*8)-1:0]		cmd_out_rsp
		);

	reg 									cmd_in_put_i_r;
	reg[(CMD_IN_PARAMS_SZ*8)-1:0]			cmd_in_params_r;
	reg[7:0]								cmd_in_r;
	reg[7:0]								cmd_in_sz_r;
	reg[(CMD_IN_RSP_SZ*8)-1:0]				cmd_in_rsp_r;
	
	reg										cmd_out_get_i_r;

	assign cmd_in = cmd_in_r;
	assign cmd_in_sz = cmd_in_sz_r;
	assign cmd_in_params = cmd_in_params_r;
	assign cmd_in_put_i = cmd_in_put_i_r;

	reg[3:0]		tipo_state;
	reg[7:0]		tipo_rsize;
	reg[7:0]		tipo_id;

	localparam TIPO_COUNT    = 4'b0000;
	localparam TIPO_CMD      = 4'b0010;
	localparam TIPO_ID_REQ   = 4'b0001;
	localparam TIPO_DAT_REQ  = 4'b0011;
	localparam TIPO_EXEC_REQ = 4'b0011;
	localparam TIPO_ID_RSP   = 4'b0001;
	localparam TIPO_DAT_RSP  = 4'b0011;
	localparam TIPO_EXEC_RSP = 4'b0011;
	localparam TIPO_WAIT_RSP_ACK = 4'b0011;
	
	wire tipo_rsp_valid;
	wire tipo_rsp_ready;
	
	reg[7:0] rcount;

	// TIPO State Machine
	// - Receives both cmd-in-req and cmd-out-rsp
	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			tipo_state <= {4{1'b0}};
			cmd_in_sz_r <= {8{1'b0}};
			cmd_in_r <= {8{1'b0}};
			cmd_in_params_r <= {CMD_IN_PARAMS_SZ*8{1'b0}};
			cmd_in_put_i_r <= 1'b0;
			tipo_rsize <= {8{1'b0}};
//			data_v_put_i <= 1'b0;
		end else begin
			case (tipo_state)
				TIPO_COUNT: begin // Count
					if (tipo_valid && tipo_ready) begin
						/*
						count <= tipo_dat;
						rcount <= tipo_dat;
						 */
						tipo_state <= TIPO_CMD;
					end
				end
				TIPO_CMD: begin // Capture command
					if (tipo_valid && tipo_ready) begin
						if (tipo_dat == 8'b0) begin // Response
							tipo_state <= TIPO_ID_RSP;
						end else begin 
							cmd_in_r <= tipo_dat;
							tipo_state <= TIPO_ID_REQ;
						end
						cmd_in_r <= tipo_dat;
						rcount <= rcount - 1'b1;
					end
				end
				TIPO_ID_REQ: begin // Capture id
					if (tipo_valid && tipo_ready) begin
						tipo_id <= tipo_dat;
						rcount <= rcount - 1'b1;
						tipo_state <= TIPO_DAT_REQ;
					end
				end
				TIPO_DAT_REQ: begin : DAT_REQ // Capture remainder of the data
					integer i;
					if (tipo_valid && tipo_ready) begin
						for (i=0; i<(CMD_IN_PARAMS_SZ-1); i=i+1) begin
							cmd_in_params_r[8*i+:8] <= cmd_in_params_r[8*(i+1)+:8];
						end
						if (rcount > 0) begin
							cmd_in_params_r[8*(CMD_IN_PARAMS_SZ-1)+:8] <= tipo_dat;
							rcount <= rcount - 1'b1;
						end
						tipo_state <= TIPO_EXEC_REQ;
						// Signal command is ready
						cmd_in_put_i_r <= ~cmd_in_put_i_r;
						
						if (rcount == 0) begin
							// Process command
						end
					end
				end
				TIPO_EXEC_REQ: begin // Process command
					// Wait for the command to be accepted
					if (cmd_in_put_i_r == cmd_in_get_i) begin
						// Once client aligns the flags again,
						// the command has been accepted and the
						// response is valid
						
						// Let TIPI know we need to send a response
						tipo_state <= TIPO_WAIT_RSP_ACK;
						cmd_in_rsp_r <= cmd_in_rsp;
					end

					/*
					ep_state <= 4'b0000;
					$display("rv-bfm: cmd=%0d", cmd);
					case (cmd[0])
						1'b0: begin // Req
							$display("rv-bfm: Calling _req");
							_req({rdat[0], rdat[1], rdat[2], rdat[3], 
										rdat[4], rdat[5], rdat[6], rdat[7]});
						end
						default:
							ep_state <= 4'b0000;
					endcase
					 */
				end
				
				TIPO_WAIT_RSP_ACK: begin // Wait response from TIPI
					if (tipo_rsp_valid && tipo_rsp_ready) begin
						// Back to the beginning?
					end
				end
				
				TIPO_ID_RSP: begin // Capture id for response
				end
				TIPO_DAT_RSP: begin // Capture remainder of response data
				end
				TIPO_EXEC_RSP: begin // Process response
				end
			endcase
		end
	end
	
	localparam TIPI_IDLE = 4'b0000;
	localparam TIPI_CMD_RSP_1 = 4'b0001;
	localparam TIPI_CMD_RSP_2 = 4'b0001;
	localparam TIPI_CMD_RSP_3 = 4'b0001;
	localparam TIPI_CMD_RSP_4 = 4'b0001;
	
	reg[3:0]				tipi_state;
	reg[7:0]				tipi_dat_o;
	reg[7:0]				tipi_tcount;
	assign tipi_dat = tipi_dat_o;
	
	// TIPI State Machine
	// - Muxes between cmd-rsp and cmd-out-req
	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			cmd_out_get_i_r <= 1'b0;
			tipi_state <= TIPI_IDLE;
			tipi_dat_o <= {8{1'b0}};
			tipi_tcount <= {8{1'b0}};
		end else begin
			case (tipi_state) 
				TIPI_IDLE: begin
					if (cmd_out_get_i_r != cmd_out_put_i) begin
						// outside world requesting
					end else if (tipo_rsp_valid) begin
						// TIPO requesting to send a response
						tipi_dat_o <= {8{1'b0}}; // DST ID 0
						tipi_state <= TIPI_CMD_RSP_1;
					end
				end
				TIPI_CMD_RSP_1: begin 	
					// Wait for DST ack
					if (tipi_valid && tipi_ready) begin
						// Send SZ (data+id+rsp-1)
						tipi_dat_o <= cmd_in_rsp_sz + 8'd1;
						tipi_state <= TIPI_CMD_RSP_2;
						tipi_tcount <= cmd_in_rsp_sz;
					end
				end
				TIPI_CMD_RSP_2: begin
					// Wait for SZ ack
					if (tipi_valid && tipi_ready) begin
						// Send CMD (RSP)
						tipi_dat_o <= {8{1'b0}};
						tipi_state <= TIPI_CMD_RSP_3;
					end
				end
				TIPI_CMD_RSP_3: begin
					// Wait for CMD ack
					if (tipi_valid && tipi_ready) begin
						// Send ID
						tipi_dat_o <= tipo_id;
						tipi_state <= TIPI_CMD_RSP_4;
					end
				end
				TIPI_CMD_RSP_4: begin
					// Wait ACK
					if (tipi_valid && tipi_ready) begin
						if (tipi_tcount == 8'd0) begin
						end else begin
						end
					end
				end
			endcase
		end
	end

endmodule


