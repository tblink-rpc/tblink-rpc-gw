'''
Created on Mar 8, 2022

@author: mballance
'''

import tblink_rpc_core as tbc
from tblink_rpc_core.method_type import MethodType


class InterfaceInst(tbc.InterfaceInst):
    
    def __init__(self,
                 ep,
                 name,
                 iftype,
                 is_mirror,
                 req_f=None):
        super().__init__(ep, name, iftype, is_mirror, req_f)
        self.peer = None
        self.addr = -1
        self._invoke_req_completion_m = {}
        self._call_id = 1
        self._method_id_m = None
        
    def invoke(self,
               method_t : MethodType,
               params,
               completion_f):
        print("gw.InterfaceInst.invoke", flush=True)
        self._ep._ifinst_invoke(
            self,
            method_t,
            params,
            completion_f)
    
    def invoke_rsp(self, call_id, ret):
        """Called by the client to notify call end"""
        print("invoke_rsp", flush=True)
        completion_f = self._invoke_req_completion_m[call_id]
        self._invoke_req_completion_m.pop(call_id)

        print("--> Calling completion_f")
        completion_f(ret)        
        print("<-- Calling completion_f")
        
    def _invoke_req(self,
                method_id,
                params,
                completion_f):
        call_id = self._call_id
        self._call_id += 1
        
        if self._method_id_m is None:
            self._method_id_m = {}
            id = 1
            for m in self._iftype.methods():
                print("m: %s is_export=%d is_mirror=%d" % (m.name(), m.is_export(), self.is_mirror()))
                if (m.is_export() and not self.is_mirror()) or (not m.is_export() and self.is_mirror()):
                    self._method_id_m[id] = m
                    id += 1
        
        # 'ifinst', 'method_t', 'call_id', and 'params'
        
        method_t : MethodType = self._method_id_m[method_id]
        params = self._ep.mkValVec()

        self._invoke_req_completion_m[call_id] = completion_f        
        print("InterfaceInst._invoke_req method_id=%d method=%s" % (
            method_id, method_t.name()), flush=True)
        self._req_f(self, method_t, call_id, params)
        pass
        