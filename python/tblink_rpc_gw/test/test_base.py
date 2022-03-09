'''
Created on Mar 5, 2022

@author: mballance
'''
from enum import Enum, auto
from multiprocessing import Pipe
import traceback

import multiprocessing as mp
from tblink_rpc_gw.msg_ctrl_factory import MsgCtrlFactory
from tblink_rpc_gw.test.pkt import Pkt
from tblink_rpc_gw.test.pkt_kind import PktKind
from tblink_rpc_gw.test.test_backend_transport import TestBackendTransport
from tblink_rpc_gw.test.test_transport import TestTransport
from tblink_rpc.rt.cocotb.mgr import Mgr
import logging
from tblink_rpc_gw.endpoint import Endpoint
from tblink_rpc_core.endpoint import comm_mode_e, comm_state_e
from tblink_rpc_core.endpoint_event import EndpointEvent
from tblink_rpc_core.event_type_e import EventTypeE
from typing import List, Dict
import tblink_rpc
from tblink_rpc.impl.iftype_rgy import IftypeRgy


class TestBase(object):
   
    _remote_proc = None
    _t = None
    
    async def init(self):
        """init method to be overridden by the specific test"""
        pass
    
    async def run(self):
        """run method to be overridden by the specific test"""
        pass
    
    async def get_transport(self) -> TestBackendTransport:
        """Returns the backend transport appropriate to the environment"""
        pass
    
    def get_ifinst_info(self) -> List[Dict]:
        raise NotImplementedError("get_ifinst_info not implemented by %s" % str(type(self)))

    @classmethod    
    def _setup_logging(cls):
        print("_setup_logging", flush=True)

    @classmethod    
    def _proc_main(cls, t, remote_conn):
        
        tp = TestTransport(remote_conn)
        setattr(t, "_tp", tp)

        ep = Endpoint(tp)
        mgr = Mgr.init()
        mgr.ep = ep

        # Ensure known types are registered
        print("--> define_iftypes")
        IftypeRgy.inst().define_iftypes(ep)
        print("<-- define_iftypes")
       
        print("--> Calling get_ifinst_info")
        ifinst_info = t.get_ifinst_info()
        print("<-- Calling get_ifinst_info")

        # TODO: dedicated methods for 
        for info in ifinst_info:
            iftype = ep.findInterfaceType(info["iftype"])
            
            if iftype is None:
                for t in ep.getInterfaceTypes():
                    print("iftype: %s" % t.name())
                raise Exception("Failed to find iftype %s" % str(info["iftype"]))
            
            print("iftype=%s" % str(iftype))
            ifinst = ep.defineHwInterfaceInst(
                iftype,
                info["name"],
                info["is_mirror"],
                info["addr"]
                )
            print("info: %s" % str(info))
        
        from tblink_rpc import cocotb_compat
        print("--> _set_ep %s" % str(ep))
        cocotb_compat.reinit()
        cocotb_compat._set_ep(ep)
        print("<-- _set_ep")
        cocotb_compat._time_controller = True
        
        print("logging.getLogger=%s" % str(logging.getLogger()), flush=True)
        logging.getLogger().handlers.clear()
        print("logging.getLogger.handlers=%s" % str(logging.getLogger().handlers), flush=True)

        import cocotb
        # cocotb seems to have difficulty re-configuring logging.
        # Just skip it (stub out)
        cocotb._setup_logging = cls._setup_logging
        
        print("--> call _initialise_testbench", flush=True)
        try:
            cocotb._initialise_testbench([])
        except Exception as e:
            print("Exception: %s" % str(e), flush=True)
            traceback.print_exc()
            
        print("<-- call _initialise_testbench", flush=True)

        # Must run event loop
        # - process one message
        # - 
        done = False
        
        def ep_event(ev : EndpointEvent):
            nonlocal done
            if ev.kind() == EventTypeE.Terminate:
                print("Shutdown request")
                done = True
                
        ep.addListener(ep_event)
        
        while not done:
            # Release the remote
            print("--> Release")
            ep.update_comm_mode(comm_mode_e.Automatic, comm_state_e.Released)
            print("<-- Release")

            while ep.comm_state() == comm_state_e.Released:
                ret = ep.process_one_message()
            
                if ret == -1:
                    done = True
                    break
            
        tp.shutdown()
        
        #     try:
        #     print("[0] --> Send GetTime Req", flush=True)
        #     tp.send(MsgCtrlFactory.mkGetTimeReq(0))
        #     print("[0] <-- Send GetTime Req", flush=True)
        #
        #     print("[0] --> Recv GetTime Resp", flush=True)
        #     rsp = tp.recv()
        #     print("[0] <-- Recv GetTime Resp", flush=True)
        #
        #     # Set Timer
        #     print("[2] --> Send SetTimer Req", flush=True)
        #     tp.send(MsgCtrlFactory.mkSetTimer(1, 1000))
        #     print("[2] <-- Send SetTimer Req", flush=True)
        #
        #     print("[2] --> Recv SetTimer Resp", flush=True)
        #     rsp = tp.recv()
        #     print("[2] <-- Recv SetTimer Resp", flush=True)
        #
        #     print("[3] --> Send Release Req", flush=True)
        #     tp.send(MsgCtrlFactory.mkRelease(2))
        #     print("[3] <-- Send Release Req", flush=True)
        #
        #     print("[3] --> Recv Release Resp", flush=True)
        #     rsp = tp.recv()
        #     print("[3] <-- Recv Release Resp", flush=True)
        #
        #     print("== Wait for wakeup")
        #
        #     print("--> Recv Wakeup Rsp", flush=True)
        #     rsp = tp.recv()
        #     print("<-- Recv Wakeup Rsp", flush=True)
        #
        #     tp.shutdown()
        # except Exception as e:
        #     traceback.print_exc()
        #     tp.shutdown()
        #     pass

    @classmethod
    async def run_main(cls, T):
        
        if cls._t is not None:
            # Running in a remote proc, so this is the real test
            print("run_main (remote)")
            
            await cls._t.init()
            await cls._t.run()
        else: # Base process: connect to testbench BFMs
            
            print("run_main (base)")
            
            cls._t = T()
            
            tp = await cls._t.get_transport()
            
            remote_conn, this_conn = Pipe()
            cls._remote_proc = mp.Process(
                target=cls._proc_main, 
                args=(cls._t, remote_conn,))
        
            cls._remote_proc.start()        
            
            def ep_event(ev : EndpointEvent):
                print("main ep_event: %s" % str(ev.kind()))

            from tblink_rpc import cocotb_compat
            cocotb_compat._ep.addListener(ep_event)
            
            while True:
                print("--> poll", flush=True)
                ret = this_conn.poll(1)
                print("<-- poll", flush=True)
                
                print("ret=%s" % str(ret))
                
                if ret:
                    obj = this_conn.recv()
                    
                    if obj.kind == PktKind.Term:
                        print("Got term")
                        break
                    elif obj.kind == PktKind.ReqPktSend:
                        print("== PktKind.ReqPktSend")
                        pkt = obj.data
                        
                        await tp.send(pkt)
                        
                        this_conn.send(Pkt(PktKind.RspPkt, data=None))
                        
                    elif obj.kind == PktKind.ReqPktRecv:
                        print("== PktKind.ReqPktRecv")
    
                        rsp = await tp.recv()
                        
                        this_conn.send(Pkt(PktKind.RspPkt, data=rsp))
                    else:
                        print("== Unknown request")
                else:
                    if not cls._remote_proc.is_alive():
                        print("Process closed")
                        break
                    else:
                        print("Process running")
            
            cls._remote_proc.join()

