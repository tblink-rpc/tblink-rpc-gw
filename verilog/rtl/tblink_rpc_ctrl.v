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
				if (cclock_en_r) begin
					cclock_div_cnt <= cclock_div_cnt + 1'b1;
				end else begin
					cclock_div_cnt <= {32{1'b0}};
				end
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
//	assign demux2local_ready = (~local_state[3]);
	assign req_buf_en = (
			(!local_state[3] & demux2local_ready & demux2local_valid) ||
			(local_state == 4'b0011));
	assign local2mux_valid = (local_state == 4'b1000);
	assign local2mux_dat = rsp_buf[0];
	
	integer req_buf_i, rsp_buf_i;
	
	localparam CMD_IN_PARAMS_SZ   = 8;
	localparam CMD_IN_RSP_SZ      = 8;
	localparam CMD_OUT_PARAMS_SZ  = 1;
	localparam CMD_OUT_RSP_SZ     = 1;

	wire[7:0]							cmd_in;
	wire[7:0]							cmd_in_sz;
	wire[(8*CMD_IN_PARAMS_SZ)-1:0]		cmd_in_params;
	wire								cmd_in_put_i;
	reg									cmd_in_get_i;
	reg[(8*CMD_IN_RSP_SZ)-1:0]			cmd_in_rsp;
	reg[7:0]							cmd_in_rsp_sz;
	reg[7:0]							cmd_out;
	reg[7:0]							cmd_out_sz;
	reg[(8*CMD_OUT_PARAMS_SZ)-1:0]		cmd_out_params;
	reg									cmd_out_put_i;
	wire								cmd_out_get_i;
	wire[(8*CMD_OUT_RSP_SZ)-1:0]		cmd_out_rsp;
	wire[7:0]							cmd_out_rsp_sz;


	tblink_rpc_cmdproc #(
		.CMD_IN_PARAMS_SZ   (CMD_IN_PARAMS_SZ   ), 
		.CMD_IN_RSP_SZ      (CMD_IN_RSP_SZ      ), 
		.CMD_OUT_PARAMS_SZ  (CMD_OUT_PARAMS_SZ  ), 
		.CMD_OUT_RSP_SZ     (CMD_OUT_RSP_SZ     )
		) u_cmdproc (
		.uclock             (uclock            ), 
		.reset              (reset             ), 
		`RV_CONNECT(tipo_, demux2local_),
		`RV_CONNECT(tipi_, local2mux_),
		.cmd_in             (cmd_in            ), 
		.cmd_in_sz          (cmd_in_sz         ), 
		.cmd_in_params      (cmd_in_params     ), 
		.cmd_in_put_i       (cmd_in_put_i      ), 
		.cmd_in_get_i       (cmd_in_get_i      ), 
		.cmd_in_rsp         (cmd_in_rsp        ), 
		.cmd_in_rsp_sz      (cmd_in_rsp_sz     ), 
		.cmd_out            (cmd_out           ), 
		.cmd_out_sz         (cmd_out_sz        ), 
		.cmd_out_params     (cmd_out_params    ), 
		.cmd_out_put_i      (cmd_out_put_i     ), 
		.cmd_out_get_i      (cmd_out_get_i     ), 
		.cmd_out_rsp        (cmd_out_rsp       ), 
		.cmd_out_rsp_sz     (cmd_out_rsp_sz    ));
	
	assign demux2local_ready = (local_state != 4'b1000);
	
	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			req_buf_cnt <= 4'b0000;
			local_state <= 4'b0000;
			req_msg_size <= 3'b000;
			cclock_div <= {32{1'b0}};
			cclock_en_r <= 1'b0;
			rsp_buf_cnt <= 4'b0000;
			cmd_in_get_i <= 1'b0;
			cmd_in_rsp <= {CMD_IN_RSP_SZ*8{1'b0}};
			cmd_in_rsp_sz <= {8{1'b0}};
		end else begin
			if (cmd_in_put_i != cmd_in_get_i) begin
				case (cmd_in)
					8'd1: begin // GetTime
						cmd_in_rsp_sz <= 8'd8;
						cmd_in_rsp[63:0] <= cclock_count;
					end
					
					8'd2: begin // SetTimer
						// TODO:
						cmd_in_rsp_sz <= 8'd0;
					end
					
					8'd3: begin // Release
						// Re-enable clock
						cclock_en_r <= 1'b1;
						
						cmd_in_rsp_sz <= 8'd0;
					end
					
					8'd4: begin // SetDivisor
						cclock_div <= cmd_in[31:0];
						cmd_in_rsp_sz <= 8'd0;
					end
					
					default: begin
						// TODO?
						cmd_in_rsp_sz <= 8'd0;
					end
						
				endcase
				cmd_in_get_i <= ~cmd_in_get_i;
			end
		end
	end
	
endmodule


