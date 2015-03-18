{{
SpinOneWire-test
----------------
This is a simple example for the SpinOneWire object. Connect up to eight 1-wire
devices to pin 10, a TV output starting at pin 12, and you'll get a real-time
listing of the devices on the bus. If there are any DS18B20 temperature sensors
attached, we'll read their temperature too.
┌───────────────────────────────────┐
│ Copyright (c) 2008 Micah Dtag1ty    │               
│ See end of file for terms of use. │
└───────────────────────────────────┘

Edited by Arun Rai for testing write operation to the DS2502.

}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  FAMILY_DS1820  = 16
  MAX_DEVICES = 8
  
OBJ
  debug   : "Parallax Serial Terminal"      ''  Parallax Serial Terminal 
  tag1      : "SpinOneWire"
  tag2     : "SpinOneWire"
  tag3      : "SpinOneWire"
  tag4      : "SpinOneWire"
  tag5      : "SpinOneWire"
  tag6      : "SpinOneWire"
  
VAR
  long addrs1[2 * MAX_DEVICES]
  long addrs2[2 * MAX_DEVICES]
  long addrs3[2 * MAX_DEVICES]
  long addrs4[2 * MAX_DEVICES]
  long addrs5[2 * MAX_DEVICES]
  long addrs6[2 * MAX_DEVICES]
  
  byte CRC1[4]
  byte CRC2[4]
  byte CRC3[4]
  byte CRC4[4]
  byte CRC5[4]
  byte CRC6[4]
  long Stack1[900]
  
PUB go
  debug.Start(115_200) 
  cognew(WriteTag1(10), @stack1[0])
  cognew(WriteTag2(11), @stack1[150])
  cognew(WriteTag3(12), @stack1[300])
  cognew(WriteTag4(13), @stack1[450])
  cognew(WriteTag5(14), @stack1[600])
  cognew(WriteTag6(15), @stack1[750])
  
PRI WriteTag1(pin_IO) | i, numDevices, addr, Address, x, newStr, inbyte
  tag1.start(pin_IO)
  repeat i from 0 to 1
    numDevices := tag1.search(tag1#REQUIRE_CRC, MAX_DEVICES, @addrs1)
    repeat i from 0 to MAX_DEVICES-1
      if i => numDevices
        debug.char(" ")
      else
        addr := @addrs1 + (i << 3)
        ' Display the 64-bit address        
        debug.Str(string("ID Tag serial number: "))
        debug.hex(LONG[addr + 4], 8)
        debug.hex(LONG[addr], 8)
        debug.str(string("  "))
        debug.NewLine
         if BYTE[addr] == tag1#FAMILY_DS2502
             ' It's a DS2502 ID TAG. Read it.
             debug.Str(string("Reading data from the momeory addressess:"))
             debug.NewLine
             ' IMPORTANT
             'newStr := debug.strJoin(string("0"), string("9"))
             'x := debug.StrToBase(newStr, 16)
             'debug.Dec(x)
             ' inbyte is the data byte to write to the EPROM
             ' This is for test only
             repeat i from 124 to 126
                 inbyte := i
                 ' Write byte at memory location x = 124
                 'WriteData1(i, inbyte)
                 ' Read back byte from memory location x
                 ReadData1(i)
    'waitcnt(80_000_000+CNT)
    
PRI WriteTag2(pin_IO) | i, numDevices, addr, Address, x, newStr, inbyte
  tag2.start(pin_IO)
  repeat i from 0 to 1
    numDevices := tag2.search(tag2#REQUIRE_CRC, MAX_DEVICES, @addrs2)
    repeat i from 0 to MAX_DEVICES-1
      if i => numDevices
        debug.char(" ")
      else
        addr := @addrs2 + (i << 3)
        ' Display the 64-bit address        
        debug.Str(string("ID Tag serial number: "))
        debug.hex(LONG[addr + 4], 8)
        debug.hex(LONG[addr], 8)
        debug.str(string("  "))
        debug.NewLine
         if BYTE[addr] == tag2#FAMILY_DS2502
             ' It's a DS2502 ID TAG. Read it.
             debug.Str(string("Reading data from the momeory addressess:"))
             debug.NewLine
             repeat i from 120 to 122
                 inbyte := i
                 'debug.Str(string("hello"))
                 ' Write byte at memory location x = 124
                 'WriteData2(i, inbyte)
                 ' Read back io from memory location x
                 ReadData2(i)
    'waitcnt(80_000_000+CNT)
    
PRI WriteTag3(pin_IO) | i, numDevices, addr, Address, x, newStr, inbyte
  tag3.start(pin_IO)
  repeat i from 0 to 1
    numDevices := tag3.search(tag3#REQUIRE_CRC, MAX_DEVICES, @addrs3)
    repeat i from 0 to MAX_DEVICES-1
      if i => numDevices
        debug.char(" ")
      else
        addr := @addrs3 + (i << 3)
        ' Display the 64-bit address        
        debug.Str(string("ID Tag serial number: "))
        debug.hex(LONG[addr + 4], 8)
        debug.hex(LONG[addr], 8)
        debug.str(string("  "))
        debug.NewLine
         if BYTE[addr] == tag3#FAMILY_DS2502
             ' It's a DS2502 ID TAG. Read it.
             debug.Str(string("Reading data from the momeory addressess:"))
             debug.NewLine
             repeat i from 120 to 122
                 inbyte := i
                 'debug.Str(string("hello"))
                 ' Write byte at memory location x = 124
                 'WriteData3(i, inbyte)
                 ' Read back io from memory location x
                 ReadData3(i)
    'waitcnt(80_000_000+CNT)
    
PRI WriteTag4(pin_IO) | i, numDevices, addr, Address, x, newStr, inbyte
  tag4.start(pin_IO)
  repeat i from 0 to 1
    numDevices := tag4.search(tag2#REQUIRE_CRC, MAX_DEVICES, @addrs4)
    repeat i from 0 to MAX_DEVICES-1
      if i => numDevices
        debug.char(" ")
      else
        addr := @addrs4 + (i << 3)
        ' Display the 64-bit address        
        debug.Str(string("ID Tag serial number: "))
        debug.hex(LONG[addr + 4], 8)
        debug.hex(LONG[addr], 8)
        debug.str(string("  "))
        debug.NewLine
         if BYTE[addr] == tag4#FAMILY_DS2502
             ' It's a DS2502 ID TAG. Read it.
             debug.Str(string("Reading data from the momeory addressess:"))
             debug.NewLine
             repeat i from 120 to 122
                 inbyte := i
                 'debug.Str(string("hello"))
                 ' Write byte at memory location x = 124
                 'WriteData4(i, inbyte)
                 ' Read back io from memory location x
                 ReadData4(i)
    'waitcnt(80_000_000+CNT)
    
    
PRI WriteTag5(pin_IO) | i, numDevices, addr, Address, x, newStr, inbyte
  tag5.start(pin_IO)
  repeat i from 0 to 1
    numDevices := tag5.search(tag2#REQUIRE_CRC, MAX_DEVICES, @addrs5)
    repeat i from 0 to MAX_DEVICES-1
      if i => numDevices
        debug.char(" ")
      else
        addr := @addrs5 + (i << 3)
        ' Display the 64-bit address        
        debug.Str(string("ID Tag serial number: "))
        debug.hex(LONG[addr + 4], 8)
        debug.hex(LONG[addr], 8)
        debug.str(string("  "))
        debug.NewLine
         if BYTE[addr] == tag5#FAMILY_DS2502
             ' It's a DS2502 ID TAG. Read it.
             debug.Str(string("Reading data from the momeory addressess:"))
             debug.NewLine
             repeat i from 120 to 122
                 inbyte := i
                 'debug.Str(string("hello"))
                 ' Write byte at memory location x = 124
                 'WriteData5(i, inbyte)
                 ' Read back io from memory location x
                 ReadData5(i)
    'waitcnt(80_000_000+CNT)
    
PRI WriteTag6(pin_IO) | i, numDevices, addr, Address, x, newStr, inbyte
  tag6.start(pin_IO)
  repeat i from 0 to 1
    numDevices := tag6.search(tag6#REQUIRE_CRC, MAX_DEVICES, @addrs6)
    repeat i from 0 to MAX_DEVICES-1
      if i => numDevices
        debug.char(" ")
      else
        addr := @addrs6 + (i << 3)
        ' Display the 64-bit address        
        debug.Str(string("ID Tag serial number: "))
        debug.hex(LONG[addr + 4], 8)
        debug.hex(LONG[addr], 8)
        debug.str(string("  "))
        debug.NewLine
         if BYTE[addr] == tag6#FAMILY_DS2502
             ' It's a DS2502 ID TAG. Read it.
             debug.Str(string("Reading data from the momeory addressess:"))
             debug.NewLine
             repeat i from 120 to 122
                 inbyte := i
                 'debug.Str(string("hello"))
                 ' Write byte at memory location x = 124
                 'WriteData6(i, inbyte)
                 ' Read back io from memory location x
                 ReadData6(i)
    'waitcnt(80_000_000+CNT)
    
    
PRI WriteData1(addr, inbyte) | data, temp, d
  repeat
    if tag1.readBits(1)
      repeat
        tag1.reset
        tag1.writeByte(tag1#SKIP_ROM)
        tag1.writeByte(tag1#WRITE_MEMORY)
        tag1.writeByte((addr & $00FF))      ' (TA1=(T7:T0)
        tag1.writeByte((addr & $FF00) >> 8) ' (TA1=(T15:T8)
        tag1.writeByte(inbyte)    
        CRC1[0] := tag1#WRITE_MEMORY
        CRC1[1] := addr & $00FF
        CRC1[2] := (addr & $FF00) >> 8
        CRC1[3] := inbyte
        if(tag1.crc8(4, @CRC1) == tag1.readBits(8))
            tag1.pulse(16)
            tag1.reset
            tag1.writeByte(tag1#SKIP_ROM)
            tag1.writeByte(tag1#READ_MEMORY)
            tag1.writeByte(addr & $00FF)
            tag1.writeByte((addr & $FF00) >> 8)
            if (tag1.readBits(16) >> 8) == inbyte
                return
      
PRI ReadData1(addr) | data
  repeat
    if tag1.readBits(1)
      tag1.reset
      tag1.writeByte(tag1#SKIP_ROM)
      tag1.writeByte(tag1#READ_MEMORY)
      tag1.writeByte(addr & $00FF)
      tag1.writeByte((addr & $FF00) >> 8)
      data := tag1.readBits(16) >> 8
      debug.Str(string("Data1: "))
      debug.hex((data),2)
      debug.NewLine
      return
      
''' Test 2
''

PRI WriteData2(addr, inbyte) | data, temp, d
  repeat
    if tag2.readBits(1)
      repeat
        tag2.reset
        tag2.writeByte(tag2#SKIP_ROM)
        tag2.writeByte(tag2#WRITE_MEMORY)
        tag2.writeByte((addr & $00FF))      ' (TA1=(T7:T0)
        tag2.writeByte((addr & $FF00) >> 8) ' (TA1=(T15:T8)
        tag2.writeByte(inbyte)    
        CRC2[0] := tag2#WRITE_MEMORY
        CRC2[1] := addr & $00FF
        CRC2[2] := (addr & $FF00) >> 8
        CRC2[3] := inbyte
        if(tag2.crc8(4, @CRC2) == tag2.readBits(8))
            tag2.pulse(17)
            tag2.reset
            tag2.writeByte(tag2#SKIP_ROM)
            tag2.writeByte(tag2#READ_MEMORY)
            tag2.writeByte(addr & $00FF)
            tag2.writeByte((addr & $FF00) >> 8)
            if (tag2.readBits(16) >> 8) == inbyte
                return
      
PRI ReadData2(addrr) | data
  repeat
    if tag2.readBits(1)
      tag2.reset
      tag2.writeByte(tag2#SKIP_ROM)
      tag2.writeByte(tag2#READ_MEMORY)
      tag2.writeByte(addrr & $00FF)
      tag2.writeByte((addrr & $FF00) >> 8)
      data := tag2.readBits(16) >> 8
      debug.Str(string("Data2: "))
      debug.hex((data),2)
      debug.NewLine
      return
      
'''''''''''''''''''''''''''''''''''
PRI WriteData3(addr, inbyte) | data, temp, d
  repeat
    if tag3.readBits(1)
      repeat
        tag3.reset
        tag3.writeByte(tag3#SKIP_ROM)
        tag3.writeByte(tag3#WRITE_MEMORY)
        tag3.writeByte((addr & $00FF))      ' (TA1=(T7:T0)
        tag3.writeByte((addr & $FF00) >> 8) ' (TA1=(T15:T8)
        tag3.writeByte(inbyte)    
        CRC3[0] := tag3#WRITE_MEMORY
        CRC3[1] := addr & $00FF
        CRC3[2] := (addr & $FF00) >> 8
        CRC3[3] := inbyte
        if(tag3.crc8(4, @CRC3) == tag3.readBits(8))
            tag3.pulse(18)
            tag3.reset
            tag3.writeByte(tag3#SKIP_ROM)
            tag3.writeByte(tag3#READ_MEMORY)
            tag3.writeByte(addr & $00FF)
            tag3.writeByte((addr & $FF00) >> 8)
            if (tag3.readBits(16) >> 8) == inbyte
                return
      
PRI ReadData3(addrr) | data
  repeat
    if tag3.readBits(1)
      tag3.reset
      tag3.writeByte(tag3#SKIP_ROM)
      tag3.writeByte(tag3#READ_MEMORY)
      tag3.writeByte(addrr & $00FF)
      tag3.writeByte((addrr & $FF00) >> 8)
      data := tag3.readBits(16) >> 8
      debug.Str(string("Data3: "))
      debug.hex((data),2)
      debug.NewLine
      return
      
'''''''''''''''''''''''''''''''''''
PRI WriteData4(addr, inbyte) | data, temp
  repeat
    if tag4.readBits(1)
      repeat
        tag4.reset
        tag4.writeByte(tag4#SKIP_ROM)
        tag4.writeByte(tag4#WRITE_MEMORY)
        tag4.writeByte((addr & $00FF))      ' (TA1=(T7:T0)
        tag4.writeByte((addr & $FF00) >> 8) ' (TA1=(T15:T8)
        tag4.writeByte(inbyte)    
        CRC4[0] := tag4#WRITE_MEMORY
        CRC4[1] := addr & $00FF
        CRC4[2] := (addr & $FF00) >> 8
        CRC4[3] := inbyte
        if(tag4.crc8(4, @CRC4) == tag4.readBits(8))
            tag4.pulse(19)
            tag4.reset
            tag4.writeByte(tag4#SKIP_ROM)
            tag4.writeByte(tag4#READ_MEMORY)
            tag4.writeByte(addr & $00FF)
            tag4.writeByte((addr & $FF00) >> 8)
            if (tag4.readBits(16) >> 8) == inbyte
                return
      
PRI ReadData4(addrr) | data
  repeat
    if tag4.readBits(1)
      tag4.reset
      tag4.writeByte(tag4#SKIP_ROM)
      tag4.writeByte(tag4#READ_MEMORY)
      tag4.writeByte(addrr & $00FF)
      tag4.writeByte((addrr & $FF00) >> 8)
      data := tag4.readBits(16) >> 8
      debug.Str(string("Data4: "))
      debug.hex((data),2)
      debug.NewLine
      return
      
'''''''''''''''''''''''''''''''''''
PRI WriteData5(addr, inbyte) | data, temp
  repeat
    if tag5.readBits(1)
      repeat
        tag5.reset
        tag5.writeByte(tag5#SKIP_ROM)
        tag5.writeByte(tag5#WRITE_MEMORY)
        tag5.writeByte((addr & $00FF))      ' (TA1=(T7:T0)
        tag5.writeByte((addr & $FF00) >> 8) ' (TA1=(T15:T8)
        tag5.writeByte(inbyte)    
        CRC5[0] := tag5#WRITE_MEMORY
        CRC5[1] := addr & $00FF
        CRC5[2] := (addr & $FF00) >> 8
        CRC5[3] := inbyte
        if(tag5.crc8(4, @CRC5) == tag5.readBits(8))
            tag5.pulse(19)
            tag5.reset
            tag5.writeByte(tag5#SKIP_ROM)
            tag5.writeByte(tag5#READ_MEMORY)
            tag5.writeByte(addr & $00FF)
            tag5.writeByte((addr & $FF00) >> 8)
            if (tag5.readBits(16) >> 8) == inbyte
                return
      
PRI ReadData5(addrr) | data
  repeat
    if tag5.readBits(1)
      tag5.reset
      tag5.writeByte(tag5#SKIP_ROM)
      tag5.writeByte(tag5#READ_MEMORY)
      tag5.writeByte(addrr & $00FF)
      tag5.writeByte((addrr & $FF00) >> 8)
      data := tag5.readBits(16) >> 8
      debug.Str(string("Data5: "))
      debug.hex((data),2)
      debug.NewLine
      return
      
'''''''''''''''''''''''''''''''''''
PRI WriteData6(addr, inbyte) | data, temp
  repeat
    if tag6.readBits(1)
      repeat
        tag6.reset
        tag6.writeByte(tag6#SKIP_ROM)
        tag6.writeByte(tag6#WRITE_MEMORY)
        tag6.writeByte((addr & $00FF))      ' (TA1=(T7:T0)
        tag6.writeByte((addr & $FF00) >> 8) ' (TA1=(T15:T8)
        tag6.writeByte(inbyte)    
        CRC6[0] := tag6#WRITE_MEMORY
        CRC6[1] := addr & $00FF
        CRC6[2] := (addr & $FF00) >> 8
        CRC6[3] := inbyte
        if(tag6.crc8(4, @CRC6) == tag6.readBits(8))
            tag6.pulse(19)
            tag6.reset
            tag6.writeByte(tag6#SKIP_ROM)
            tag6.writeByte(tag6#READ_MEMORY)
            tag6.writeByte(addr & $00FF)
            tag6.writeByte((addr & $FF00) >> 8)
            if (tag6.readBits(16) >> 8) == inbyte
                return
      
PRI ReadData6(addrr) | data
  repeat
    if tag6.readBits(1)
      tag6.reset
      tag6.writeByte(tag4#SKIP_ROM)
      tag6.writeByte(tag4#READ_MEMORY)
      tag6.writeByte(addrr & $00FF)
      tag6.writeByte((addrr & $FF00) >> 8)
      data := tag6.readBits(16) >> 8
      debug.Str(string("Data6: "))
      debug.hex((data),2)
      debug.NewLine
      return
      
