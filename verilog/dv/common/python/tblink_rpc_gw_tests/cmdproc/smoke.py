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
        print("--> Run")
        await super().run()
        print("<-- Run")
        

@cocotb.test()
async def entry(dut):
    t = SmokeTest()
    
    await t.init()
    await t.run()
    