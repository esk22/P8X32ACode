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
  
VAR
  long addrs[2 * MAX_DEVICES]
  byte Buffer[128]
  
CON

  WATCH_ALL     = false         'Set to TRUE to watch the sentence being built.
  CONTINUOUS    = true          'Set to FALSE to build only one sentence per run.
  DELAY         = 5             'Number of seconds to delay between sentences.
  HEAP_SIZE     = 2000
  WRAP          = $10000

VAR
  long  Seed, Heap_array[HEAP_SIZE]
  word  Rules, Sentence
  word  rule, lft, rgt, wrd, def, option
  byte  Hp
  
PUB start | i, numDevices, addr, Address, data
  Hp := st.start(@heap_array, HEAP_SIZE)
  debug.Start(115_200) 
  ow.start(13)

  repeat i from 0 to 1
    numDevices := ow.search(ow#REQUIRE_CRC, MAX_DEVICES, @addrs)

    'debug.str(string($01, " SpinOneWire Test ", 13, 13, "Devices:"))

    repeat i from 0 to 1 'MAX_DEVICES-1
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
                  'start reading from address 0 to 127
                  'debug.Str(string("Address: "))
                  'debug.Dec(Address)
                  'debug.Str(string("    "))
                  'Call function to read data from EPROM
                  ' 
                  Buffer[Address] := ReadData(Address)
                  debug.Hex(Buffer[Address], 2)
                  
                  
    'waitcnt(80_000_000+CNT)

PRI ReadData(addr) | data, crc, arun, rai
  ow.reset
  ow.writeByte(ow#MATCH_ROM)
  ow.writeAddress(addr)
  repeat
    'waitcnt(clkfreq/100 + cnt)
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
     
      data := ow.readBits(16) >> 8
      'debug.hex(Buffer[addr], 2)
      'debug.Str(string("Data: "))
      'debug.hex((data),2)
      'debug.str(string("  "))
      'crc := ow.crc8(2, 0)
      'debug.Hex((crc), 2)
      'arun := string("Arun is a computer engineering student at virginia tech doing his undergrade")
      'rai := string("rai")
      'bytemove((arun + strsize(arun)), rai, (strsize(rai) + 1))      eb
      'debug.Str(arun)
      debug.NewLine
      return data
