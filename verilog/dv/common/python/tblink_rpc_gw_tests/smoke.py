'''
Created on Nov 2, 2021

@author: mballance
'''

import tblink_rpc_cocotb
from rv_bfms.rv_initiator_bfm import RvInitiatorBfm
from rv_bfms.rv_target_bfm import RvTargetBfm
import cocotb

class Smoke(object):
    
    async def init(self):
        await tblink_rpc_cocotb.init()
        self.u_net_i : RvInitiatorBfm = tblink_rpc_cocotb.find_ifinst(".*u_net_i")
        self.u_net_o : RvTargetBfm = tblink_rpc_cocotb.find_ifinst(".*u_net_i")
        
    async def run(self):
        await self.u_net_i.send(0x01) # Destination
        await self.u_net_i.send(0x01) # Size
        await self.u_net_i.send(0x55) # Data
        
        await cocotb.triggers.Timer(10, "us")
        
        # await self.u_tx_bfm.send(0x00) # Capture data
        # data = await self.u_rx_bfm.recv()
        # print("Rx: 0x%02x" % data)
        # data = await self.u_rx_bfm.recv()
        # print("Rx: 0x%02x" % data)
        #
        # # Now, advance for 1 cycle
        # await self.u_tx_bfm.send((2 << 2) | 1) 
        # data = await self.u_rx_bfm.recv()
        # print("Rx: 0x%02x" % data)
        #
        # await self.u_tx_bfm.send(0x00) # Capture data
        # data = await self.u_rx_bfm.recv()
        # print("Rx: 0x%02x" % data)
        # data = await self.u_rx_bfm.recv()
        # print("Rx: 0x%02x" % data)
        #
        # # Now, advance for 1 cycle
        # await self.u_tx_bfm.send((40 << 2) | 1) 
        # data = await self.u_rx_bfm.recv()
        # print("Rx: 0x%02x" % data)
        #
        # await self.u_tx_bfm.send(0x00) # Capture data
        # data = await self.u_rx_bfm.recv()
        # print("Rx: 0x%02x" % data)
        # data = await self.u_rx_bfm.recv()
        # print("Rx: 0x%02x" % data)
        #
        # await self.u_tx_bfm.send(0x00) # Capture data
        # data = await self.u_rx_bfm.recv()
        # print("Rx: 0x%02x" % data)
        # data = await self.u_rx_bfm.recv()
        # print("Rx: 0x%02x" % data)
        
        pass
    
@cocotb.test()
async def entry(dut):
    t = Smoke()
    await t.init()
    await t.run()

    await cocotb.triggers.Timer(10, "us")
       

       
       
        