'''
Created on Mar 5, 2022

@author: mballance
'''
from multiprocessing.connection import Connection

from tblink_rpc_gw.msg_base import MsgBase
from tblink_rpc_gw.msg_ctrl_factory import MsgCtrlFactory
from tblink_rpc_gw.test.pkt import Pkt
from tblink_rpc_gw.test.pkt_kind import PktKind
from tblink_rpc_gw.transport import Transport


class TestTransport(Transport):
    
    def __init__(self, conn : Connection):
        self._conn = conn
        
    def send(self, msg : MsgBase):
        print("[0] --> Send SendPkt Req", flush=True)
        self._conn.send(Pkt(PktKind.ReqPktSend, msg))
        print("[0] <-- Send SendPkt Req", flush=True)
            
        print("[0] --> Recv SendPkt Resp", flush=True)
        pkt = self._conn.recv()
        print("[0] <-- Recv SendPkt Resp", flush=True)        
        pass
    
    def recv(self) -> MsgBase:
        print("[1] --> Send RecvPkt", flush=True)
        self._conn.send(Pkt(PktKind.ReqPktRecv))
        print("[1] <-- Send RecvPkt", flush=True)
            
        print("[1] --> Recv RecvPkt Resp", flush=True)
        pkt = self._conn.recv()
        print("[1] <-- Recv RecvPkt Resp", flush=True)
        print("[1] pkt: %s %s" % (str(pkt), str(pkt.data.pack())), flush=True)        
        
        return pkt.data
    
    def shutdown(self):
        self._conn.send(Pkt(PktKind.Term, exc=None))
        