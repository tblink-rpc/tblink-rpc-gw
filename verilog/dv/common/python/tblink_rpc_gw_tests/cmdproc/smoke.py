'''
Created on Feb 16, 2022

@author: mballance
'''

import cocotb
import tblink_rpc
import rv_bfms
from tblink_rpc_gw_tests.cmdproc.test_base import TestBase

class SmokeTest(TestBase):

    async def run(self):
        await super().run()
        

@cocotb.test()
async def entry(dut):
    t = SmokeTest()
    
    await t.init()
    await t.run()
    
    print("Hello World!")
    print("--> init")
    await tblink_rpc.cocotb_compat.init()
    
    for bfm in tblink_rpc.cocotb_compat.ifinsts():
        print("Bfm: %s" % bfm.inst_name())
        
    print("<-- init")
    pass