'''
Created on Jan 21, 2022

@author: mballance
'''
from tblink_rpc_gw.transport.msg_base import MsgBase

class MsgBfmCmd(MsgBase):
    
    def __init__(self, dst, id, cmd, payload=None):
        super().__init__(dst)
        self.id = id
        self.cmd = cmd
        
        if payload is not None:
            self.payload.extend(payload)
        
    def pack(self):
        ret = []
        ret.append(self.dst & 0xFF)
        ret.append(len(self.payload)+2-1)
        ret.append(self.cmd & 0xFF)
        ret.append(self.id & 0xFF)
        for b in reversed(self.payload):
            ret.append(b)
        
        return ret
    