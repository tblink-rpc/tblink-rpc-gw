'''
Created on Feb 28, 2022

@author: mballance
'''

import tblink_rpc_core as trc
from tblink_rpc_gw.transport import Transport
from tblink_rpc_gw.msg_ctrl_factory import MsgCtrlFactory
from tblink_rpc.time_unit import TimeUnit

class Endpoint(trc.EndpointBase):
    
    def __init__(self, tp : Transport):
        super().__init__()
        self._tp = tp
        self._cb_l = []
        self._cb_id = 1
        self._req_id = 1
        pass
    
    def is_init(self) -> int:
        return 1
    
    def build_complete(self) -> bool:
        return True
    
    def is_build_complete(self) -> int:
        return 1
    
    def connect_complete(self) -> bool:
        return True
    
    def is_connect_complete(self) -> int:
        return 1
    
    
    def add_time_callback(self, time, cb_f)->int:
        id = self._cb_id
        self._cb_id += 1
        
        offset = time
        
        set_timer = False
        
        if len(self._cb_l) == 0:
            self._cb_l.append((offset, cb_f, id))
            set_timer = True
        else:
            # Walk through the callback list reducing offset
            # until we find the place to insert
            for i in range(len(self._cb_l)):
                if offset < self._cb_l[i][0]:
                    self._cb_l.insert(i, (offset, cb_f, id))
                    if i == 0:
                        set_timer = True
                    break
                else:
                    offset -= self._cb_l[i][0]
                    
                    if i+1 >= len(self._cb_l):
                        self._cb_l.append((offset, cb_f, id))
                        
        if set_timer:
            self._tp.send(MsgCtrlFactory.mkSetTimer(
                self._req_id, 
                self._cb_l[0][0]))
            self._req_id += 1

            # Receive the set-timer response            
            self._tb.recv()
            
        return id
        
    def cancel_callback(self, cb_id):
        for i in range(len(self._cb_l)):
            if self._cb_l[i][2] == id:
                self._cb_l.pop(i)
                break
            
    def time(self)->int:
        return 0
    
    def time_precision(self)->TimeUnit:
        return TimeUnit.ns
    
    