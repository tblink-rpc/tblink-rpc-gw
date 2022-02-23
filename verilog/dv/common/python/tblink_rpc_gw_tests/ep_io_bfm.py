'''
Created on Feb 21, 2022

@author: mballance
'''
from tblink_rpc_gw.transport.msg_bfm_cmd import MsgBfmCmd
import tblink_rpc

class EpIoBfm(object):
    
    def __init__(self, i_bfm, o_bfm):
        self._i_bfm = i_bfm
        self._o_bfm = o_bfm
        self._o_bfm.set_req_f(self._o_req)
        self._recv_state = 0
        self._size = 0
        self._payload = []
        self._msg_q = []
        self._msg_q_ev = tblink_rpc.event()
        pass
    
    async def send(self, msg) -> MsgBfmCmd:
        await self._i_bfm.send(msg.pack())
        while len(self._msg_q) == 0:
            await self._msg_q_ev.wait()
            self._msg_q_ev.clear()
        return self._msg_q.pop(0)
        
    def _o_req(self, data):
        print("_o_req: %d %02x" % (self._recv_state, data))
        if self._recv_state == 0: # Receive destination
            self._recv_state = 1
        elif self._recv_state == 1: # Receive size
            self._recv_state = 2
            self._size = data+1
        elif self._recv_state == 2: # Receive payload
            self._payload.append(data)
            if len(self._payload) >= self._size:
                # Queue message
                print("Message: %s" % str(self._payload))
                msg = MsgBfmCmd(0, self._payload[1], self._payload[0])
                for d in self._payload[2:]:
                    msg.payload.append(d)
                self._payload.clear()
                self._recv_state = 0
                self._msg_q.append(msg)
                self._msg_q_ev.set()
                pass
            pass