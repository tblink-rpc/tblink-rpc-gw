'''
Created on Feb 20, 2022

@author: mballance
'''

import tblink_rpc
import ctypes

@tblink_rpc.iftype("cmdproc")
class CmdProcBfm(object):
    
    def __init__(self):
        self._is_reset = False
        self._reset_ev = tblink_rpc.event()
        self._lock = tblink_rpc.lock()
        self._rsp_data = []
        self._out_ack_ev = tblink_rpc.event()
        self._in_cmd_f = None
        self._in_cmd_params = []
        pass
    
    async def send_bfm_cmd(self, cmd, params):
        await self._lock.acquire()
        sz = len(params)
        for p in params:
            await self._out_cmd_data(p)
        await self._out_valid(cmd, sz)
        self._rsp_data = []
        await self._out_ack_ev.wait()
        self._out_ack_ev.clear()
        ret = self._rsp_data
        self._rsp_data = []
        self._lock.release()

        return ret

    @tblink_rpc.impfunc
    def _in_cmd_data(self, data : ctypes.c_uint8):
        self._in_cmd_params.append(data)
        pass
    
    @tblink_rpc.impfunc
    def _in_valid(self, cmd : ctypes.c_uint8, sz : ctypes.c_uint8):
        tblink_rpc.start_soon(self.process_cmd(cmd, sz))
    
    @tblink_rpc.exptask
    def _in_rsp_data(self, data : ctypes.c_uint8):
        pass
        
    async def process_cmd(self, cmd, sz):
        rsp = self._in_cmd_f(cmd, sz, self._in_cmd_params)
        self._in_cmd_params.clear()
        for r in rsp:
            await self._cmd_rsp_data(r)
        await self._in_ack(len(rsp))
    
    @tblink_rpc.exptask
    def _in_ack(self, sz : ctypes.c_uint8):
        pass
    
    @tblink_rpc.exptask
    def _out_cmd_data(self, data : ctypes.c_uint8):
        pass
    
    @tblink_rpc.exptask
    def _out_valid(self, cmd : ctypes.c_uint8, sz : ctypes.c_uint8):
        pass
    
    @tblink_rpc.impfunc
    def _out_rsp_data(self, data : ctypes.c_uint8):
        self._rsp_data.append(data)
    
    @tblink_rpc.impfunc
    def _out_ack(self, sz : ctypes.c_uint8):
        self._out_ack_ev.set()
        pass
    
    @tblink_rpc.impfunc
    def _reset(self):
        self._is_reset = True
        self._reset_ev.set()
