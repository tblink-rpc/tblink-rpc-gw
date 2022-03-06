'''
Created on Mar 5, 2022

@author: mballance
'''

class Pkt(object):
    
    def __init__(self, kind, data=None, exc=None):
        self.kind = kind
        self.data = data
        self.exc = exc
