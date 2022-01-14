
tblink-rpc-gw uses the same stream-oriented protocol with all IPs. All requests
have responses. Time updates are handled as separate events.

The address of the controller is always 0.

TIPs are assumed to be connected in a ring or mesh network. When a TIP receives
a message intended for another TIP, it forwards the message. When it receives
a message intended for itself, it consumes and does not forward.

TIPs are permitted to insert messages at message boundaries, potentially
introducing back-pressure in the network.

[Header]
  [7]     Type (1=req ; 0=rsp)
  [6:0]   Dst
  
  [7:0]   Payload sz (val+1)

[Payload]
  [...]   sz bytes
  
- Response-type code
  - ACK: 0x01
  - EV: 0x02

Controller Commands
- GetTime
  Request:
    - CMD=0x01
    - ID=XX
  Response:
    - RSP=0x01
    - ID=XX
    - TIME[0..7]

- SetTimer
  Request:
    - CMD=0x02
    - ID=XX
    - TVAL[0..3]
  Response:
    - RSP=0x01
    - ID=XX
    
- Release
  Request:
    - CMD=0x03
    - ID=XX
  Response:
    - RSP=0x01
    - ID=XX
- SetDivisor
  Request:
    - CMD=0x04
    - ID=XX
    - DIV[0..3]
  Response:
    - RSP=0x01
    - ID=XX
    
  
