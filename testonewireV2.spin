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
  ow      : "SpinOneWire"
  f       : "FloatMath"
  fp      : "FloatString"
  
VAR
  long addrs[2 * MAX_DEVICES]
  
PUB start | i, numDevices, addr, x

  debug.Start(115_200) 
  ow.start(12)

  repeat
    numDevices := ow.search(ow#REQUIRE_CRC, MAX_DEVICES, @addrs)

    debug.str(string($01, " SpinOneWire Test ", 13, 13, "Devices:"))

    repeat i from 0 to MAX_DEVICES-1
      debug.char(13)
    
      if i => numDevices
        ' No device: Blank line
        'repeat 39
          debug.char(" ")

      else
        addr := @addrs + (i << 3)

        ' Display the 64-bit address        

        debug.hex(LONG[addr + 4], 8)
        debug.hex(LONG[addr], 8)
        debug.str(string("  "))
        debug.char(13)
        
         if BYTE[addr] == ow#FAMILY_DS2502
          ' It's a DS2502 ID TAG. Read it.
          repeat x from 0 to 128
           debug.hex(addr,4)
           debug.str(string("  "))  
           debug.hex(x,4)
           debug.str(string("  "))  
           read(addr) 
           debug.char(13) 
    waitcnt(80_000_000+CNT)

PRI read(addr) | temp, degC, degF

  ow.reset
  ow.writeByte(ow#MATCH_ROM)
  ow.writeAddress(addr)

  repeat
    waitcnt(clkfreq/100 + cnt)
    if ow.readBits(1)
      ' Have a reading! Read it from the scratchpad.
      ow.reset
      ow.writeByte(ow#MATCH_ROM)
      ow.writeAddress(addr)
     
      ow.writeByte(ow#READ_SCRATCHPAD)
      temp := ow.readBits(8)
      
      debug.hex((temp),2)
      return
