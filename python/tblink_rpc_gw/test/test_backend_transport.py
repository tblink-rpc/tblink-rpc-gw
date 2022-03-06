'''
Created on Mar 4, 2022

@author: mballance
'''

from tblink_rpc_gw.msg_base import MsgBase
from tblink_rpc_gw.msg_bfm_cmd import MsgBfmCmd


class TestBackendTransport(object):
    
    async def init(self):
        pass
        
    async def send(self, msg_base : MsgBase):
        raise NotImplementedError("send not implemented by %s" % str(type(self)))
    
    async def recv(self) -> MsgBase:
        dst = await self.recv_b()
                    
        print("dst=%d" % dst)
                   
        # Receive size
        size = await self.recv_b()
        size += 1
                    
        print("size=%d" % size)

        payload = []
        for _ in range(size):
            data = await self.recv_b()
            payload.append(data)
            print("data=%d" % data)
                       
        rsp = MsgBfmCmd(0, payload[1], payload[0])
        rsp.payload.extend(payload[2:])        
   
        return rsp        
    
    async def recv_b(self) -> int:
        raise NotImplementedError("recv_b not implemented by %s" % str(type(self)))
    