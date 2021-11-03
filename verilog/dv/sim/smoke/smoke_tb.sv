/****************************************************************************
 * smoke_tb.sv
 ****************************************************************************/
`include "rv_macros.svh"

`ifdef NEED_TIMESCALE
	`timescale 1ns/1ns
`endif

/**
 * Module: smoke_tb
 * 
 * TODO: Add module documentation
 */
module smoke_tb(input clock);
	
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
	
`ifdef IVERILOG
	`include "iverilog_control.svh"
`endif
	
	reg reset = 0;
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
	
	`RV_WIRES(bfm2dut_, 8);
	`RV_WIRES(dut2bfm_, 8);
	
	reg[7:0]			count;
	
	always @(posedge cclock or posedge reset) begin
		if (reset) begin
			count <= {8{1'b0}};
		end else begin
			count <= count + 1;
		end
	end
	
	rv_data_out_bfm #(
		.DATA_WIDTH  (8 )
		) u_tx_bfm (
		.clock       (clock      ), 
		.reset       (reset      ), 
		`RV_CONNECT( , bfm2dut_));
	
	rv_data_in_bfm #(
		.DATA_WIDTH  (8 )
		) u_rx_bfm (
		.clock       (clock      ), 
		.reset       (reset      ), 
		`RV_CONNECT( , dut2bfm_));

	tblink_rpc_ep #(
		.N_INTERFACE_INSTS  (1 )
		) u_dut (
		.clock              (clock             ), 
		.reset              (reset             ), 
		.cclock             (cclock            ), 
		`RV_CONNECT(t_, bfm2dut_),
		`RV_CONNECT(i_, dut2bfm_),
		.dat_i				(count             )
		);

endmodule


