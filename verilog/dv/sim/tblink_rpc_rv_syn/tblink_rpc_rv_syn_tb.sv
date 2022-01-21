/****************************************************************************
 * tblink_rpc_rv_syn_tb.sv
 ****************************************************************************/
`include "rv_macros.svh"
`ifdef NEED_TIMESCALE
`timescale 1ns/1ns
`endif
  
/**
 * Module: tblink_rpc_rv_syn_tb
 * 
 * TODO: Add module documentation
 */
module tblink_rpc_rv_syn_tb(input clock);
	
`ifdef IVERILOG
`include "iverilog_control.svh"
`endif
	
`ifdef HAVE_HDL_CLOCKGEN
	reg clock_r = 0;
	initial begin
		forever begin
`ifdef NEED_TIMESCALE
			#10;
`else
			#10ns;
`endif
			clock_r <= ~clock_r;
		end
	end
	assign clock = clock_r;
`endif
	
	reg      reset = 0;
	reg[5:0] reset_cnt = 0;
	
	always @(posedge clock) begin
		if (reset_cnt == 20) begin
			reset <= 0;
		end else begin
			if (reset_cnt == 1) begin
				reset <= 1;
			end
			reset_cnt <= reset_cnt + 1;
		end
	end	
	
	wire cclock;
	wire uclock;
	assign uclock = clock;
	
	`RV_WIRES(bfm2ctrl_t_, 8);
	`RV_WIRES(ctrl_i_2bfm_, 8);
	`RV_WIRES(ctrl_neto_, 8);
	`RV_WIRES(ctrl_neti_, 8);
	
	rv_initiator_bfm #(
		.WIDTH    (8   )
		) u_ctrl_i (
		.clock    (uclock   ), 
		.reset    (reset   ), 
		`RV_CONNECT(i_, bfm2ctrl_t_)
		);
	rv_target_bfm #(
		.WIDTH    (8   )
		) u_ctrl_t (
		.clock    (uclock   ), 
		.reset    (reset   ), 
		`RV_CONNECT(t_, ctrl_i_2bfm_)
		);
	
	wire ctrl_hreq_i;
	
	tblink_rpc_ctrl u_ctrl(
		.uclock             (uclock            ),
		.reset              (reset             ),
		.cclock             (cclock            ),
		.hreq_i             (ctrl_hreq_i       ),
		`RV_CONNECT(t_, bfm2ctrl_t_),
		`RV_CONNECT(i_, ctrl_i_2bfm_),
		`RV_CONNECT(neti_, ctrl_neti_),
		`RV_CONNECT(neto_, ctrl_neto_)
		);

	`RV_WIRES(sbfm2bfm_, 8);
	
	wire bfm_hreq_i;
	assign bfm_hreq_i = 0;
	wire bfm_hreq_o;
	
	rv_initiator_bfm_syn #(
		.ADDR        (1       ), 
		.WIDTH       (8      )
		) u_bfm (
		.cclock      (cclock     ), 
		.uclock      (uclock     ), 
		.reset       (reset      ), 
		.hreq_i      (bfm_hreq_i ),
		.hreq_o      (bfm_hreq_o ),
		`RV_CONNECT(neti_, ctrl_neto_),
		`RV_CONNECT(neto_, ctrl_neti_),
		`RV_CONNECT(i_, sbfm2bfm_)
		);
	
	rv_target_bfm #(
		.WIDTH    (8   )
		) u_t_bfm (
		.clock    (clock   ), 
		.reset    (reset   ), 
		`RV_CONNECT(t_, sbfm2bfm_)
		);
	
	assign ctrl_hreq_i = bfm_hreq_o;

endmodule


