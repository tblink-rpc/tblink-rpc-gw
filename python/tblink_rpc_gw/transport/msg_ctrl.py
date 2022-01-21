'''
Created on Jan 14, 2022

@author: mballance
'''
from tblink_rpc_gw.transport.msg_base import MsgBase

class MsgCtrl(MsgBase):
    
    def __init__(self):
        super().__init__()
        self.cmd = 0
        self.id = 0
        
    def pack(self):
        ret = []
        ret.append(self.dst & 0xFF)
        ret.append(len(self.payload)+2-1)
        ret.append(self.cmd & 0xFF)
        ret.append(self.id & 0xFF)
        ret.extend(self.payload)
        
        return ret
    