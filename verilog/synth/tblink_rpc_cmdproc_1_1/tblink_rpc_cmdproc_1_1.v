
`include "rv_macros.svh"

module tblink_rpc_cmdproc_1_1 #(
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
		output[(CMD_OUT_RSP_SZ*8)-1:0]		cmd_out_rsp);
	
	tblink_rpc_cmdproc #(
		.CMD_IN_PARAMS_SZ   (CMD_IN_PARAMS_SZ  ), 
		.CMD_IN_RSP_SZ      (CMD_IN_RSP_SZ     ), 
		.CMD_OUT_PARAMS_SZ  (CMD_OUT_PARAMS_SZ ), 
		.CMD_OUT_RSP_SZ     (CMD_OUT_RSP_SZ    )
		) u_core (
		.uclock             (uclock            ), 
		.reset              (reset             ), 
		`RV_CONNECT(tipo_, tipo_),
		`RV_CONNECT(tipi_, tipi_),
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
		.cmd_out_rsp        (cmd_out_rsp       ));
	
endmodule

