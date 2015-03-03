{{

┌───────────────────────────────────┐
│ Copyright (c) 2008 Micah Dtag1ty    │               
│ See end of file for terms of use. │
└───────────────────────────────────┘

multi-core-operation

GE - Simultaneous Programming of Multiple ID Tags
BridgeBuilders Group
Modified by Arun Rai - 02/20/2015
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  MAX_DEVICES   = 1
  ' PIN 10 - 15 will be used for
  ' W/R operation for ID Tags (DS2502)
  PIN10         = 10
  PIN11         = 11
  PIN12         = 12
  PIN13         = 13
  PIN14         = 14
  PIN15         = 15
  
OBJ
  debug     : "Parallax Serial Terminal"      ''  Parallax Serial Terminal 
  tag1      : "SpinOneWire"
  tag2      : "SpinOneWire"
  tag3      : "SpinOneWire"
  tag4      : "SpinOneWire"
  tag5      : "SpinOneWire"
  tag6      : "SpinOneWire"
  f         : "FloatMath"
  fp        : "FloatString"
  PORT      : "Parallax Serial Terminal Plus"
  system    : "Propeller Board of Education"
  
VAR
  long addrs1[2 * MAX_DEVICES]
  long addrs2[2 * MAX_DEVICES]
  long addrs3[2 * MAX_DEVICES]
  long addrs4[2 * MAX_DEVICES]
  long addrs5[2 * MAX_DEVICES]
  long addrs6[2 * MAX_DEVICES]
  byte c
  ' Define stacks for multi-core operation
  ' Each COG needs space allocated for operaton
  long  Stack1[900]
  long  Stack2[700]
  long  DataBuffer2[128]
  long  DataBuffer3[128]
  long  DataBuffer4[128]
  long  DataBuffer5[128]
  long  DataBuffer6[128]
  ' Define flags
  long ReadingDone[6]
  long ToSerialFlag[6]
  ' Define addresses - one for each COG
  long addr2, addr3, addr4, addr5, addr6
  
  
PUB go | a
    ' Intialization of buffers
    repeat a from 0 to 128
        DataBuffer2[a] := 0
        DataBuffer3[a] := 0
        DataBuffer4[a] := 0
        DataBuffer5[a] := 0
        DataBuffer6[a] := 0
    
    '' Configure pin 16 as output
    dira[16] := 1
    '' Configure pin 17 as output
    dira[17] := 1
    system.Clock(80_000_000)
    PORT.StartRxTx(31, 30, 0, 115_200)
    repeat 
        FlagInitialization
        '' Read from the serial port
        c := PORT.CharIn
        if (c == "z")
            PORT.Str(String("ack"))
            outa[16] := 1
            waitcnt(clkfreq + cnt)
            outa[16] := 0      
        elseif (c == "r")
            ' Multi-core reading operation
            cognew(OneWireDevice1(PIN10), @stack1[150])
            cognew(OneWireDevice2(PIN11), @stack1[300])
            cognew(OneWireDevice3(PIN12), @stack1[450])
            cognew(OneWireDevice4(PIN13), @stack1[600])
            cognew(OneWireDevice5(PIN14), @stack1[750])
            cognew(OneWireDevice6(PIN15), @stack1[0])
 
' Initialize the flags           
PRI FlagInitialization : a
    repeat a from 0 to 6
        ReadingDone[a] := 0
        ToSerialFlag[a] := 0

' Reading operation - Tag 1 
PRI OneWireDevice1(PIN) | i, numDevices, addr1, x
    tag1.start(PIN)
    numDevices := tag1.search(tag1#REQUIRE_CRC, MAX_DEVICES, @addrs1)
    repeat i from 0 to MAX_DEVICES
      if i => numDevices
        ' No device found
        ReadingDone[0] := 1
        ToSerialFlag[0] := 1
      else
        addr1 := @addrs1 + (i << 3)
         if BYTE[addr1] == tag1#FAMILY_DS2502
            ' It's a DS2502 ID TAG. Read it.
            PORT.hex(LONG[addr1 + 4], 8)
            PORT.hex(LONG[addr1], 8)
            PORT.str(string(" "))
            repeat x from 0 to 127 
                PORT.Hex(ReadDevice1(x), 2)
            PORT.Str(String("tag1end"))
            ReadingDone[0] := 1
            ToSerialFlag[0] := 1

' Reading operation - Tag 2
PRI OneWireDevice2(PIN) | i, numDevices, x
    tag2.start(PIN)
    numDevices := tag2.search(tag2#REQUIRE_CRC, MAX_DEVICES, @addrs2)
    repeat i from 0 to MAX_DEVICES
      ''debug.char(13)
      if i => numDevices
        ' No device found
        ToSerialFlag[1] := 1
      else
        addr2 := @addrs2 + (i << 3)
         if BYTE[addr2] == tag2#FAMILY_DS2502
            ' It's a DS2502 ID TAG. Read it.
            repeat x from 0 to 127 
                'DataBuffer2[x] := ReadDevice2(x)
            ReadingDone[1] := 1
            ToSerialFlag[1] := 1

' Reading operation - Tag 3
PRI OneWireDevice3(PIN) | i, numDevices, x
    tag3.start(PIN)
    numDevices := tag3.search(tag3#REQUIRE_CRC, MAX_DEVICES, @addrs3)
    repeat i from 0 to MAX_DEVICES
      ''debug.char(13)
      if i => numDevices
        ' No device found
        ToSerialFlag[2] := 1
      else
        addr3 := @addrs3 + (i << 3)
         if BYTE[addr3] == tag3#FAMILY_DS2502
            ' It's a DS2502 ID TAG. Read it.
            repeat x from 0 to 127 
                DataBuffer3[x] := ReadDevice3(x)
            ReadingDone[2] := 1
            ToSerialFlag[2] := 1
          
' Reading operation - Tag 4  
PRI OneWireDevice4(PIN) | i, numDevices, x
    tag4.start(PIN)
    numDevices := tag4.search(tag4#REQUIRE_CRC, MAX_DEVICES, @addrs4)
    repeat i from 0 to MAX_DEVICES
      ''debug.char(13)
      if i => numDevices
        ' No device found
        ToSerialFlag[3] := 1
      else
        addr4 := @addrs4 + (i << 3)
         if BYTE[addr4] == tag4#FAMILY_DS2502
            ' It's a DS2502 ID TAG. Read it.
            repeat x from 0 to 127 
                DataBuffer4[x] := ReadDevice4(x)
            ReadingDone[3] := 1
            ToSerialFlag[3] := 1
 
' Reading operation - Tag 5           
PRI OneWireDevice5(PIN) | i, numDevices, x
    tag5.start(PIN)
    numDevices := tag5.search(tag5#REQUIRE_CRC, MAX_DEVICES, @addrs5)
    repeat i from 0 to MAX_DEVICES
      ''debug.char(13)
      if i => numDevices
        ' No device found
        ToserialFlag[4] := 1
      else
        addr5 := @addrs5 + (i << 3)
         if BYTE[addr5] == tag5#FAMILY_DS2502
            ' It's a DS2502 ID TAG. Read it.
            repeat x from 0 to 127 
                DataBuffer5[x] := ReadDevice5(x)
            ReadingDone[4] := 1
            ToSerialFlag[4] := 1

' Reading operation - Tag 6            
PRI OneWireDevice6(PIN) | i, numDevices, x
    tag6.start(PIN)
    numDevices := tag6.search(tag6#REQUIRE_CRC, MAX_DEVICES, @addrs6)
    repeat i from 0 to MAX_DEVICES
      ''debug.char(13)
      if i => numDevices
        ' No device found
        ToSerialFlag[5] := 1
        SendBytes(string("Send bytes - serial"))
      else
        addr6 := @addrs6 + (i << 3)
         if BYTE[addr6] == tag6#FAMILY_DS2502
            ' It's a DS2502 ID TAG. Read it.
            repeat x from 0 to 127 
                DataBuffer6[x] := ReadDevice6(x)
            ReadingDone[5] := 1
            ToSerialFlag[5] := 1
            ' Call function to write data to the Serial Port
            SendBytes(string("Send bytes - serial"))
            

PRI ReadDevice1(a)
  tag1.reset
  repeat
    'waitcnt(clkfreq/100 + cnt)
    if tag1.readBits(1)
      tag1.reset
      tag1.writeByte(tag1#SKIP_ROM)
      tag1.writeByte(tag1#READ_MEMORY)
      tag1.writeByte(a)
      tag1.writeByte(0)
      return (tag1.readBits(16) >> 8)
                      
PRI ReadDevice2(a) 
  tag2.reset
  repeat
    if tag2.readBits(1)
      tag2.reset
      tag2.writeByte(tag2#SKIP_ROM)
      tag2.writeByte(tag2#READ_MEMORY)
      tag2.writeByte(a)
      tag2.writeByte(0)
      return (tag2.readBits(16) >> 8)
     
PRI ReadDevice3(a) 
  tag3.reset
  repeat
    if tag3.readBits(1)
      tag3.reset
      tag3.writeByte(tag3#SKIP_ROM)
      tag3.writeByte(tag3#READ_MEMORY)
      tag3.writeByte(a)
      tag3.writeByte(0)
      return (tag3.readBits(16) >> 8)
      
PRI ReadDevice4(a) 
  tag4.reset
  repeat
    if tag4.readBits(1)
      tag4.reset
      tag4.writeByte(tag4#SKIP_ROM)
      tag4.writeByte(tag4#READ_MEMORY)
      tag4.writeByte(a)
      tag4.writeByte(0)
      return (tag4.readBits(16) >> 8)
      
PRI ReadDevice5(a) 
  tag5.reset
  repeat
    if tag5.readBits(1)
      tag5.reset
      tag5.writeByte(tag5#SKIP_ROM)
      tag5.writeByte(tag5#READ_MEMORY)
      tag5.writeByte(a)
      tag5.writeByte(0)
      return (tag5.readBits(16) >> 8)
      
PRI ReadDevice6(a) 
  tag6.reset
  repeat
    if tag6.readBits(1)
      tag6.reset
      tag6.writeByte(tag6#SKIP_ROM)
      tag6.writeByte(tag6#READ_MEMORY)
      tag6.writeByte(a)
      tag6.writeByte(0)
      return (tag6.readBits(16) >> 8)
      
' This function is called after COG6 finishes AddDigits
' reading operation. The function checks if other COGS have
' also finished reading operation. If, so it starts to write
' data to the Serial port from the buffers. It randomly checks 
' which COG has finished its task, and starts to write data to the
' Serial Port from whichever COG it finds has finisehd the task.
' Returns when all data from the buffers are completely written to the
' Serial Port.
' - The last string to be written to the Serial Port is "finished"
'   indicating that all data are written to the Port.
PRI SendBytes(bytes) | x
    repeat 
        if ReadingDone[0] == 1
            if ReadingDone[1] == 1
              PORT.hex(LONG[addr2 + 4], 8)
              PORT.hex(LONG[addr2], 8)
              PORT.str(string(" "))
              repeat x from 0 to 127
                    PORT.Hex(DataBuffer2[x], 2)
              PORT.Str(string("tag2end"))
              ReadingDone[1] := 0
              
            if ReadingDone[2] == 1
              PORT.hex(LONG[addr3 + 4], 8)
              PORT.hex(LONG[addr3], 8)
              PORT.str(string(" "))
              repeat x from 0 to 127
                    PORT.Hex(DataBuffer3[x], 2)
              PORT.Str(string("tag3end"))
              ReadingDone[2] := 0
              
            if ReadingDone[3] == 1
              PORT.hex(LONG[addr4 + 4], 8)
              PORT.hex(LONG[addr4], 8)
              PORT.str(string(" "))
              repeat x from 0 to 127
                    PORT.Hex(DataBuffer4[x], 2)
              PORT.Str(string("tag4end"))
              ReadingDone[3] := 0
              
            if ReadingDone[4] == 1
              PORT.hex(LONG[addr5 + 4], 8)
              PORT.hex(LONG[addr5], 8)
              PORT.str(string(" "))
              repeat x from 0 to 127
                    PORT.Hex(DataBuffer5[x], 2)
              PORT.Str(string("tag5end"))
              ReadingDone[4] := 0
              
            if ReadingDone[5] == 1
              PORT.hex(LONG[addr6 + 4], 8)
              PORT.hex(LONG[addr6], 8)
              PORT.str(string(" "))
              repeat x from 0 to 127
                    PORT.Hex(DataBuffer6[x], 2)
              PORT.Str(string("tag6end"))
              ReadingDone[5] := 0
              
            if ToSerialFlag[0] == 1 AND ToSerialFlag[1] == 1 AND ToSerialFlag[2] == 1 
                if ToSerialFlag[3] == 1 AND ToSerialFlag[4] == 1 AND ToSerialFlag[5] == 1
                    PORT.Str(string("finished"))
                    return
    
