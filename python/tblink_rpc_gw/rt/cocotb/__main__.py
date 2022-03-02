'''
Created on Mar 1, 2022

@author: mballance
'''
import importlib
import sys

from tblink_rpc_core.endpoint import Endpoint
from tblink_rpc_gw.rt.cocotb.mgr import Mgr


def run_cocotb(ep : Endpoint):
    # cocotb has a native module for interfacing with the 
    # simulator. We need to provide our own cocotb 'simulator'
    # module. We do this by inserting our own module prior
    # to importing cocotb.
    sys.modules['cocotb.simulator'] = importlib.import_module("tblink_rpc.rt.cocotb.simulator")
        
    
    
    # Set the endpoint for when the user calls    
    # Note: it's required to import the module here so as
    # to avoid messing up replacement of the simulator module
    from tblink_rpc import cocotb_compat
    cocotb_compat._set_ep(ep)
    
    mgr = Mgr.inst()
    mgr.ep = ep
    
    # TODO: init
    ep.init(None)
    
    while not ep.is_init():
        ep.process_one_message()
        
    import cocotb
    cocotb._initialise_testbench([])
    
    pass

def main():
    '''
    - Initiate connection to hardware platform
    - Pass endpoint to 'core' main
    '''
    pass

if __name__ == "__main__":
    main()
    