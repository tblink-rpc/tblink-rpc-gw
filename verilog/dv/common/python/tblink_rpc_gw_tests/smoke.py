'''
Created on Nov 2, 2021

@author: mballance
'''
import pybfms
from rv_bfms.rv_data_out_bfm import ReadyValidDataOutBFM
from rv_bfms.rv_data_in_bfm import ReadyValidDataInBFM
import cocotb

class Smoke(object):
    
    async def init(self):
        await pybfms.init()
        self.u_tx_bfm : ReadyValidDataOutBFM = pybfms.find_bfm(".*u_tx_bfm")
        self.u_rx_bfm : ReadyValidDataInBFM  = pybfms.find_bfm(".*u_rx_bfm")
        
    async def run(self):
        await cocotb.triggers.Timer(10, "us")
        
        await self.u_tx_bfm.send(0x00) # Capture data
        data = await self.u_rx_bfm.recv()
        print("Rx: 0x%02x" % data)
        data = await self.u_rx_bfm.recv()
        print("Rx: 0x%02x" % data)
        
        # Now, advance for 1 cycle
        await self.u_tx_bfm.send((2 << 2) | 1) 
        data = await self.u_rx_bfm.recv()
        print("Rx: 0x%02x" % data)
        
        await self.u_tx_bfm.send(0x00) # Capture data
        data = await self.u_rx_bfm.recv()
        print("Rx: 0x%02x" % data)
        data = await self.u_rx_bfm.recv()
        print("Rx: 0x%02x" % data)
        
        # Now, advance for 1 cycle
        await self.u_tx_bfm.send((40 << 2) | 1) 
        data = await self.u_rx_bfm.recv()
        print("Rx: 0x%02x" % data)
        
        await self.u_tx_bfm.send(0x00) # Capture data
        data = await self.u_rx_bfm.recv()
        print("Rx: 0x%02x" % data)
        data = await self.u_rx_bfm.recv()
        print("Rx: 0x%02x" % data)
        
        await self.u_tx_bfm.send(0x00) # Capture data
        data = await self.u_rx_bfm.recv()
        print("Rx: 0x%02x" % data)
        data = await self.u_rx_bfm.recv()
        print("Rx: 0x%02x" % data)
        
        pass
    
@cocotb.test()
async def entry(dut):
    t = Smoke()
    await t.init()
    await t.run()

    await cocotb.triggers.Timer(10, "us")
       
       
       
       
        