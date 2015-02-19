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
  
PUB start | i, numDevices, addr, Address

  debug.Start(115_200) 
  ow.start(12)

  repeat i from 0 to 1
    numDevices := ow.search(ow#REQUIRE_CRC, MAX_DEVICES, @addrs)

    'debug.str(string($01, " SpinOneWire Test ", 13, 13, "Devices:"))

    repeat i from 0 to MAX_DEVICES-1
      debug.char(13)
    
      if i => numDevices
        ' No device: Blank line
        'repeat 39
        debug.char(" ")
      else
        addr := @addrs + (i << 3)
        ' Display the 64-bit address        
        debug.Str(string("ID Tag serial number: "))
        debug.hex(LONG[addr + 4], 8)
        debug.hex(LONG[addr], 8)
        debug.str(string("  "))
        debug.NewLine

         if BYTE[addr] == ow#FAMILY_DS2502
         ' It's a DS2502 ID TAG. Read it.
         debug.Str(string("Reading data from the momeory addressess:"))
         debug.NewLine
             repeat Address from 0 to 127
                  ' start reading from address 0 to 127
                  debug.Str(string("Address: "))
                  debug.Dec(Address)
                  debug.Str(string("    "))
                  ' Call function to read data from EPROM
                  ReadData(Address)
    waitcnt(80_000_000+CNT)

PRI ReadData(addr) | data, crc
  ow.reset
  ow.writeByte(ow#MATCH_ROM)
  ow.writeAddress(addr)
  repeat
    waitcnt(clkfreq/100 + cnt)
    if ow.readBits(1)
      ow.reset
      ' Not exactly sure whats happening here
      ' I think it is asking the hardware to skip the ROM
      ' which we have already read
      ow.writeByte(ow#SKIP_ROM)
      ' It is configuring the ID Tag to read mode so that
      ' data can be read from the EPROM
      ow.writeByte(ow#READ_MEMORY)
      ' This is the particular address specified where data is read from
      ow.writeByte(addr)
      ' Not sure what 0 means.
      ow.writeByte(0)
     
      data := ow.readBits(16)
      debug.Str(string("Data: "))
      debug.hex((data),4)
      debug.str(string("  "))
      ' Trying to print CRC
      'crc := ow.crc8(2, 0)
      'debug.Hex((crc), 2)
      debug.NewLine
      return
