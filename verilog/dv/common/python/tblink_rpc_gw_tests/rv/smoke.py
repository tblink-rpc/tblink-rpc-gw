'''
Created on Nov 2, 2021

@author: mballance
'''

import tblink_rpc_cocotb
from rv_bfms.rv_initiator_bfm import RvInitiatorBfm
from rv_bfms.rv_target_bfm import RvTargetBfm
import cocotb
from tblink_rpc.lib.fifo import Fifo
import tblink_rpc
from tblink_rpc_gw.transport.msg_ctrl_factory import MsgCtrlFactory
from tblink_rpc_gw.transport.msg_bfm_cmd import MsgBfmCmd

class SetDivisor(object):
    
    async def init(self):
        await tblink_rpc_cocotb.init()
        
        self.fifo_net_o = Fifo()
        
        self.u_ctrl_i : RvInitiatorBfm = tblink_rpc_cocotb.find_ifinst(".*u_ctrl_i")
        self.u_ctrl_t : RvTargetBfm = tblink_rpc_cocotb.find_ifinst(".*u_ctrl_t")
        
#        self.u_net_o.set_req_f(lambda data : self.fifo_net_o.try_put(data))
        
#        self.u_tip_o : RvTargetBfm = tblink_rpc_cocotb.find_ifinst(".*u_tip_o")
#        self.u_tip_i : RvInitiatorBfm = tblink_rpc_cocotb.find_ifinst(".*u_tip_i")
        
    async def run(self):

        # Set the clock divisor        
        msg = MsgCtrlFactory.mkSetDivisor(1, 4)

        print("--> u_ctrl_i.send", flush=True)
        await self.u_ctrl_i.send(msg.pack())
        print("<-- u_ctrl_i.send", flush=True)
        
        # Queue an access request 
        msg = MsgBfmCmd(1, 0, 1)
        msg.payload.extend([1, 2, 3, 4, 5, 6, 7, 8])
        await self.u_ctrl_i.send(msg.pack())
        
        msg = MsgCtrlFactory.mkRelease(2)
        await self.u_ctrl_i.send(msg.pack())
        
        await cocotb.triggers.Timer(10, "us")

@cocotb.test()
async def entry(dut):
    t = SetDivisor()
    await t.init()
    await t.run()

    await cocotb.triggers.Timer(10, "us")
