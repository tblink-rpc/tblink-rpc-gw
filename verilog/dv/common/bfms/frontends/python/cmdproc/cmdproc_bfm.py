'''
Created on Feb 20, 2022

@author: mballance
'''

import tblink_rpc
import ctypes

@tblink_rpc.iftype("cmdproc")
class CmdProcBfm(object):
    
    def __init__(self):
        pass

    @tblink_rpc.impfunc
    def _in_cmd_data(self, data : ctypes.c_uint8):
        print("_in_cmd_data 0x%02x" % data)
        pass
    
    @tblink_rpc.impfunc
    def _in_valid(self, cmd : ctypes.c_uint8, sz : ctypes.c_uint8):
        print("_in_valid cmd=0x%02x sz=0x%02x" % (cmd, sz))
        tblink_rpc.start_soon(self._in_ack(0))
        pass
    
    @tblink_rpc.exptask
    def _in_rsp_data(self, data : ctypes.c_uint8):
        pass
    
    @tblink_rpc.exptask
    def _in_ack(self, sz : ctypes.c_uint8):
        pass
    
    @tblink_rpc.exptask
    def _out_valid(self, cmd : ctypes.c_uint8, sz : ctypes.c_uint8):
        pass
    
    @tblink_rpc.impfunc
    def _out_rsp_data(self, data : ctypes.c_uint8):
        pass
    
    @tblink_rpc.impfunc
    def _out_ack(self, sz : ctypes.c_uint8):
        pass
    
    @tblink_rpc.impfunc
    def _reset(self):
        pass
