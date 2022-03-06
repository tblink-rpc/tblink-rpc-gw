'''
Created on Mar 5, 2022

@author: mballance
'''
from enum import Enum, auto


class PktKind(Enum):
    ReqPktSend = auto()
    ReqPktRecv = auto()
    RspPkt = auto()
    Term = auto()
    
    