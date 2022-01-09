/****************************************************************************
 * tblink_rpc_ep_tb.sv
 ****************************************************************************/
`ifdef NEED_TIMESCALE
`timescale 1ns/1ns
`endif
`include "rv_macros.svh"
  
/**
 * Module: tblink_rpc_ep_tb
 * 
 * TODO: Add module documentation
 */
module tblink_rpc_ep_tb(input clock);
	
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
	
	wire uclock;
	assign uclock = clock;
	
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
	
	`RV_WIRES(bfm2neti_, 8);
	
	rv_initiator_bfm #(
		.WIDTH    (8   )
		) u_net_i (
		.clock    (clock   ), 
		.reset    (reset   ), 
		`RV_CONNECT(i_, bfm2neti_)
		);

	`RV_WIRES(neto2bfm_, 8);
	rv_target_bfm #(
		.WIDTH    (8   )
		) u_net_o (
		.clock    (clock   ), 
		.reset    (reset   ), 
		`RV_CONNECT(t_, neto2bfm_)
		);
	
	`RV_WIRES(tipo2bfm_, 8);
	rv_target_bfm #(
		.WIDTH    (8   )
		) u_tip_o (
		.clock    (clock   ), 
		.reset    (reset   ), 
		`RV_CONNECT(t_, tipo2bfm_)
		);
	
	`RV_WIRES(bfm2tipi_, 8);
	rv_initiator_bfm #(
		.WIDTH    (8   )
		) u_tip_i (
		.clock    (clock   ), 
		.reset    (reset   ), 
		`RV_CONNECT(i_, bfm2tipi_)
		);
	
	tblink_rpc_ep #(
		.ADDR        (1       )
		) u_dut (
		.uclock      (uclock     ), 
		.reset       (reset      ), 
		.hreq_i      (hreq_i     ), 
		.hreq_o      (hreq_o     ), 
		`RV_CONNECT(neti_, bfm2neti_),
		`RV_CONNECT(neto_, neto2bfm_),
		`RV_CONNECT(tipo_, tipo2bfm_),
		`RV_CONNECT(tipi_, bfm2tipi_)
		);

endmodule


