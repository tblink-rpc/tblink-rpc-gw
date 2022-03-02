'''
Created on Feb 28, 2022

@author: mballance
'''
from tblink_rpc_gw.msg_base import MsgBase

class Transport(object):

    def send(self, msg_base : MsgBase):
        raise NotImplementedError("send not implemented by %s" % str(type(self)))
    
    def recv(self) -> MsgBase:
        raise NotImplementedError("recv not implemented by %s" % str(type(self)))
    