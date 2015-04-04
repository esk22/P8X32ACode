 {{

SpinOneWire
-----------

This object is a Spin-only implementation of a Dallas/Maxim 1-wire bus master.

It should be a drop-in replacement for Cam Thompson's OneWire object.
This object does not require a separate cog, but it sacrifices
speed and timing accuracy to accomplish this. This object requires an
80 MHz clock.

┌───────────────────────────────────┐
│ Copyright (c) 2008 Micah Dowty    │               
│ See end of file for terms of use. │
└───────────────────────────────────┘

Edited by Arun Rai for Senior Design project
Senior Design Capstonne - (Fall 2014 - Spring 2015) - Virginia Tech
Date: 03/01/2015
Added additional function implementations for R/W operations on DS2502
Reviewed by: 

}}

CON
  ' Required clock frequency.
  CONST_CLKFREQ = 80_000_000

  ' Ticks per microsecond. We require an 80 MHz clock.
  USEC_TICKS = CONST_CLKFREQ / 1_000_000

  ' 1-wire commands
  SEARCH_ROM         = $F0
  READ_MEMORY        = $F0
  WRITE_MEMORY       = $0F
  READ_ROM           = $33
  READ_STATUS        = $AA
  MATCH_ROM          = $55
  WRITE_STATUS       = $55
  SKIP_ROM           = $CC
  ALARM_SEARCH       = $EC
  READ_SCRATCHPAD    = $BE
  CONVERT_T          = $44
  COPY_SCRATCHPAD    = $48
  RECALL_EE          = $B8
  READ_POWER_SUPPLY  = $B4

  ' 1-wire family codes
  FAMILY_DS2502     = $09

  ' Search flags
  REQUIRE_CRC       = $100

OBJ
  'debug     : "Parallax Serial Terminal"      ''  Parallax Serial Terminal 
  system    : "Propeller Board of Education"
  PORT      : "Parallax Serial Terminal Plus"
                                              
VAR
  long pin
  byte write_crc1[4]
  byte write_crc2[4]
  byte write_crc3[4]
  byte write_crc4[4]
  byte write_crc5[4]
  byte write_crc6[4]
  long data[128]
  long DataTag[128]
  long WriteData
  byte counter
  byte dataStart
  byte READ_CRC[3]
  
PUB start(dataPin) : okay
  '' Initialize, using the provided data pin. Does not allocate a cog.
  '' For compatibility with OneWire.spin, always returns success.

  pin := dataPin
  outa[pin]~
  dira[pin]~
  okay~

'' Main function
PUB go
    PORT.StartRxTx(31, 30, 0, 115_200)
  
'' Write a hex of size to the Serial Port     
PUB SendHex(val, size)
    PORT.Hex(val , size)

'' Write a string to the Serial Port     
PUB SendStr(str)
    PORT.Str(str)

'' Write a character to the Serial Port 
PUB SendChar(chr)
    PORT.Char(chr)

'' Write a decimal value to the Serial Port 
PUB SendDec(dec)
    PORT.Dec(dec)

'' A new line    
PUB SetNewLine
    PORT.NewLine
    
'' Receive a character from the Serial Port
PUB ReceiveChar
    return PORT.CharIn

'' Starting EPROM address where
'' data bytes should be written from   
PUB DataStartPos(pos)  
    dataStart := pos

'' Record the number of data bytes
''to be written into EPROM
PUB RecordCounter(count)
    counter := count
    
'' Store data bytes in buffer
PUB DataRecord(pos, value)
    DataTag[pos] := value
    
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

'' Read a byte from an EPROM address
PUB ReadAddressContent(addr) : read_counter
  reset
  read_counter := 0
  repeat
    if read_counter == 20
        return 0
    read_counter++
    if readBits(1)
      reset
      writeByte(SKIP_ROM)
      writeByte(READ_MEMORY)
      writeByte(addr & $00FF)
      writeByte((addr & $FF00) >> 8)
      return (readBits(16) >> 8)
 
'' Write a byte to an EPROM address       
PUB ByteToMemory(address, inbyte, PGM, tag) : loop_counter | crc, error_count
    crc := computeCRC(address, inbyte, tag)
    error_count:= 0
    loop_counter := 0
    repeat
        if readBits(1)
          repeat
            reset
            writeByte(SKIP_ROM)
            writeByte(WRITE_MEMORY)
            writeByte(address & $00FF)        ' (TA1=(T7:T0)
            writeByte((address & $FF00) >> 8) ' (TA1=(T15:T8)
            writeByte(inbyte)    
            'if Writing fails
            ' 50 is an arbitrary number
            ' Expecation is that the writing operation should
            ' not exceed 50 resets
            if(crc == readBits(8))
                outa[PGM] := 0
                ' a programming pulse of 480 us 
                waitcnt(constant(USEC_TICKS * 480) + cnt)
                outa[PGM] := 1
                if (loop_counter == 50)
                    return
                loop_counter++
                if ReadAddressContent(address) == inbyte
                    return
        else
            if (error_count == 50)
                return
            error_count := error_count + 1
            
'' Specify tag number to compute the crc value
'' for the tag 
'' required for simultaneous operation only
PRI computeCRC(addr, data_byte, tag)
    if tag == 1
        write_crc1[0] := WRITE_MEMORY
        write_crc1[1] := addr & $00FF
        write_crc1[2] := (addr & $FF00) >> 8
        write_crc1[3] := data_byte
        return (crc8(4, @write_crc1))
    elseif tag == 2
        write_crc2[0] := WRITE_MEMORY
        write_crc2[1] := addr & $00FF
        write_crc2[2] := (addr & $FF00) >> 8
        write_crc2[3] := data_byte
        return (crc8(4, @write_crc2))
    elseif tag == 3
        write_crc3[0] := WRITE_MEMORY
        write_crc3[1] := addr & $00FF
        write_crc3[2] := (addr & $FF00) >> 8
        write_crc3[3] := data_byte
        return (crc8(4, @write_crc3))
    elseif tag == 4
        write_crc4[0] := WRITE_MEMORY
        write_crc4[1] := addr & $00FF
        write_crc4[2] := (addr & $FF00) >> 8
        write_crc4[3] := data_byte
        return (crc8(4, @write_crc4))
    elseif tag == 5
        write_crc5[0] := WRITE_MEMORY
        write_crc5[1] := addr & $00FF
        write_crc5[2] := (addr & $FF00) >> 8
        write_crc5[3] := data_byte
        return (crc8(4, @write_crc5))
    elseif tag == 6
        write_crc6[0] := WRITE_MEMORY
        write_crc6[1] := addr & $00FF
        write_crc6[2] := (addr & $FF00) >> 8
        write_crc6[3] := data_byte
        return (crc8(4, @write_crc6))
    else
        return 0

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

PUB strJoin(str1, str2) '' 5 Stack Longs
  bytemove((str1 + strsize(str1)), str2, (strsize(str2) + 1))
  return str1

PUB StrToBase(stringptr, base) : value | chr, index
{Converts a zero terminated string representation of a number to a value in the designated base.
Ignores all non-digit characters (except negative (-) when base is decimal (10)).}

  value := index := 0
  repeat until ((chr := byte[stringptr][index++]) == 0)
    chr := -15 + --chr & %11011111 + 39*(chr > 56)                              'Make "0"-"9","A"-"F","a"-"f" be 0 - 15, others out of range     
    if (chr > -1) and (chr < base)                                              'Accumulate valid values into result; ignore others
      value := value * base + chr                                                  
  if (base == 10) and (byte[stringptr] == "-")                                  'If decimal, address negative sign; ignore otherwise
    value := - value
      
PUB WriteBytesToMemory(PGM, tag) | a, erase_start, erase_end, write_start, write_end, i, data_value
    i := 0
    ReadAddressContent(0) ' Reading/Writing initiation
    if (DataTag[counter - 1] == "j")
        erase_end := StrToBase(strJoin(@DataTag[dataStart+3], @DataTag[dataStart+4]), 16)
        write_start := WriteStartAddress(erase_end + 1)
        ' No erasing data required in this case
        PORT.Str(string("Tag Number: <> "))
        PORT.Dec(tag)
        PORT.Str(string(" <> "))
        PORT.Str(string("Start Address <> "))
        PORT.Hex(write_start, 2)
        PORT.Str(string(" <> DATA <> "))
        repeat a from (dataStart + 5) to (counter - 2)
            if (i < 2)
                i := i + 1
            if (i == 2)
                'add data to eprom
                WriteData := StrToBase(strJoin(@DataTag[a-1],@DataTag[a]), 16)
                PORT.Hex(WriteData, 2)
                if(ReadAddressContent(write_start) == $FF)
                    ByteToMemory(write_start, WriteData, PGM, 1)
                write_start := write_start + 1
                i := 0
        PORT.Str(string(" <> DATA -- End Address <> "))
        PORT.Hex(write_start - 1, 2)
        PORT.Str(string(" <> //// "))
        return
    else
        if ((counter - 1) == dataStart)
            PORT.Str(string("Tag Number: <> "))
            PORT.Dec(tag)
            PORT.Str(string(" <> "))
            EraseBytes(dataStart, erase_start, erase_end, PGM)
        elseif ((counter - 1) > dataStart)
            erase_start := StrToBase(strJoin(@DataTag[dataStart+1], @DataTag[dataStart+2]), 16)
            erase_end := StrToBase(strJoin(@DataTag[dataStart+3], @DataTag[dataStart+4]), 16)
            if (erase_end > 0)
                write_start := WriteStartAddress(erase_end + 1)
                if (erase_end > 0 and (erase_end > erase_start)) 'erase_start >= 0 and
                    'erase data
                    PORT.Str(string("Tag Number: <> "))
                    PORT.Dec(tag)
                    PORT.Str(string(" <> "))
                    PORT.Str(string(" Erase bytes -- Start Address <> "))
                    PORT.Hex(erase_start, 2)
                    PORT.Str(string(" End Address <> "))
                    PORT.Hex(erase_end, 2)
                    PORT.Str(string(" <> //// "))
                    repeat a from erase_start to (erase_end)
                        data_value := ReadAddressContent(a)
                        if(data_value > $FF and data_value < $00)
                            ByteToMemory(a, 0, PGM, 1)
            else
                write_start := 0
            write_end := (counter - dataStart - 5)/2 - 1
            PORT.Str(string("Tag Number: <> "))
            PORT.Dec(tag)
            PORT.Str(string(" <> "))
            EraseBytes(dataStart, erase_start, erase_end, PGM)
            'PORT.Dec((counter - dataStart - 5)/2 - 1)
            PORT.Str(string(" Write Start address <> "))
            PORT.Hex(write_start, 2)
            PORT.Str(string(" <> DATA <> "))
            
            ReadAddressContent(0) 
            repeat a from (dataStart + 5) to (counter - 1)
                if (i < 2)
                    i := i + 1
                if (i == 2)
                    WriteData := StrToBase(strJoin(@DataTag[a-1],@DataTag[a]), 16)
                    PORT.Hex(WriteData, 2)
                    ByteToMemory(write_start, WriteData, PGM, 1)
                    write_start := write_start + 1
                    i := 0 
            PORT.Str(string(" <> DATA <> "))    
            PORT.Str(string(" Write End address <> "))
            PORT.Hex(write_start - 1, 2)
            PORT.Str(string(" <> <> //// "))      
        return

PRI WriteStartAddress(start_address) : a
    if(ReadAddressContent(start_address) <> $FF)
        repeat a from start_address to 127
            if(ReadAddressContent(a) == $FF)
                start_address := a
                quit
    return start_address
       
PRI EraseBytes(dataStartsAt, startEraseAt, endEraseAt, pulse) | a, i, data_value, m
    repeat a from 0 to dataStartsAt
        if (DataTag[a] == "x" or DataTag[a] == "y")
            startEraseAt := StrToBase(strJoin(@DataTag[a+1], @DataTag[a+2]), 16)
            endEraseAt := StrToBase(strJoin(@DataTag[a+3], @DataTag[a+4]), 16)
            if DataTag[a] == "x"
                PORT.Str(string(" Erase Barcode -- Start Address <> "))
            elseif DataTag[a] == "y"
                PORT.Str(string(" Erase DSR -- Start Address <> "))
            PORT.Hex(startEraseAt, 2)
            PORT.Str(string(" <> End Address <> "))
            PORT.Hex(startEraseAt + endEraseAt, 2)
            PORT.Str(string(" <> <> //// "))
            repeat i from startEraseAt to (startEraseAt + endEraseAt)
                'Erase data
                data_value := ReadAddressContent(i)
                if(data_value > $FF and data_value > $00)
                    ByteToMemory(i, 0, pulse, 1)
        elseif (DataTag[a] == "z")
            startEraseAt := StrToBase(strJoin(@DataTag[a+1], @DataTag[a+2]), 16)
            i := startEraseAt
            PORT.Str(string(" Erase Catalog no -- Start Address <> "))
            PORT.Hex(startEraseAt, 2)
            data := ReadAddressContent(i)
            repeat a from i to 127
                READ_CRC[1] := 0
                READ_CRC[2] := 0
                data_value := ReadAddressContent(a)
                if (data_value == $FF)
                    m := a - 1
                    quit
                'Erase data
                elseif(data_value < $FF and data_value > $00)
                    ByteToMemory(a, 0, pulse, 1)
            PORT.Str(string(" <> End Address <> "))
            PORT.Hex(m, 2)
            PORT.Str(string(" <> <> //// "))
                       
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
