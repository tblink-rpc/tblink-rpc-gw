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
        
        from tblink_rpc import cocotb_compat
        cocotb_compat._set_ep(ep)
        
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

        try:
            print("[0] --> Send GetTime Req", flush=True)
            tp.send(MsgCtrlFactory.mkGetTimeReq(0))
            print("[0] <-- Send GetTime Req", flush=True)
            
            print("[0] --> Recv GetTime Resp", flush=True)
            rsp = tp.recv()
            print("[0] <-- Recv GetTime Resp", flush=True)
            
            # Set Timer
            print("[2] --> Send SetTimer Req", flush=True)
            tp.send(MsgCtrlFactory.mkSetTimer(1, 1000))
            print("[2] <-- Send SetTimer Req", flush=True)
            
            print("[2] --> Recv SetTimer Resp", flush=True)
            rsp = tp.recv()
            print("[2] <-- Recv SetTimer Resp", flush=True)
            
            print("[3] --> Send Release Req", flush=True)
            tp.send(MsgCtrlFactory.mkRelease(2))
            print("[3] <-- Send Release Req", flush=True)
            
            print("[3] --> Recv Release Resp", flush=True)
            rsp = tp.recv()
            print("[3] <-- Recv Release Resp", flush=True)
            
            print("== Wait for wakeup")
            
            print("--> Recv Wakeup Rsp", flush=True)
            rsp = tp.recv()
            print("<-- Recv Wakeup Rsp", flush=True)
            
            tp.shutdown()
        except Exception as e:
            traceback.print_exc()
            tp.shutdown()
            pass

    @classmethod
    async def run_main(cls, T):
        
        if cls._t is not None:
            # Running in a remote proc, so this is the real test
            print("run_main (remote)")
            
            await cls._t.init()
            await cls._t.run()
        else: # Base process: connect to testbench BFMs
            
            cls._t = T()
            
            tp = await cls._t.get_transport()
            
            remote_conn, this_conn = Pipe()
            cls._remote_proc = mp.Process(
                target=cls._proc_main, 
                args=(cls._t, remote_conn,))
        
            cls._remote_proc.start()        
            
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

