/****************************************************************************
 * tblink_rpc_cmdproc_tb.sv
 ****************************************************************************/
`ifdef NEED_TIMESCALE
`timescale 1ns/1ns
`endif
`include "rv_macros.svh"
  
/**
 * Module: tblink_rpc_cmdproc_tb
 * 
 * TODO: Add module documentation
 */
module tblink_rpc_cmdproc_tb(input clock);
	
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
	
	wire uclock /* verilator public */;
	assign uclock = clock;
	reg cclock = 0;
	
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
	
	always @(posedge clock) begin
		cclock <= ~cclock;
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
	
	`RV_WIRES(tipo2proc_, 8);
	`RV_WIRES(proc2tipi_, 8);
	
	wire hreq_i, hreq_o;
	assign hreq_i = 0;

	tblink_rpc_ep #(
		.ADDR        (1       )
		) u_ep (
		.uclock      (uclock     ), 
		.reset       (reset      ), 
		.hreq_i      (hreq_i     ), 
		.hreq_o      (hreq_o     ), 
		`RV_CONNECT(neti_, bfm2neti_),
		`RV_CONNECT(neto_, neto2bfm_),
		`RV_CONNECT(tipo_, tipo2proc_),
		`RV_CONNECT(tipi_, proc2tipi_)
		);
	
	localparam CMD_IN_PARAMS_SZ = 4;
	localparam CMD_IN_RSP_SZ = 1;
	localparam CMD_OUT_PARAMS_SZ = 4;
	localparam CMD_OUT_RSP_SZ = 1;

	wire[7:0]							cmd_in;
	wire[7:0]							cmd_in_sz;
	wire[(CMD_IN_PARAMS_SZ*8)-1:0]		cmd_in_params;
	wire								cmd_in_get_i;
	wire								cmd_in_put_i;
	wire[(CMD_IN_RSP_SZ*8)-1:0]			cmd_in_rsp;
	wire[7:0]							cmd_in_rsp_sz;
	
	tblink_rpc_cmdproc #(
		.CMD_IN_PARAMS_SZ  (CMD_IN_PARAMS_SZ ), 
		.CMD_IN_RSP_SZ     (CMD_IN_RSP_SZ    ), 
		.CMD_OUT_PARAMS_SZ (CMD_OUT_PARAMS_SZ), 
		.CMD_OUT_RSP_SZ    (CMD_OUT_RSP_SZ   )
		) u_dut (
		.uclock            (uclock           ), 
		.reset             (reset            ), 
		`RV_CONNECT(tipo_, tipo2proc_),
		`RV_CONNECT(tipi_, proc2tipi_),
		.cmd_in            (cmd_in           ), 
		.cmd_in_sz         (cmd_in_sz        ), 
		.cmd_in_params     (cmd_in_params    ), 
		.cmd_in_put_i      (cmd_in_put_i     ), 
		.cmd_in_get_i      (cmd_in_get_i     ), 
		.cmd_in_rsp        (cmd_in_rsp       ), 
		.cmd_in_rsp_sz     (cmd_in_rsp_sz    ) 
		/*
		.cmd_out           (cmd_out          ), 
		.cmd_out_sz        (cmd_out_sz       ), 
		.cmd_out_params    (cmd_out_params   ), 
		.cmd_out_put_i     (cmd_out_put_i    ), 
		.cmd_out_get_i     (cmd_out_get_i    ), 
		.cmd_out_rsp       (cmd_out_rsp      )
		 */
		);
	
	wire cmd_in_valid = (cmd_in_put_i != cmd_in_get_i);
	
	cmdproc_bfm #(
		.CMD_IN_PARAMS_SZ  (CMD_IN_PARAMS_SZ ), 
		.CMD_IN_RSP_SZ     (CMD_IN_RSP_SZ    ), 
		.CMD_OUT_PARAMS_SZ (CMD_OUT_PARAMS_SZ), 
		.CMD_OUT_RSP_SZ    (CMD_OUT_RSP_SZ   )
		) u_cmdproc_bfm (
			.cclock			(cclock			),
			.reset			(reset			),
			.cmd_in			(cmd_in			),
			.cmd_in_sz		(cmd_in_sz		),
			.cmd_in_params	(cmd_in_params	),
			.cmd_in_put_i	(cmd_in_put_i	),
			.cmd_in_get_i	(cmd_in_get_i	),
			.cmd_in_rsp		(cmd_in_rsp		),
			.cmd_in_rsp_sz	(cmd_in_rsp_sz	)
		);
	
endmodule


