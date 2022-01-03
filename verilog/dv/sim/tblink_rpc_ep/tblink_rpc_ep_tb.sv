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
	
	tblink_rpc_ep #(
		.ADDR        (1       )
		) u_dut (
		.uclock      (uclock     ), 
		.reset       (reset      ), 
		.hreq_i      (hreq_i     ), 
		.hreq_o      (hreq_o     ), 
		.neti_dat    (neti_dat   ), 
		.neti_valid  (neti_valid ), 
		.neti_ready  (neti_ready ), 
		.neto_dat    (neto_dat   ), 
		.neto_valid  (neto_valid ), 
		.neto_ready  (neto_ready ), 
		.tipo_dat    (tipo_dat   ), 
		.tipo_valid  (tipo_valid ), 
		.tipo_ready  (tipo_ready ), 
		.tipi_dat    (tipi_dat   ), 
		.tipi_valid  (tipi_valid ), 
		.tipi_ready  (tipi_ready ));
	


endmodule


