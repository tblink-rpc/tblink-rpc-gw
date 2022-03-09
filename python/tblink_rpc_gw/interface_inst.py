'''
Created on Mar 8, 2022

@author: mballance
'''

import tblink_rpc_core as tbc

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
        
        