'''
Created on Feb 28, 2022

@author: mballance
'''

import traceback

from tblink_rpc.time_unit import TimeUnit
import tblink_rpc_core as trc
from tblink_rpc_core.endpoint import comm_state_e, comm_mode_e
from tblink_rpc_gw.msg_ctrl_factory import MsgCtrlFactory
from tblink_rpc_gw.transport import Transport
from tblink_rpc_gw.msg_bfm_cmd import MsgBfmCmd
from tblink_rpc_core.interface_type import InterfaceType
from typing import Callable
from tblink_rpc_gw.interface_inst import InterfaceInst


class Endpoint(trc.EndpointBase):
    
    def __init__(self, tp : Transport):
        super().__init__()
        self._tp = tp
        self._cb_l = []
        self._cb_id = 1
        self._req_id = 1
        self._rsp_m = {}
        self._simtime = 0
        pass
    
    def is_init(self) -> int:
        return 1
    
    def build_complete(self) -> bool:
        
        return 1
    
    def is_build_complete(self) -> int:
        return 1
    
    def connect_complete(self) -> bool:
        # Compare sets of interface instances and link stuff up
       
        # Check that we have expected peer instances
        for ifinst in self._local_interface_inst_l:
            if ifinst.name() not in self._peer_interface_inst_m.keys():
                raise Exception("Missing peer interface inst %s" % ifinst.name())
            else:
                ifinst.peer = self._peer_interface_inst_m[ifinst.name()]
                ifinst.addr = self._peer_interface_inst_m[ifinst.name()].addr
        
        # Check that we have expected local instances
        for ifinst in self._peer_interface_inst_l:
            if ifinst.name() not in self._local_interface_inst_m.keys():
                raise Exception("Missing local interface inst %s" % ifinst.name())
            
        return 1
    
    def is_connect_complete(self) -> int:
        return 1
    
    def update_comm_mode(self, m : comm_mode_e, s : comm_state_e):
        if s == comm_state_e.Released and s != self._comm_state:
            print("--> Releasing")
            self._tp.send(MsgCtrlFactory.mkRelease(self._req_id))
            self._req_id += 1
            print("<-- Releasing")
        super().update_comm_mode(m, s)
            
        self._comm_mode = m 
        self._comm_state = s
    
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
            print("Timer: %d" % self._cb_l[0][0])
            self._tp.send(MsgCtrlFactory.mkSetTimer(
                self._req_id, 
                self._cb_l[0][0]))
            self._req_id += 1

            # Receive the set-timer response            
            self._tp.recv()
            
        return id
        
    def cancel_callback(self, cb_id):
        for i in range(len(self._cb_l)):
            if self._cb_l[i][2] == id:
                self._cb_l.pop(i)
                break
            
    def time(self)->int:
        return self._simtime
    
    def time_precision(self)->TimeUnit:
        return TimeUnit.ns
    
    def defineInterfaceInst(self, 
                            iftype : InterfaceType,
                            inst_name : str,
                            is_mirror : bool,
                            req_f : Callable) -> InterfaceInst:
        """Defines a new interface instance"""
        ifinst = InterfaceInst(self, inst_name, iftype, is_mirror, req_f)
        self._local_interface_inst_m[inst_name] = ifinst
        self._local_interface_inst_l.append(ifinst)
        
        return ifinst
    
    def defineHwInterfaceInst(self,
                              iftype : InterfaceType,
                              inst_name : str,
                              is_mirror : bool,
                              addr : int):
        ifinst = InterfaceInst(self, inst_name, iftype, is_mirror)
        ifinst.addr = addr
        
        self._peer_interface_inst_m[inst_name] = ifinst
        self._peer_interface_inst_l.append(ifinst)
        
        return ifinst
    
    def process_one_message(self):
        """
        Blocks until a single message is processed. This must be used 
        *very* sparingly, but may be done to implement operations 
        that are blocking and non-async from a user perspective.
        In many cases, the Endpoint implementation simply delegates 
        to the underlying transport.
        """
        
        pkt = None
        try:
            print("--> recv")
            pkt = self._tp.recv()
            print("<-- recv: %s" % str(pkt))
            print("id=%d cmd=%d payload=%s" % (pkt.id, pkt.cmd, str(pkt.payload)))
            
            if pkt.cmd == 0:
                print("TODO: Handle as a response")
                if pkt.id in self._rsp_m.keys():
                    self._rsp_m[pkt.id](pkt)
                    self._rsp_m.pop(pkt.id)
            else:
                print("TODO: Handle as a request")
                if pkt.id == 0:
                    # This is a request from ctrl
                    if pkt.cmd == 1:
                        print("Timer expired")
                        self._comm_state = comm_state_e.Waiting

                        # Query the controller for the current time
                        # TODO: This really should be scaled by the uclock period and clkdiv                        
                        self._simtime = self._get_simtime()
                        
                        first = self._cb_l.pop(0)
                        first[1]()
                        while len(self._cb_l) > 0 and self._cb_l[0][0] == 0:
                            self._cb_l[0][1]()
                            self._cb_l.pop(0)
                            
                        if len(self._cb_l) > 0:
                            print("Reset timer %d", self._cb_l[0][0])
                            self._send(MsgCtrlFactory.mkSetTimer(
                                0, self._cb_l[0][0]))
                            
                    else:
                        print("TODO: handle ctrl request %d" % pkt.cmd)
                    pass
                else:
                    # This is a request from one of the connected EPs
                    pass
                
        except Exception as e:
            traceback.print_exc()

        return 1
    
    def _send(self, pkt, rsp_f=None):
        id = self._req_id
        self._req_id += 1
        pkt.id = id
        if rsp_f is not None:
            self._rsp_m[id] = rsp_f
        self._tp.send(pkt)
        
    def _send_get_rsp(self, pkt) -> MsgBfmCmd:
        rsp = None
        
        def rsp_f(rsp_p):
            nonlocal rsp
            rsp = rsp_p

        self._send(pkt, rsp_f)
        
        while rsp is None:
            if self.process_one_message() == -1:
                break

        return rsp
    
    def _get_simtime(self):
        # Request the time
        pkt = MsgCtrlFactory.mkGetTimeReq(0)
        time_rsp = self._send_get_rsp(pkt)

        time = 0
        for i in range(7, -1, -1):      
            time <<= 8
            time |= time_rsp.payload[i]
                       
        print("time: %d" % time)
        return time
    
    