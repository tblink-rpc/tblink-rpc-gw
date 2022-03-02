'''
Created on Jan 14, 2022

@author: mballance
'''
from tblink_rpc_gw.msg_base import MsgBase
from tblink_rpc_gw.msg_ctrl import MsgCtrl

class MsgCtrlFactory(object):
    
    @staticmethod
    def mkGetTimeReq(req_id):
        ret = MsgCtrl()
        ret.dst = 0
        ret.cmd = 0x01
        ret.id = req_id
        return ret
    
    @staticmethod
    def mkSetTimer(req_id, tval):
        ret = MsgCtrl()
        ret.dst = 0
        ret.cmd = 0x02
        ret.id = req_id
        ret.payload.append(((tval >>0) & 0xFF))
        ret.payload.append(((tval >>8) & 0xFF))
        ret.payload.append(((tval >>16) & 0xFF))
        ret.payload.append(((tval >>24) & 0xFF))
        return ret
    
    @staticmethod
    def mkRelease(req_id):
        ret = MsgCtrl()
        ret.dst = 0
        ret.cmd = 0x03
        ret.id = req_id
        return ret
    
    @staticmethod
    def mkSetDivisor(req_id, div):
        ret = MsgCtrl()
        ret.dst = 0
        ret.cmd = 0x04
        ret.id = req_id
        ret.payload.append(((div >>0) & 0xFF))
        ret.payload.append(((div >>8) & 0xFF))
        ret.payload.append(((div >>16) & 0xFF))
        ret.payload.append(((div >>24) & 0xFF))
        return ret
