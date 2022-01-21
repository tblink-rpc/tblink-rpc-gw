'''
Created on Jan 14, 2022

@author: mballance
'''

class MsgBase(object):
    
    def __init__(self, dst=0):
        self.dst = dst
        self.payload = []
        
    def pack(self):
        ret = []
        ret.append(self.dst & 0xFF)
        ret.append(len(self.payload)-1)
        ret.extend(self.payload)
        
        return ret
        