'''
Created on Feb 16, 2022

@author: mballance
'''

import cocotb
import tblink_rpc
import rv_bfms
from tblink_rpc_gw_tests.cmdproc.test_base import TestBase
from tblink_rpc_gw.transport.msg_bfm_cmd import MsgBfmCmd
import cmdproc

class SmokeTest(TestBase):

    async def run(self):
        print("--> Run")
        
        self.cmdproc._in_cmd_f = self.in_cmd
        self.ep_io._out_cmd_f = self.out_cmd
        
        # DST, ID, CMD
        # msg = MsgBfmCmd(1, 1, 1, [1])
        # print("msg: %s" % str(msg.pack()))
        # rsp = await self.ep_io.send(msg)
        # print("rsp: %s" % str(rsp))
        #
        # msg = MsgBfmCmd(1, 1, 2, [2, 3])
        # rsp = await self.ep_io.send(msg)
        #
        # msg = MsgBfmCmd(1, 1, 3, [3, 4, 5, 6])
        # rsp = await self.ep_io.send(msg)

        print("--> send_bfm_cmd")
        await self.cmdproc.send_bfm_cmd(0x55, [1, 2])
        print("<-- send_bfm_cmd")
        
        print("--> send_bfm_cmd")
        await self.cmdproc.send_bfm_cmd(0x56, [1, 2])
        print("<-- send_bfm_cmd")
        
        print("--> send_bfm_cmd")
        await self.cmdproc.send_bfm_cmd(0x57, [1, 2, 3, 4])
        print("<-- send_bfm_cmd")
        
        print("<-- Run")
        
    def in_cmd(self, cmd, sz, params):
        print("in_cmd: 0x%02x %d %s" % (cmd, sz, str(params)), flush=True)
        return []
    
    def out_cmd(self, msg):
        print("out_cmd: %02x %d %s" % (msg.cmd, len(msg.payload), str(msg.payload)), flush=True)
        data = []
        for i in range(msg.cmd-0x55):
            data.append(i+1)
        rsp = MsgBfmCmd(1, 0, 0, data)
        
        print("rsp: %s" % str(rsp.pack()))
        
        return rsp
        
        

@cocotb.test()
async def entry(dut):
    t = SmokeTest()
    
    await t.init()
    await t.run()
    