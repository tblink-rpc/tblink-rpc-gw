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
	
	reg				cclock_timer_load_r;
	reg				cclock_timer_load_a;
	reg[31:0]		cclock_timer_cnt;
	reg[31:0]		cclock_timer;
	reg				cclock_timer_trig_r;
	reg				cclock_timer_trig_a;
	
	assign cclock_en = (cclock_en_r & (cclock_div == cclock_div_cnt));

	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			cclock_r <= 0;
			cclock_div_cnt <= {32{1'b0}};
			cclock_count <= {64{1'b0}};
			cclock_timer <= {32{1'b0}};
			cclock_timer_load_a <= 1'b0;
			cclock_timer_trig_r <= 1'b0;
		end else begin
			if (cclock_timer_load_r != cclock_timer_load_a) begin
				cclock_timer <= cclock_timer_cnt;
				cclock_timer_load_a <= ~cclock_timer_load_a;
			end
			
			if (cclock_en) begin
				if (!cclock_r) begin
					// Count rising clock edges
					cclock_count <= cclock_count + 1'b1;
					
					if (cclock_timer != 0) begin
						if (cclock_timer == 32'd1) begin
							cclock_timer_trig_r <= ~cclock_timer_trig_r;
						end
						cclock_timer <= cclock_timer - 1;
					end
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
	
	reg cmd_out_state;
	
	always @(posedge uclock or posedge reset) begin
		if (reset) begin
			cclock_div <= {32{1'b0}};
			cclock_en_r <= 1'b0;
			cmd_in_get_i <= 1'b0;
			cmd_in_rsp <= {CMD_IN_RSP_SZ*8{1'b0}};
			cmd_in_rsp_sz <= {8{1'b0}};
			cmd_out <= {8{1'b0}};
			cmd_out_sz <= {8{1'b0}};
			cmd_out_params <= {8*CMD_OUT_PARAMS_SZ{1'b0}};
			cmd_out_put_i <= 1'b0;
			cclock_timer_cnt <= {32{1'b0}};
			cclock_timer_load_r <= 1'b0;
			cclock_timer_trig_a <= 1'b0;
			cmd_out_state <= 1'b0;
		end else begin
			if (cmd_in_put_i != cmd_in_get_i) begin
				case (cmd_in)
					8'd1: begin // GetTime
						cmd_in_rsp_sz <= 8'd8;
						cmd_in_rsp[63:0] <= cclock_count;
					end
					
					8'd2: begin // SetTimer
						// TODO:
						cclock_timer_cnt <= cmd_in_params[31:0];
						cclock_timer_load_r <= ~cclock_timer_load_r;
						cmd_in_rsp_sz <= 8'd0;
					end
					
					8'd3: begin // Release
						// Re-enable clock
						cclock_en_r <= 1'b1;
						
						cmd_in_rsp_sz <= 8'd0;
					end
					
					8'd4: begin // SetDivisor
						cclock_div <= cmd_in_params[31:0];
						cmd_in_rsp_sz <= 8'd0;
					end
					
					default: begin
						// TODO?
						cmd_in_rsp_sz <= 8'd0;
					end
						
				endcase
				cmd_in_get_i <= ~cmd_in_get_i;
			end
			
			case (cmd_out_state) 
				1'b0: begin
					if (cclock_timer_trig_a != cclock_timer_trig_r) begin
						cmd_out_put_i <= ~cmd_out_put_i;
						cclock_timer_trig_a <= ~cclock_timer_trig_a;
						cmd_out <= 8'b1;

						cmd_out_state <= 1'b1;

						// Halt clock
						cclock_en_r <= 1'b0;
					end else begin
						// TODO:
					end
				end
				
				1'b1: begin
					if (cmd_out_put_i == cmd_out_get_i) begin
						cmd_out_state <= 1'b0;
					end
				end
			endcase
			
		end
	end
	
endmodule


