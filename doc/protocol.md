
tblink-rpc-gw uses the same stream-oriented protocol with all IPs. All requests
have responses. Time updates are handled as separate events.

The address of the controller is always 0.

TIPs are assumed to be connected in a ring or mesh network. When a TIP receives
a message intended for another TIP, it forwards the message. When it receives
a message intended for itself, it consumes and does not forward.

TIPs are permitted to insert messages at message boundaries, potentially
introducing back-pressure in the network.

[Header]
  [7]     Type (1=req ; 0=rsp) -- ?
  [6:0]   Dst
  
  [7:0]   Payload sz (val+1)

[Payload]
  [...]   sz bytes
  
- Response-type code
  - ACK: 0x01
  - EV: 0x02

# Controller Commands

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

# BFM Messages

BFM messages have a common format, but the way that data is interpreted 
is BFM-specific.

- Request
  - CMD != 0
  - ID
  - Data [0..N]
  
- Response
  - CMD == 0
  - ID (Matches request)
  - Data [0..N]

## Payload ordering
BFMs receive parameter data via a vector N-bits in size. The actual amount of 
data sent is also presented to the BFM. To simplify hardware implementation,
the endianness of data transfer is different for requests to hardware and
responses from hardware.

Parameter data in requests to hardware is big-endian ordered. In other words,
the byte that appears at the top of the 'valid' portion of the parameters
vector is sent first.

Parameter data in responses from hardware is little-endian ordered. In other
words, the byte that appears at the bottom of the 'valid' portion of the
parameters is sent first.


  
