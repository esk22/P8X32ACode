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

Edited by Arun Rai for testing write operation to the DS2502
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
  w       : "SpinOneWire"
  f       : "FloatMath"
  fp      : "FloatString"
  
VAR
  long addrs[2 * MAX_DEVICES]
  byte CRC[4]
  
PUB start | i, numDevices, addr, Address, x, newStr, inbyte

  debug.Start(115_200) 
  ow.start(12)
  w.start(13)
  repeat i from 0 to 1
    numDevices := ow.search(ow#REQUIRE_CRC, MAX_DEVICES, @addrs)

    'debug.str(string($01, " SpinOneWire Test ", 13, 13, "Devices:"))
    
    'waitcnt(clkfreq + cnt)
    'outa[13] := 0
    repeat i from 0 to MAX_DEVICES-1
      'debug.char(15)
    
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
         ' IMPORTANT
         'newStr := debug.strJoin(string("0"), string("9"))
         'x := debug.StrToBase(newStr, 16)
         'debug.Dec(x)
         ' inbyte is the data byte to write to the EPROM
         ' This is for test only
         inbyte := 31
         ' Write byte at memory location x = 124
         'WriteData(124, inbyte)
         ' Read back byte from memory location x
         ReadData(124)
    waitcnt(80_000_000+CNT)
    
PRI WriteData(addr, inbyte) | data, temp, d
  repeat
    if ow.readBits(1)
      repeat
        ow.reset
        ow.writeByte(ow#SKIP_ROM)
        ow.writeByte(ow#WRITE_MEMORY)
        ow.writeByte((addr & $00FF))      ' (TA1=(T7:T0)
        ow.writeByte((addr & $FF00) >> 8) ' (TA1=(T15:T8)
        ow.writeByte(inbyte)    
        CRC[0] := ow#WRITE_MEMORY
        CRC[1] := addr & $00FF
        CRC[2] := (addr & $FF00) >> 8
        CRC[3] := inbyte
        if(ow.crc8(4, @CRC) == ow.readBits(8))
            ow.pulse(16)
            ow.reset
            ow.writeByte(ow#SKIP_ROM)
            ow.writeByte(ow#READ_MEMORY)
            ow.writeByte(addr & $00FF)
            ow.writeByte((addr & $FF00) >> 8)
            if (ow.readBits(16) >> 8) == inbyte
                return
      
PRI ReadData(addr) | data
  repeat
    if ow.readBits(1)
      ow.reset
      ow.writeByte(ow#SKIP_ROM)
      ow.writeByte(ow#READ_MEMORY)
      ow.writeByte(addr & $00FF)
      ow.writeByte((addr & $FF00) >> 8)
      data := ow.readBits(16)
      debug.Str(string("Data: "))
      debug.hex((data),4)
      debug.NewLine
      return
      
