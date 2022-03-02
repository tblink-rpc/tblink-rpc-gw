'''
Created on Feb 28, 2022

@author: mballance
'''

import tblink_rpc_core as trc
from tblink_rpc_gw.transport import Transport

class Endpoint(trc.EndpointBase):
    
    def __init__(self, tp : Transport):
        self._tp = tp
        pass
    
    