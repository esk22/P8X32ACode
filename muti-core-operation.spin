{{
|------------------------------------------------------------------------------------|
|************************************************************************************|
File name               : multi-core-operation.spin
(This file uses objects created by Micah Dowty, and Parallax Inc.)

Project name            : Senior Capstone Design
Project term            : Fall 2014 - Spring 2015
Title                   : Simultaneous Programming of Multiple ID Tags
Sponsor                 : General Electric
Customer name           : Mr. Michael Austin

Instructor              : Prof. Gino manzo
Subject Matter Expert   : Dr. William Plymale
Team name               : BridgeBuilders 
Members                 : Arun Rai, Danny Mota, Mohammad Islam, and Xin Gan
Author                  : Arun Rai
Date                    : 02/20/2015
Reviewed by             : 

Description             : This program allows two way communication between a Graphic-
                          al User (GUI) Interface and the Programmer device. The prog-
                          ram receives a command (read or write) from the GUI, and ex-
                          cutes functions based on the command. When the program recei-
                          eves read command, it reads EPROM contents from all available
                          ID Tags (DS2502), and sends data to the GUI through Serial Port.
                          For writing data into EPROM of specific ID Tag(s), the program
                          receives tag number, starting address and ending address, and 
                          data. The data types are barcode, D.S.R, and catalog number. 
                          Please, refer to the documentation for more detail.
|************************************************************************************|
|------------------------------------------------------------------------------------|
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  MAX_DEVICES   = 1
  ' PIN 10 - 15 will be used for
  ' W/R operation for ID Tags (DS2502)
  PIN10         = 09
  PIN11         = 10
  PIN12         = 11
  PIN13         = 12
  PIN14         = 13
  PIN15         = 14
  
  PIN25         = 24
  PIN26         = 25
  PIN27         = 26
  PIN28         = 27
  PIN29         = 28
  PIN30         = 29
  
OBJ
  tag1      : "SpinOneWire"
  tag2      : "SpinOneWire"
  tag3      : "SpinOneWire"
  tag4      : "SpinOneWire"
  tag5      : "SpinOneWire"
  tag6      : "SpinOneWire"
  system    : "Propeller Board of Education"
  
VAR
  long addrs1[2 * MAX_DEVICES]
  long addrs2[2 * MAX_DEVICES]
  long addrs3[2 * MAX_DEVICES]
  long addrs4[2 * MAX_DEVICES]
  long addrs5[2 * MAX_DEVICES]
  long addrs6[2 * MAX_DEVICES]
  byte c
  ' Allocate stack for multi-core operation
  ' Each COG needs some space for operaton
  long  Stack1[900]
  'long  Stack2[1600]
  ' Data buffer
  long  DataBuffer2[128]
  long  DataBuffer3[128]
  long  DataBuffer4[128]
  long  DataBuffer5[128]
  long  DataBuffer6[128]
  long  DataTag1[128]
  long  DataTag2[128]
  long  DataTag3[128]
  long  DataTag4[128]
  long  DataTag5[128]
  long  DataTag6[128]
  ' Define flags
  long BytesRead[6]
  long BytesWritten[6]
  long BytesReady[6]
  ' Define addresses - one for each COG
  long addr2, addr3, addr4, addr5, addr6
  byte counter1, counter2, counter3, counter4, counter5, counter6
  byte TagNumber
  byte dataStart[6]
  byte CRC1[4]
  
PUB go | a
    SetPGMLineHigh
    ' Intialization of buffers
    system.Clock(80_000_000)
    TagsInit
    repeat 
        InitReadFlags
        InitArray
        '' Read from the serial port
        c := tag1.ReceiveChar
        if (c == "z")
            tag1.SendStr(String("ack"))
            DataReceiveIndicator      
        elseif (c == "r")
            ' Multi-core reading operation
            CogOperation("R") 
        elseif (c == "w")
            tag1.SendStr(String("ack"))
            DataReceiveIndicator     
            TagNumber := 0
            repeat a from 0 to 5
                dataStart[a] := 0
            counter1 := 0
            counter2 := 0
            counter3 := 0
            counter4 := 0
            counter5 := 0
            counter6 := 0
            repeat until c == "q"
                c := tag1.ReceiveChar
                if (c == "q")
                    quit
                elseif (c == "a")
                    TagNumber := 1
                elseif (c == "b")
                    TagNumber := 2
                elseif (c == "c")
                    TagNumber := 3
                elseif (c == "d")
                    TagNumber := 4
                elseif (c == "e")
                    TagNumber := 5
                elseif (c == "f")
                    TagNumber := 6
                    
                if (TagNumber == 1)
                    if (c <> "a")
                        if (c == "s")
                            dataStart[0] := counter1
                        DataTag1[counter1]  := c
                        counter1 := counter1 + 1
                elseif (TagNumber == 2)  
                    if (c <> "b")
                        if (c == "s")
                            dataStart[1] := counter2
                        DataTag2[counter2]  := c
                        counter2 := counter2 + 1
                elseif (TagNumber == 3)
                    if (c <> "c")
                        if (c == "s")
                            dataStart[2] := counter3
                        DataTag3[counter3]  := c
                        counter3 := counter3 + 1
                elseif (TagNumber == 4)
                    if (c <> "d")
                        if (c == "s")
                            dataStart[3] := counter4
                        DataTag4[counter4]  := c
                        counter4 := counter4 + 1
                elseif (TagNumber == 5)
                    if (c <> "e")
                        if (c == "s")
                            dataStart[4] := counter5
                        DataTag5[counter5]  := c
                        counter5 := counter5 + 1
                elseif (TagNumber == 6)
                    if (c <> "f")
                        if (c == "s")
                            dataStart[5] := counter6
                        DataTag6[counter6]  := c
                        counter6 := counter6 + 1
                        
            waitcnt(constant(tag1#USEC_TICKS * 10000) + cnt)
            CogOperation("W")
           
PRI CogOperation(op)
    if (op == "R")     
        cognew(ReadDevice1, @stack1[150])
        cognew(ReadDevice2, @stack1[300])
        cognew(ReadDevice3, @stack1[450])
        cognew(ReadDevice4, @stack1[600])
        cognew(ReadDevice5, @stack1[750])
        cognew(ReadDevice6, @stack1[0])     
    elseif (op == "W")
        'WriteBytesToMemory1(24)
        {
        WriteBytesToMemory1(PIN25)
        WriteBytesToMemory2(PIN26)
        WriteBytesToMemory3(PIN27)
        WriteBytesToMemory4(PIN28)
        WriteBytesToMemory5(PIN29)
        WriteBytesToMemory6(PIN30)
        }        
        TagsInit
        tag1.SendStr(string("ended"))
        
        {
        cognew(WriteBytesToMemory1(24), @stack2[300])
        cognew(WriteBytesToMemory2(25), @stack2[600])
        cognew(WriteBytesToMemory3(26), @stack2[900])
        cognew(WriteBytesToMemory4(27), @stack2[1200])
        cognew(WriteBytesToMemory5(28), @stack2[1500])
        cognew(WriteBytesToMemory6(29), @stack2[0])     
        }        
           
PRI InitArray : a
    repeat a from 0 to 128
        DataBuffer2[a] := 0
        DataBuffer3[a] := 0
        DataBuffer4[a] := 0
        DataBuffer5[a] := 0
        DataBuffer6[a] := 0
            
' Initialize the flags           
PRI InitReadFlags : a
    repeat a from 0 to 6
        BytesRead[a] := 0
        BytesReady[a] := 0
        BytesWritten[a] := 0

' Reading operation - Tag 1 
PRI ReadDevice1 | i, numDevices, addr1, x
    numDevices := tag1.search(tag1#REQUIRE_CRC, MAX_DEVICES, @addrs1)
    repeat i from 0 to MAX_DEVICES
        if i => numDevices
            ' No device found
            BytesRead[0] := 1
            BytesReady[0] := 1
            BytesWritten[0] := 1
        else
            addr1 := @addrs1 + (i << 3)
            if BYTE[addr1] == tag1#FAMILY_DS2502
                SendChipSerialNo(addr1)
                repeat x from 0 to 127 
                    tag1.SendHex(tag1.ReadAddressContent(x), 2)
                tag1.SendStr(String("tag1end"))
                BytesRead[0] := 1
                BytesReady[0] := 1
                    
' Reading operation - Tag 2
PRI ReadDevice2 | i, numDevices, x
    numDevices := tag2.search(tag2#REQUIRE_CRC, MAX_DEVICES, @addrs2)
    repeat i from 0 to MAX_DEVICES
        if i => numDevices
            ' No device found
            BytesReady[1] := 1
            BytesWritten[1] := 1
        else
            addr2 := @addrs2 + (i << 3)
            if BYTE[addr2] == tag2#FAMILY_DS2502
                repeat x from 0 to 127 
                    DataBuffer2[x] := tag2.ReadAddressContent(x)
                BytesRead[1] := 1
                BytesReady[1] := 1

' Reading operation - Tag 3
PRI ReadDevice3 | i, numDevices, x
    numDevices := tag3.search(tag3#REQUIRE_CRC, MAX_DEVICES, @addrs3)
    repeat i from 0 to MAX_DEVICES
        if i => numDevices
            ' No device found
            BytesReady[2] := 1
            BytesWritten[2] := 1
        else
            addr3 := @addrs3 + (i << 3)
            if BYTE[addr3] == tag3#FAMILY_DS2502
                repeat x from 0 to 127 
                    DataBuffer3[x] := tag3.ReadAddressContent(x)
                BytesRead[2] := 1
                BytesReady[2] := 1
                        
' Reading operation - Tag 4  
PRI ReadDevice4 | i, numDevices, x
    numDevices := tag4.search(tag4#REQUIRE_CRC, MAX_DEVICES, @addrs4)
    repeat i from 0 to MAX_DEVICES
        if i => numDevices
            ' No device found
            BytesReady[3] := 1
        else
            addr4 := @addrs4 + (i << 3)
            if BYTE[addr4] == tag4#FAMILY_DS2502
                repeat x from 0 to 127 
                    DataBuffer4[x] := tag4.ReadAddressContent(x)
                BytesRead[3] := 1
                BytesReady[3] := 1
                   
' Reading operation - Tag 5           
PRI ReadDevice5 | i, numDevices, x
    numDevices := tag5.search(tag5#REQUIRE_CRC, MAX_DEVICES, @addrs5)
    repeat i from 0 to MAX_DEVICES
        if i => numDevices
            ' No device found
            BytesReady[4] := 1
        else
            addr5 := @addrs5 + (i << 3)
            if BYTE[addr5] == tag5#FAMILY_DS2502
                repeat x from 0 to 127 
                    DataBuffer5[x] := tag5.ReadAddressContent(x)
                BytesRead[4] := 1
                BytesReady[4] := 1
                   
' Reading operation - Tag 6            
PRI ReadDevice6 | i, numDevices, x
    numDevices := tag6.search(tag6#REQUIRE_CRC, MAX_DEVICES, @addrs6)
    repeat i from 0 to MAX_DEVICES
        if i => numDevices
            ' No device found
            BytesReady[5] := 1
            SendBytes(string("Send bytes - serial"))
        else
            addr6 := @addrs6 + (i << 3)
            if BYTE[addr6] == tag6#FAMILY_DS2502
                repeat x from 0 to 127 
                    DataBuffer6[x] := tag6.ReadAddressContent(x)
                BytesRead[5] := 1
                BytesReady[5] := 1
                ' Call function to write data to the Serial Port
                SendBytes(string("Send bytes - serial"))
            
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
        if BytesRead[0] == 1
            if BytesRead[1] == 1
              SendChipSerialNo(addr2)
              repeat x from 0 to 127
                    tag1.SendHex(DataBuffer2[x], 2)
              tag1.SendStr(string("tag2end"))
              BytesRead[1] := 0
              
            if BytesRead[2] == 1
              SendChipSerialNo(addr3)
              repeat x from 0 to 127
                    tag1.SendHex(DataBuffer3[x], 2)
              tag1.SendStr(string("tag3end"))
              BytesRead[2] := 0
              
            if BytesRead[3] == 1
              SendChipSerialNo(addr4)
              repeat x from 0 to 127
                    tag1.SendHex(DataBuffer4[x], 2)
              tag1.SendStr(string("tag4end"))
              BytesRead[3] := 0
              
            if BytesRead[4] == 1
              SendChipSerialNo(addr5)
              repeat x from 0 to 127
                    tag1.SendHex(DataBuffer5[x], 2)
              tag1.SendStr(string("tag5end"))
              BytesRead[4] := 0
              
            if BytesRead[5] == 1
              SendChipSerialNo(addr6)
              repeat x from 0 to 127
                    tag1.SendHex(DataBuffer6[x], 2)
              tag1.SendStr(string("tag6end"))
              BytesRead[5] := 0
              
            if BytesReady[0] == 1 AND BytesReady[1] == 1 AND BytesReady[2] == 1 
                if BytesReady[3] == 1 AND BytesReady[4] == 1 AND BytesReady[5] == 1
                    tag1.SendStr(string("finished"))
                    return

'' Write data bytes - Tag 1
PRI WriteBytesToMemory1(PGM) : i
    tag1.DataStartPos(dataStart[0])
    tag1.RecordCounter(counter1)
    repeat i from 0 to (counter1 - 1)
        tag1.DataRecord(i, DataTag1[i])
    tag1.WriteBytesToMemory(PGM) 
    return
 
'' Write data bytes - Tag 2                         
PRI WriteBytesToMemory2(PGM) : i
    tag1.start(PIN11)
    tag1.DataStartPos(dataStart[1])
    tag1.RecordCounter(counter2)
    repeat i from 0 to (counter2 - 1)
        tag1.DataRecord(i, DataTag2[i])
    tag1.WriteBytesToMemory(PGM) 
    return
 
'' Write data bytes - Tag 3   
PRI WriteBytesToMemory3(PGM) | i
    tag1.start(PIN12)
    tag1.DataStartPos(dataStart[2])
    tag1.RecordCounter(counter3)
    repeat i from 0 to (counter3 - 1)
        tag1.DataRecord(i, DataTag3[i])
    tag1.WriteBytesToMemory(PGM) 
    return

'' Write data bytes - Tag 4    
PRI WriteBytesToMemory4(PGM) | i
    tag1.start(PIN13)
    tag1.DataStartPos(dataStart[3])
    tag1.RecordCounter(counter4)
    repeat i from 0 to (counter4 - 1)
        tag1.DataRecord(i, DataTag4[i])
    tag1.WriteBytesToMemory(PGM) 
    return

'' Write data bytes - Tag 5    
PRI WriteBytesToMemory5(PGM) | i
    tag1.start(PIN14)
    tag1.DataStartPos(dataStart[4])
    tag1.RecordCounter(counter5)
    repeat i from 0 to (counter5 - 1)
        tag1.DataRecord(i, DataTag5[i])
    tag1.WriteBytesToMemory(PGM) 
    return

'' Write data bytes - Tag 6
PRI WriteBytesToMemory6(PGM) | i
    tag1.start(PIN15)
    tag1.DataStartPos(dataStart[5])
    tag1.RecordCounter(counter6)
    repeat i from 0 to (counter6 - 1)
        tag1.DataRecord(i, DataTag6[i])
    tag1.WriteBytesToMemory(PGM) 
    return

'' Turn on LEDs P16 when data/command
'' is received through the Serial Port  
'' This function may not be required later.   
PRI DataReceiveIndicator
    dira[16] := 1
    outa[16] := 1
    waitcnt(clkfreq + cnt)
    outa[16] := 0      

'' Send the Serial Number of an ID Tag  to the 
'' GUI through the Serial Port. 
'' This ID Tag Serial Number is read from the ROM
PRI SendChipSerialNo(address)
    tag1.SendHex(LONG[address + 4], 8)
    tag1.SendHex(LONG[address], 8)
    tag1.SendStr(string(" "))

'' Set the programming lines high
'' The driver circuit is active low circuit. The circuit
'' provides a 12V pulse to an ID Tag when the PGM line is low.
PRI SetPGMLineHigh
    dira[24]~~
    outa[24] := 1
    dira[25]~~
    outa[25] := 1
    dira[26]~~
    outa[26] := 1
    dira[27]~~
    outa[27] := 1
    dira[28]~~
    outa[28] := 1
    dira[29]~~
    outa[29] := 1

'' Initial PIN configuration for R/W operations              
PRI TagsInit
    tag1.start(PIN10)
    tag2.start(PIN11)
    tag3.start(PIN12)
    tag4.start(PIN13)
    tag5.start(PIN14)
    tag6.start(PIN15)
    tag1.ReadAddressContent(0)
    tag2.ReadAddressContent(0)
    tag3.ReadAddressContent(0)
    tag4.ReadAddressContent(0)
    tag5.ReadAddressContent(0)
    tag6.ReadAddressContent(0)
