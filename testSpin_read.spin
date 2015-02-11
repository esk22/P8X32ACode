 {{

SpinOneWire-test
----------------

This is a simple example for the SpinOneWire object. Connect up to eight 1-wire
devices to pin 10, a TV output starting at pin 12, and you'll get a real-time
listing of the devices on the bus. If there are any DS18B20 temperature sensors
attached, we'll read their temperature too.

┌───────────────────────────────────┐
│ Copyright (c) 2008 Micah Dowty    │               
│ See end of file for terms of use. │
└───────────────────────────────────┘

}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  FAMILY_DS1820  = 16
  MAX_DEVICES = 8
  
OBJ
  debug   : "Parallax Serial Terminal"      ''  Parallax Serial Terminal 
' ow      : "OneWire"
  ow1      : "SpinOneWire"
  ow2    :"SpinOneWire"
  f       : "FloatMath"
  fp      : "FloatString"
  
VAR
  long addrs1
  long addrs2
  long  Stack1[50]
  long  Stack2[50]
  long addr1
  long addr2
  long mem1
  long mem2
  
PUB GO
  cognew (COG_READ2, @Stack1)
  cognew (COG_READ1, @Stack2)
  
repeat
        debug.hex(LONG[addr1+4], 8)
        debug.hex(LONG[addr1], 8)
        debug.hex((mem1),4)
        debug.NewLine
        debug.hex(LONG[addr2+4], 8)
        debug.hex(LONG[addr2], 8)
        debug.hex((mem2),4)
        debug.NewLine
        debug.NewLine
        debug.NewLine
  
PRI COG_READ1 | i, numDevices

  debug.Start(115_200) 
  ow1.start(10)
  numDevices := ow1.search(ow1#REQUIRE_CRC, MAX_DEVICES, @addrs1)
     
  addr1 := @addrs1 + (0 << 3)
  
  if BYTE[addr1] == ow1#FAMILY_DS2502
          ' It's a DS2502 ID TAG. Read it.
          read1(0)
   
  waitcnt(80_000_000+CNT)      

PRI COG_READ2 | i, numDevices
  debug.Start(115_200) 
  ow2.start(12)
  
  
  numDevices := ow2.search(ow2#REQUIRE_CRC, MAX_DEVICES, @addrs2)
  
  addr2 := @addrs2 + (0 << 3)
  
  if BYTE[addr2] == ow2#FAMILY_DS2502
          ' It's a DS2502 ID TAG. Read it.
          read2(0) 

  waitcnt(80_000_000+CNT)


PRI read1(addr) |  degC, degF, temp

  ow1.reset
  ow1.writeByte(ow1#MATCH_ROM)
  ow1.writeAddress(addr)

  repeat
    waitcnt(clkfreq/100 + cnt)
    if ow1.readBits(1)
      ' Have a reading! Read it from the scratchpad.
      ow1.reset
      ow1.writeByte(ow1#SKIP_ROM)
      ow1.writeByte(ow1#READ_MEMORY)
      ow1.writeByte($18)
      ow1.writeByte(0)

      
     

      mem1 := ow1.readBits(16)
      
      
      return


PRI read2(addr) |  degC, degF

  ow2.reset
  ow2.writeByte(ow2#MATCH_ROM)
  ow2.writeAddress(addr)

  repeat
    waitcnt(clkfreq/100 + cnt)
    if ow2.readBits(1)
      ' Have a reading! Read it from the scratchpad.
      ow2.reset
      ow2.writeByte(ow2#MATCH_ROM)
      ow2.writeAddress(addr)
     
      ow2.writeByte(ow1#READ_SCRATCHPAD)
      mem2 := ow2.readBits(16)
      
      
      return

 
