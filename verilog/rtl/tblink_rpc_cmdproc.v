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
		parameter ADDR = 0,
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
		input[(CMD_OUT_PARAMS_SZ*8)-1:0]	cmd_out_params,
		input								cmd_out_put_i,
		output								cmd_out_get_i,
		output[(CMD_OUT_RSP_SZ*8)-1:0]		cmd_out_rsp,
		output[7:0]							cmd_out_rsp_sz
		);

	reg 									cmd_in_put_i_r;
	reg[(CMD_IN_PARAMS_SZ*8)-1:0]			cmd_in_params_r;
	reg[7:0]								cmd_in_r;
	reg[7:0]								cmd_in_sz_r;
	reg[(CMD_IN_RSP_SZ*8)-1:0]				cmd_in_rsp_r;
	
	reg[(CMD_OUT_RSP_SZ*8)-1:0]				cmd_out_rsp_r;
	reg[7:0]								cmd_out_rsp_sz_r;
	

	assign cmd_in = cmd_in_r;
	assign cmd_in_sz = cmd_in_sz_r;
	assign cmd_in_params = cmd_in_params_r;
	assign cmd_in_put_i = cmd_in_put_i_r;
	assign cmd_out_rsp = cmd_out_rsp_r;
	assign cmd_out_rsp_sz = cmd_out_rsp_sz_r;
	
	reg[3:0]		tipo_state;
	reg[7:0]		tipo_rsize;
	reg[7:0]		tipo_id;

	localparam TIPO_COUNT    		= 4'b0000;
	localparam TIPO_CMD      		= (TIPO_COUNT+1'b1);
	localparam TIPO_ID_REQ   		= (TIPO_CMD+1'b1);
	localparam TIPO_DAT_REQ  		= (TIPO_ID_REQ+1'b1);
	localparam TIPO_EXEC_REQ 		= (TIPO_DAT_REQ+1'b1);
	localparam TIPO_ID_RSP   		= (TIPO_EXEC_REQ+1'b1);
	localparam TIPO_DAT_RSP  		= (TIPO_ID_RSP+1'b1);
	localparam TIPO_EXEC_RSP 		= (TIPO_DAT_RSP+1'b1);		// 8
	localparam TIPO_WAIT_RSP_ACK 	= (TIPO_EXEC_RSP+1'b1);
	
	wire tipo_rsp_valid;
	wire tipo_rsp_ready;

	reg[7:0] tipo_count;
	
	assign tipo_ready = (
			tipo_state == TIPO_COUNT ||
			tipo_state == TIPO_CMD ||
			tipo_state == TIPO_ID_REQ ||
			tipo_state == TIPO_DAT_REQ ||
			tipo_state == TIPO_ID_RSP ||
			tipo_state == TIPO_DAT_RSP
		);
	assign tipo_rsp_valid = (
			tipo_state == TIPO_WAIT_RSP_ACK
		);
	// True for one cycle when a cmd-in response
	// is complete
	wire cmd_in_rsp_done;

	// TIPO State Machine
	// - Receives both cmd-in-req and cmd-out-rsp
	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			tipo_state <= {4{1'b0}};
			cmd_in_sz_r <= {8{1'b0}};
			cmd_in_r <= {8{1'b0}};
			cmd_in_params_r <= {CMD_IN_PARAMS_SZ*8{1'b0}};
			cmd_in_put_i_r <= 1'b0;
			cmd_out_rsp_r <= {CMD_OUT_RSP_SZ*8{1'b0}};
			tipo_rsize <= {8{1'b0}};
			tipo_id <= {8{1'b0}};
			tipo_count <= {8{1'b0}};
			cmd_in_rsp_r <= {CMD_IN_RSP_SZ*8{1'b0}};
			cmd_out_rsp_sz_r <= {8{1'b0}};
//			data_v_put_i <= 1'b0;
		end else begin
			case (tipo_state)
				TIPO_COUNT: begin // Count
					if (tipo_valid && tipo_ready) begin
						// tipo_count is the number of payload-parameter
						// bytes we need to read.
						// (sz+1) - total 
						// -1     - cmd
						// -1     - id
						//        - parameters payload
						tipo_count <= tipo_dat - 1; // size + 1 - 2
						
						// cmd_in_sz_r publishes the number of parameter
						// bytes to the cmdproc client.
						// 
						cmd_in_sz_r <= tipo_dat - 1; // size + 1 - 2
						cmd_in_params_r <= {CMD_IN_PARAMS_SZ*8{1'b0}};
						cmd_out_rsp_r <= {CMD_OUT_RSP_SZ*8{1'b0}};
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
					end
				end
				TIPO_ID_REQ: begin // Capture id
					if (tipo_valid && tipo_ready) begin
						tipo_id <= tipo_dat;
						if (tipo_count > 0) begin
							tipo_state <= TIPO_DAT_REQ;
							tipo_count <= tipo_count - 1;
						end else begin
							// Signal command is ready
							cmd_in_put_i_r <= ~cmd_in_put_i_r;
							tipo_state <= TIPO_EXEC_REQ;
						end
					end
				end
				TIPO_DAT_REQ: begin : DAT_REQ // Capture remainder of the data
					integer i;
					if (tipo_valid && tipo_ready) begin
						for (i=CMD_IN_PARAMS_SZ-1; i>0; i=i-1) begin
							cmd_in_params_r[8*i+:8] <= cmd_in_params_r[8*(i-1)+:8];
						end
						cmd_in_params_r[7:0] <= tipo_dat;
						if (tipo_count > 0) begin
							tipo_count <= tipo_count - 1'b1;
						end else begin
							cmd_in_put_i_r <= ~cmd_in_put_i_r;
							tipo_state <= TIPO_EXEC_REQ;
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
				end
				TIPO_WAIT_RSP_ACK: begin // Wait response from TIPI
					// Back to the beginning?
					if (cmd_in_rsp_done) begin
						tipo_state <= TIPO_COUNT;
					end
				end
				TIPO_ID_RSP: begin // Capture id for response
					if (tipo_valid && tipo_ready) begin
						cmd_out_rsp_sz_r <= tipo_count;
						if (tipo_count == 0) begin
							tipo_state <= TIPO_EXEC_RSP;
						end else begin
							tipo_state <= TIPO_DAT_RSP;
							tipo_count <= tipo_count - 1'b1;
						end
					end
				end
				TIPO_DAT_RSP: begin : _DAT_RSP // Capture remainder of response data
					integer i;
					if (tipo_valid && tipo_ready) begin
						for (i=CMD_OUT_RSP_SZ-1; i>0; i=i-1) begin
							cmd_out_rsp_r[8*i+:8] <= cmd_out_rsp_r[8*(i-1)+:8];
						end
						cmd_out_rsp_r[7:0] <= tipo_dat;
						
						if (tipo_count == 0) begin
							tipo_state <= TIPO_EXEC_RSP;
						end
						tipo_count <= tipo_count - 1'b1;
					end
				end
				TIPO_EXEC_RSP: begin // Process response
					tipo_state <= TIPO_COUNT;
				end
			endcase
		end
	end
	
	localparam TIPI_IDLE 		= 4'b0000;
	localparam TIPI_CMD_RSP_1 	= (TIPI_IDLE+1'b1);
	localparam TIPI_CMD_RSP_2 	= (TIPI_CMD_RSP_1+1'b1);
	localparam TIPI_CMD_RSP_3 	= (TIPI_CMD_RSP_2+1'b1);
	localparam TIPI_CMD_RSP_4	= (TIPI_CMD_RSP_3+1'b1); // 4
	localparam TIPI_CMD_RSP_5	= (TIPI_CMD_RSP_4+1'b1);
	localparam TIPI_OUT_REQ_1	= (TIPI_CMD_RSP_5+1'b1);
	localparam TIPI_OUT_REQ_2	= (TIPI_OUT_REQ_1+1'b1);
	localparam TIPI_OUT_REQ_3	= (TIPI_OUT_REQ_2+1'b1); // 8
	localparam TIPI_OUT_REQ_4	= (TIPI_OUT_REQ_3+1'b1);
	localparam TIPI_OUT_REQ_5	= (TIPI_OUT_REQ_4+1'b1);
	localparam TIPI_OUT_WAIT_RSP	= (TIPI_OUT_REQ_5+1'b1);
//	localparam TIPI_
	
	reg[3:0]							tipi_state;
	reg[7:0]							tipi_dat_o;
	reg[7:0]							tipi_tcount;
	reg[7:0]							tipi_id;
	reg[(8*CMD_OUT_PARAMS_SZ)-1:0]		cmd_out_params_r;
	reg									cmd_out_get_i_r;
	assign tipi_dat = tipi_dat_o;
	
	assign tipi_valid = (
			(tipi_state != TIPI_IDLE) &&
			(tipi_state != TIPI_CMD_RSP_5) &&
			(tipi_state != TIPI_OUT_WAIT_RSP));
	assign tipo_rsp_ready = (tipi_state == TIPI_CMD_RSP_5);
	
	assign cmd_out_get_i = cmd_out_get_i_r;
	
	assign cmd_in_rsp_done  = (tipi_state == TIPI_CMD_RSP_5);
	
	// TIPI State Machine
	// - Muxes between cmd-rsp and cmd-out-req
	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			cmd_out_get_i_r <= 1'b0;
			tipi_state <= TIPI_IDLE;
			tipi_dat_o <= {8{1'b0}};
			tipi_tcount <= {8{1'b0}};
			tipi_id <= {8{1'b0}};
			cmd_out_params_r <= {8*CMD_OUT_PARAMS_SZ{1'b0}};
		end else begin
			case (tipi_state) 
				TIPI_IDLE: begin
					if (cmd_out_get_i_r != cmd_out_put_i) begin
						// outside world requesting
						tipi_dat_o <= {8{1'b0}}; // DST ID 0
						tipi_state <= TIPI_OUT_REQ_1;
						cmd_out_params_r <= cmd_out_params;
					end else if (tipo_rsp_valid) begin
						// TIPO requesting to send a response
						if (ADDR != 0) begin
							tipi_dat_o <= {8{1'b0}}; // DST ID 0
							tipi_state <= TIPI_CMD_RSP_1;
						end else begin
							// If we implement the controller, then do not
							// send a destination address
							tipi_dat_o <= cmd_in_rsp_sz + 8'd1;
							tipi_state <= TIPI_CMD_RSP_2;
						end
					end
				end
				TIPI_CMD_RSP_1: begin
					// Wait for DST ack
					if (tipi_valid && tipi_ready) begin
						// Send SZ (data+2-1)
						tipi_dat_o <= cmd_in_rsp_sz + 8'd1;
						tipi_state <= TIPI_CMD_RSP_2;
						tipi_tcount <= cmd_in_rsp_sz;
					end
				end
				TIPI_CMD_RSP_2: begin
					// Wait for SZ ack
					if (tipi_valid && tipi_ready) begin
						// Send CMD (RSP)
						tipi_dat_o <= {8{1'b0}}; // Response
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
				TIPI_CMD_RSP_4: begin : RSP_DAT
					integer i;
					// Wait ID ACK
					if (tipi_valid && tipi_ready) begin
						if (tipi_tcount == 8'd0) begin
							tipi_state <= TIPI_CMD_RSP_5;
						end else begin
							for (i=0; i<CMD_IN_RSP_SZ-1; i=i+1) begin
								cmd_in_rsp_r[8*i+:8] <= cmd_in_rsp_r[8*(i+1)+:8];
							end
						
							tipi_dat_o <= cmd_in_rsp_r[7:0];
							tipi_tcount <= tipi_tcount - 1'b1;
							// TODO: handle data response
						end
					end
				end
				TIPI_CMD_RSP_5: begin
					tipi_state <= TIPI_IDLE;
				end
				TIPI_OUT_REQ_1: begin
					// Wait DST ACK ; 
					if (tipi_valid && tipi_ready) begin
						tipi_state <= TIPI_OUT_REQ_2;
						// Total payload size
						// cmd_out_sz
						// +1 - cmd
						// +1 - id
						// -1
						tipi_dat_o <= cmd_out_sz + 8'd1;
						tipi_tcount <= cmd_out_sz;
					end
				end
				TIPI_OUT_REQ_2: begin
					// Wait SZ Ack
					if (tipi_valid && tipi_ready) begin
						tipi_state <= TIPI_OUT_REQ_3;
						tipi_dat_o <= cmd_out;
					end
				end
				TIPI_OUT_REQ_3: begin
					// Wait CMD Ack
					if (tipi_valid && tipi_ready) begin
						tipi_state <= TIPI_OUT_REQ_4;
						tipi_dat_o <= ADDR;
						tipi_id <= tipi_id + 1'b1;
					end
				end
				TIPI_OUT_REQ_4: begin
					// Wait ID Ack
					if (tipi_valid && tipi_ready) begin
						tipi_state <= TIPI_OUT_REQ_5;
						tipi_dat_o <= tipi_id;
						
						if (tipi_tcount > 0) begin
							// Move on to send data
							tipi_state <= TIPI_OUT_REQ_5;
							tipi_dat_o <= cmd_out_params_r[7:0];
							tipi_tcount <= tipi_tcount - 1'b1;
						end else begin
							// Done sending request message
							// Wait for an ack
							tipi_state <= TIPI_OUT_WAIT_RSP;
						end
					end
				end
				TIPI_OUT_REQ_5: begin : OUT_REQ_5
					integer i;
					
					// Send data
					if (tipi_valid && tipi_ready) begin
						tipi_dat_o <= cmd_out_params_r[15:8];
						for (i=1; i<CMD_OUT_PARAMS_SZ; i=i+1) begin
							cmd_out_params_r[8*(i-1)+:8] <= cmd_out_params_r[8*i+:8];
						end
						
						if (tipi_tcount == 0) begin
							tipi_state <= TIPI_OUT_WAIT_RSP;
						end
						
						tipi_tcount <= tipi_tcount - 1'b1;
					end
				end
				TIPI_OUT_WAIT_RSP: begin
					// Wait for the other side to respond with 
					// out-cmd acknowledge

					if (tipo_rsp_valid) begin
						// Acknowledge that we received the request
						cmd_out_get_i_r <= ~cmd_out_get_i_r;
						
						tipi_state <= TIPI_IDLE;
					end
				end
			endcase
		end
	end

endmodule


