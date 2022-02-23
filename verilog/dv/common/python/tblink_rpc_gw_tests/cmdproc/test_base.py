'''
Created on Feb 16, 2022

@author: mballance
'''
import tblink_rpc
import rv_bfms
from rv_bfms.rv_initiator_bfm import RvInitiatorBfm
from cmdproc.cmdproc_bfm import CmdProcBfm
from tblink_rpc_gw_tests.ep_io_bfm import EpIoBfm

class TestBase(object):
    
    def __init__(self):
        self.net_i : RvInitiatorBfm = None
        pass
    
    async def init(self):
        await tblink_rpc.cocotb_compat.init()
        self.net_i = tblink_rpc.cocotb_compat.find_ifinst(".*net_i")
        self.net_o = tblink_rpc.cocotb_compat.find_ifinst(".*net_o")
        self.ep_io = EpIoBfm(self.net_i, self.net_o)
        self.cmdproc : CmdProcBfm = tblink_rpc.cocotb_compat.find_ifinst(".*cmdproc_bfm")
        pass
    
    async def run(self):
        pass
    