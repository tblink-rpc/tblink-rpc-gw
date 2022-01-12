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

class Smoke(object):
    
    async def init(self):
        await tblink_rpc_cocotb.init()
        
        self.fifo_net_o = Fifo()
        
        self.u_net_i : RvInitiatorBfm = tblink_rpc_cocotb.find_ifinst(".*u_net_i")
        self.u_net_o : RvTargetBfm = tblink_rpc_cocotb.find_ifinst(".*u_net_o")
        self.u_net_o.set_req_f(lambda data : self.fifo_net_o.try_put(data))
        
        self.u_tip_o : RvTargetBfm = tblink_rpc_cocotb.find_ifinst(".*u_tip_o")
        self.u_tip_i : RvInitiatorBfm = tblink_rpc_cocotb.find_ifinst(".*u_tip_i")
        
    async def run(self):
        
        t1 = tblink_rpc.start_soon(self.u_tip_i.send([0x02,0x00,0xaa]))
        t2 = tblink_rpc.start_soon(self.u_net_i.send([0x03,0x00,0x55]))
        
        await tblink_rpc.gather(t1, t2)
        
#        tblink_rpc.
        
        await cocotb.triggers.Timer(10, "us")

@cocotb.test()
async def entry(dut):
    t = Smoke()
    await t.init()
    await t.run()

    await cocotb.triggers.Timer(10, "us")
       

       
       
        