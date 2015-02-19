 {{

SpinOneWire
-----------

This object is a Spin-only implementation of a Dallas/Maxim 1-wire bus master.

It should be a drop-in replacement for Cam Thompson's OneWire object.
This object does not require a separate cog, but it sacrifices
speed and timing accuracy to accomplish this. This object requires an
80 MHz clock.

In addition to the functions available in OneWire, this object provides
built-in functions for reading DS18B20 temperature sensors.
     
┌───────────────────────────────────┐
│ Copyright (c) 2008 Micah Dowty    │               
│ See end of file for terms of use. │
└───────────────────────────────────┘

}}

CON
  ' Required clock frequency.
  CONST_CLKFREQ = 80_000_000

  ' Ticks per microsecond. We require an 80 MHz clock.
  USEC_TICKS = CONST_CLKFREQ / 1_000_000

  ' 1-wire commands
  SEARCH_ROM         = $F0
  READ_MEMORY        = $F0
  READ_ROM          = $33
  MATCH_ROM         = $55
  SKIP_ROM          = $CC
  ALARM_SEARCH      = $EC
  READ_SCRATCHPAD   = $BE
  CONVERT_T         = $44
  COPY_SCRATCHPAD   = $48
  RECALL_EE         = $B8
  READ_POWER_SUPPLY = $B4

  ' 1-wire family codes
  FAMILY_DS2502     = $09

  ' Search flags
  REQUIRE_CRC       = $100
  
VAR
  long  pin

PUB start(dataPin) : okay
  '' Initialize, using the provided data pin. Does not allocate a cog.
  '' For compatibility with OneWire.spin, always returns success.

  pin := dataPin
  outa[pin]~
  dira[pin]~
  okay~

PUB stop
  '' For compatibility with OneWire.spin. Does nothing.

PUB reset : present
  '' Issue a one-wire reset signal.
  '' Returns 1 if a device is present, 0 if not.

  ' Make sure the line isn't shorted
  if not ina[pin]
    present~
    return
  
  ' Pulse low for 480 microseconds or more.
  dira[pin]~~
  waitcnt(constant(USEC_TICKS * 480) + cnt)
  dira[pin]~

  ' The presence pulse will last a minimum of 60us.
  ' Wait about 30us, then sample.
  dira[pin]~ 
  dira[pin]~ 
  dira[pin]~ 
  dira[pin]~ 
  present := not ina[pin]
  
  ' Wait for the rest of the reset timeslot  
  waitcnt(constant(USEC_TICKS * 480) + cnt)

PUB writeAddress(p) | ah, al
  longmove(@ah, p, 2)
  writeBits(ah, 32)
  writeBits(al, 32)

PUB readAddress(p) | ah, al
  ah := readBits(32)
  al := readBits(32)
  longmove(p, @ah, 2)

PUB writeByte(b)
  writeBits(b, 8)

PUB readByte
  return readBits(8)

PUB writeBits(b, n)
  repeat n
    if b & 1
      ' Write 1: Low for at least 1us, High for about 40us
      dira[pin]~~
      dira[pin]~
      dira[pin]~
      dira[pin]~
      dira[pin]~
      dira[pin]~
    else
      ' Write 0: Low for 40us
      dira[pin]~~
      dira[pin]~~
      dira[pin]~~
      dira[pin]~~
      dira[pin]~~
      dira[pin]~
    b >>= 1

PUB readBits(n) : b | mask
  b := 0
  mask := 1
  
  repeat n
    ' Pull low briefly, then sample.
    ' Ideally we'd be sampling 15us after pulling low.
    ' Our timing won't be that accurate, but we can be close enough.

    dira[pin]~~
    dira[pin]~
    if ina[pin]
      b |= mask

    mask <<= 1
              
PUB search(flags, maxAddrs, addrPtr) : numFound | bit, rom[2], disc, discMark, locked, crc
  '' Search the 1-wire bus.
  ''
  '' 'flags' is a set of search options. The lower 8 bits, if nonzero,
  '' are a family code to restrict the search to. If set, only devices
  '' belonging to that family will be enumerated. If the FLAG_CRC bit is
  '' set, only addresses that include a valid CRC code will be returned.
  ''  
  '' 'maxAddrs' is the maximum number of 64-bit addresses to find, and
  '' 'addrPtr' points to a buffer which must be large enough to hold
  '' 'maxAddrs' 64-bit words.
  ''
  '' Returns the number of addresses we actually found. Addresses are written
  '' to 'addrPtr', low word first. (little endian)

  ' This is an adaptation of the "ROM SEARCH" algorithm from the
  ' iButton Book of Standards at www.maxim-ic.com/ibuttonbook. 
  
  rom[1]~
  numFound~
  disc~
  locked~

  ' Optionally restrict to a single family
  rom[0] := flags & $FF
  if rom[0]
    locked := 8
    
  repeat maxAddrs
    if !reset
      ' No device responded with a presence pulse.
      return

    writeByte(SEARCH_ROM)
    discMark~
    
    repeat bit from 1 to 64
      if bit > locked
        case readBits(2)

          %00:  ' Conflict.

            if bit == disc
              ' We tried a zero here last time, try a one now
              setBit64(@rom, bit, 1)

            elseif bit > disc
              setBit64(@rom, bit, 0)
              discMark := bit

            elseif getBit64(@rom, bit) == 0
              discMark := bit
            
          %01:  ' All devices read 1.
            setBit64(@rom, bit, 1)
 
          %10:  ' All devices read 0
            setBit64(@rom, bit, 0)

          %11:  ' No response from any device. Give up!
            return

      else
        ' Bit is locked. Ignore the device.
        readBits(2)
  
      ' Reply, selecting only devices that match this bit.
      writeBits(getBit64(@rom, bit), 1)

    ' At the end of every iteration, we've discovered one device's address.
    ' Optionally check its CRC.

    if flags & REQUIRE_CRC
      crc := crc8(8, @rom)
    else
      crc := 0

    if crc == 0
      longmove(addrPtr, @rom, 2)
      addrPtr += 8
      numFound++

    ' Is the search done yet?
    disc := discMark
    if disc == 0
      return
    
PRI getBit64(p, n) : bit
  ' Return bit 'n' (1-based) in a 64-bit word at address 'p'.
  n -= 1
  bit := (BYTE[p + (n>>3)] >> (n&7)) & 1

PRI setBit64(p, n, bit)
  ' Set or clear bit 'n' (1-based) in a 64-bit word at address 'p'.
  n -= 1
  if n => 32
    n -= 32
    p += 4
  if bit
    LONG[p] |= |< n
  else
    LONG[p] &= !|< n

PUB crc8(n, p) : crc | b
  '' Calculate the CRC8 of 'n' bytes, starting at address 'p'.

  crc := 0

  ' Loop over all bits, LSB first.
  repeat n
    b := BYTE[p++]
    repeat 8
    
      ' CRC polynomial: x^8 + x^5 + x^4 + 1
      if (crc ^ b) & 1
        crc := (crc >> 1) ^ $8C
      else
        crc >>= 1
  
      b >>= 1    

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}   
