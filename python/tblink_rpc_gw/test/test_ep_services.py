'''
Created on Mar 4, 2022

@author: mballance
'''
from tblink_rpc_core.endpoint import Endpoint
from tblink_rpc_core.endpoint_services import EndpointServices
from multiprocessing.connection import Connection


class TestEpServices(EndpointServices):
    
    def __init__(self, conn : Connection):
        self._conn = conn
        self._ep = None
    
    def init(self, ep:Endpoint):
        self._ep = ep
        
    def add_time_cb(self, time, callback_id)->int:
        EndpointServices.add_time_cb(self, time, callback_id)
        