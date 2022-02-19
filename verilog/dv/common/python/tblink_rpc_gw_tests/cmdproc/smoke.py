'''
Created on Feb 16, 2022

@author: mballance
'''

import cocotb
import tblink_rpc
import rv_bfms
from tblink_rpc_gw_tests.cmdproc.test_base import TestBase
from tblink_rpc_gw.transport.msg_bfm_cmd import MsgBfmCmd

class SmokeTest(TestBase):

    async def run(self):
        print("--> Run")
        # DST, ID, CMD
        msg = MsgBfmCmd(1, 1, 1)
        print("msg: %s" % str(msg.pack()))
        await self.net_i.send(msg.pack())
        
        msg = MsgBfmCmd(1, 1, 2)
        await self.net_i.send(msg.pack())
        
        msg = MsgBfmCmd(1, 1, 3)
        await self.net_i.send(msg.pack())
        
        print("<-- Run")
        

@cocotb.test()
async def entry(dut):
    t = SmokeTest()
    
    await t.init()
    await t.run()
    