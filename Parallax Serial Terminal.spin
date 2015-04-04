{{Parallax Serial Terminal Plus.spin

This object is made for direct use with the
Parallax Serial Terminal; a simple serial
communication program available with the
Propeller Tool installer and also separately
via the Parallax website (www.parallax.com).

See end of file for author, version,
copyright and terms of use.

This object launches a cog for 2-way,
high speed communication with Parallax
Serial Terminal software that you can run
on your PC.  It launches as soon as you call
one of its methods, with settings that match
the Parallax Serial Terminal's defaults.

You can also call the Start Method for
a different baud rate, or StartRxTx for
custom configurations.

Examples in each method's documentation
assume that this object was declared in a
program and nicknamed pst, with the system
clock set to run at 80 MHz using the
Propeller Board of Education's 5 MHz
crystal oscillator.  Like this:

Example Program with pst Nickname
┌──────────────────────────────────────────┐
│''Hello message to Parallax Serial        │
│''Terminal                                │
│OJB                                       │
│ pst : "Parallax Serial Terminal Plus"    │
│ system: "Propeller Board of Education"   │
│                                          │
│PUB Go                                    │
│ system.Clock(80_000_000)  '80 Mhz clock  │
│ pst.Str(string("Hello!")) 'Message to PST│
└──────────────────────────────────────────┘

IMPORTANT: Make sure to click the Parallax 
           Serial Terminal's Enable button,
           either while the program is 
           loading or within 1 second    
           afterwards.  Otherwise, you will
           miss the message.

BUGS       Please send bug reports, questions, 
&          suggestions, and improved versions 
UPDATES    of this object to alindsay@parallax.com.
           Also, check learn.parallax.com
           periodically for updated versions.
           
}}

  
CON
''
''     Parallax Serial Terminal
''    Control Character Constants
''─────────────────────────────────────
  CS = 16  ''CS: Clear Screen      
  CE = 11  ''CE: Clear to End of line     
  CB = 12  ''CB: Clear lines Below 

  HM =  1  ''HM: HoMe cursor       
  PC =  2  ''PC: Position Cursor in x,y          
  PX = 14  ''PX: Position cursor in X         
  PY = 15  ''PY: Position cursor in Y         

  NL = 13  ''NL: New Line        
  LF = 10  ''LF: Line Feed       
  ML =  3  ''ML: Move cursor Left          
  MR =  4  ''MR: Move cursor Right         
  MU =  5  ''MU: Move cursor Up          
  MD =  6  ''MD: Move cursor Down
  TB =  9  ''TB: TaB          
  BS =  8  ''BS: BackSpace          
           
  BP =  7  ''BP: BeeP speaker          

CON

   BUFFER_LENGTH = 64                                   'Recommended as 64 or higher, but can be 2, 4, 8, 16, 32, 64, 128 or 256.
   BUFFER_MASK   = BUFFER_LENGTH - 1
   MAXSTR_LENGTH = 49                                   'Maximum length of received numerical string (not including zero terminator).

VAR

  long  cog                                             'Cog flag/id

  long  rx_head                                         '9 contiguous longs (must keep order)
  long  rx_tail
  long  tx_head
  long  tx_tail
  long  rx_pin
  long  tx_pin
  long  rxtx_mode
  long  bit_ticks
  long  buffer_ptr
                     
  byte  rx_buffer[BUFFER_LENGTH]                        'Receive and transmit buffers
  byte  tx_buffer[BUFFER_LENGTH]

  byte  str_buffer[MAXSTR_LENGTH+1]                     'String buffer for numerical strings

PUB Start(baudrate) : okay
{{Start communication with the Parallax
Serial Terminal using the Propeller's
programming connection.
Waits 1 second for connection, then clears
screen.

IMPORTANT: You do not need to call this
method if you just want to send messages
to the Parallax Serial Terminal at its
default baudrate of 115.2 kbps.  Any
method call will call this start method
with the default baud rate if it has not
already been called.

Parameters:
  baudrate - bits per second.  Make sure it
  matches the Parallax Serial Terminal's
  Baud Rate field.

Returns:
  True (non-zero) if cog started
  False (0) if no cog is available.

Example:
  'Start communication with the
  'Parallax Serial Terminal at a baud
  'rate of 115.2 kbps.

  pst.Start(115_2000)  
}}

  okay := StartRxTx(31, 30, 0, baudrate)
  waitcnt(clkfreq + cnt)                                'Wait 1 second for PST
  Clear                                                 'Clear display

PUB StartRxTx(rxpin, txpin, mode, baudrate) : okay
{{Start serial communication with designated
pins, mode, and baud.

Parameters:
  rxpin    - input pin; receives signals
             from external device's TX pin.
  txpin    - output pin; sends signals to
             external device's RX pin.
  mode     - signaling mode (4-bit pattern).
             bit 0 - inverts rx.
             bit 1 - inverts tx.
             bit 2 - open drain/source tx.
             bit 3 - ignore tx echo on rx.
  baudrate - bits per second.

Returns:
  True (non-zero) if cog started
  False (0) if no cog is available.

Example:
  'Start communication with the
  'Parallax Serial Terminal at a baud
  'rate of 115.2 kbps using the serial
  'programming and communication pins.

  pst.StartRxTx(31,30,0,115_200)
}}

  stop
  longfill(@rx_head, 0, 4)
  longmove(@rx_pin, @rxpin, 3)
  bit_ticks := clkfreq / baudrate
  buffer_ptr := @rx_buffer
  okay := cog := cognew(@entry, @rx_head) + 1

PUB Stop
{{Stop serial communication; frees a cog.}}

  if cog
    cogstop(cog~ - 1)
  longfill(@rx_head, 0, 9)

PUB Char(bytechr)
{{Send single-byte character.  Waits for
room in transmit buffer if necessary.

Parameter:
  bytechr - character (ASCII byte value)
            to send.

Eamples:
  'Send "A" to Parallax Serial Terminal
  pst.Char("A")
  'Send "A" to Parallax Serial Terminal
  'using its ASCII value
  pst.Char(65)              
}}

  ifnot cog
    start(115_200)

  repeat until (tx_tail <> ((tx_head + 1) & BUFFER_MASK))
  tx_buffer[tx_head] := bytechr
  tx_head := (tx_head + 1) & BUFFER_MASK

  if rxtx_mode & %1000
    CharIn

PUB Chars(bytechr, count)
{{Send multiple copies of a single-byte
character. Waits for room in transmit buffer
if necessary.

Parameters:
  bytechr - character (ASCII byte value) to
            send.
  count   - number of bytechrs to send.

Example:
  'Send "AAAAA" to Parallax Serial Terminal
  pst.Chars("A", 5)
  }}
 
  ifnot cog
    start(115_200)

  repeat count
    Char(bytechr)

PUB CharIn : bytechr
{{Receive single-byte character.  Waits
until character received.

Returns:
  A byte value (0 to 255) which
  represents a character that has been typed 
  into the Parallax Serial Terminal.

Example:
  ' Get a character that is typed into the
  ' Parallax Serial Terminal, and copy it to
  ' a variable named c.
  c := pst.CharIn
}}

  ifnot cog
    start(115_200)

  repeat while (bytechr := RxCheck) < 0

PUB Str(stringptr)
{{Send zero terminated string.
Parameter:
  stringptr - pointer to zero terminated
              string to send.

Examples:
  ''Send string with String operator.
  pst.Str(String("Hello!"))

  ''Send string from DAT block
  '...code omitted
  PUB Go
    pst.Str(@myDatString)
  DAT
    myDatString byte "abcdefg", 0
    '                           
    '        Zero terminator ───┘
}}

  ifnot cog
    start(115_200)

  repeat strsize(stringptr)
    Char(byte[stringptr++])

PUB StrIn(stringptr)
{{Receive a string (carriage return
terminated) and stores it  (zero terminated)
starting at stringptr.  Waits until full
string received.
Parameter:
  stringptr - pointer to memory in which to
    store received string characters.
    Memory reserved must be large enough for
    all string characters plus a zero
    terminator.

Example:

  ' Get a string that's up to 100 characters
  ' long (including zero terminator) from
  ' the Parallax Serial Terminal.
  '...code omitted
  VAR
    byte mystr(100)
  PUB Go
    '... code omitted
    pst.StrIn(@mystr)
}}
  
  ifnot cog
    start(115_200)

  StrInMax(stringptr, -1)

PUB StrInMax(stringptr, maxcount)
{{Receives a string of characters (either
carriage return terminated or maxcount in
length) and stores it (zero terminated)
starting at stringptr.  Waits until either
full string received or maxcount characters
received.

Parameters:
  stringptr - pointer to memory in which to
  store received string characters. Memory
  reserved must be large enough for all
  string characters plus a zero terminator
  (maxcount + 1).  maxcount  - maximum
  length of string to receive, or -1 for
  unlimited.

Example:
  ' Get a string that's up to 100 characters
  ' long (including zero terminator) from
  ' the Parallax Serial Terminal.  ...and
  ' make sure that the string buffer isn't
  ' overloaded.
  '...code omitted
  VAR
    byte mystr(100)
  PUB Go
    '... code omitted
    pst.StrInMax(@mystr, 99)
}}
    
  ifnot cog
    start(115_200)

  repeat while (maxcount--)                                                     'While maxcount not reached
    if (byte[stringptr++] := CharIn) == NL                                      'Get chars until NL
      quit
  byte[stringptr+(byte[stringptr-1] == NL)]~                                    'Zero terminate string; overwrite NL or append 0 char

PUB Dec(value) | i, x
{{Send value as decimal characters.
Parameter:
  value - byte, word, or long value to
  send as decimal characters.
 
Examples:

  'Display 100 in Parallax Serial Terminal
  pst.Dec(100)

  'Display variable value as decimal in
  'Parallax Serial Terminal.
  '...code omitted
  VAR
    long val
  PUB Go
    '... code omitted
    val := 100
    pst.Dec(val)
}}

  ifnot cog
    start(115_200)

  x := value == NEGX                                                            'Check for max negative
  if value < 0
    value := ||(value+x)                                                        'If negative, make positive; adjust for max negative
    Char("-")                                                                   'and output sign

  i := 1_000_000_000                                                            'Initialize divisor

  repeat 10                                                                     'Loop for 10 digits
    if value => i                                                               
      Char(value / i + "0" + x*(i == 1))                                        'If non-zero digit, output digit; adjust for max negative
      value //= i                                                               'and digit from value
      result~~                                                                  'flag non-zero found
    elseif result or i == 1
      Char("0")                                                                 'If zero digit (or only digit) output it
    i /= 10                                                                     'Update divisor

PUB strJoin(whereToPut, whereToGet) '' 5 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Concatenates a string onto the end of another. This method can corrupt memory.
'' //
'' // Returns a pointer to the new string.
'' //
'' // WhereToPut - Address of the string to concatenate a string to.
'' // WhereToGet - Address of where to get the string to concatenate.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  bytemove((whereToPut + strsize(whereToPut)), whereToGet, (strsize(whereToGet) + 1))
  return whereToPut
  
PUB DecIn : value
{{Receive carriage return terminated string
of characters representing a decimal value.

Returns: the corresponding decimal value.

Example:

  ' Get a decimal value that is typed into
  ' the Parallax Serial Terminal's
  ' Transmit windowpane.
  '...code omitted
  VAR
    long val
  PUB Go
    '...code omitted
    val := pst.DecIn
  }}

  ifnot cog
    start(115_200)

  StrInMax(@str_buffer, MAXSTR_LENGTH)
  value := StrToBase(@str_buffer, 10)

PUB Bin(value, digits)
{{Send value as binary characters up to
digits in length.

Parameters:
  value  - byte, word, or long value to send
           as binary characters.
  digits - number of binary digits to send.
           Will be zero padded if necessary.

Examples:

  'Display decimal-10 as a binary value in
  'the Parallax Serial Terminal.  The result
  'should be 1010, which is binary for 10.
  pst.Bin(10, 4)

  'Display variable value as binary in
  'Parallax Serial Terminal.  Also, try
  'val := %1010.  The % operator means you
  'are using a binary value instead of a
  'decimal one.
  '...code omitted
  VAR
    long val
  PUB Go
    '... code omitted
    val := 10
    pst.Bin(val, 4)
}}
   
  ifnot cog
    start(115_200)

  value <<= 32 - digits
  repeat digits
    Char((value <-= 1) & 1 + "0")

PUB BinIn : value
{{Receive carriage return terminated string
of characters representing a binary value.

Returns:
  the corresponding binary value.

Example:

  ' Get a binary value that is typed into
  ' the Parallax Serial Terminal's
  ' Transmit windowpane.
  '...code omitted
  VAR
    long val
  PUB Go
    '...code omitted
    val := pst.BinIn
}}
   
  ifnot cog
    start(115_200)

  StrInMax(@str_buffer, MAXSTR_LENGTH)
  value := StrToBase(@str_buffer, 2)
   
PUB Hex(value, digits)
{{Send value as hexadecimal characters up to
digits in length.
Parameters:
  value  - byte, word, or long value to send
           as hexadecimal characters.
  digits - number of hexadecimal digits to
           send.  Will be zero padded if
           necessary.

Examples:

  'Display decimal-10 as a hexadecimal value
  'in the Parallax Serial Terminal.  The
  'result should be the hexadecimal 0A.
  pst.Hex(10, 2)

  'Display variable value as hexadecmial in
  'Parallax Serial Terminal.  Also, try
  'val := $A.  The $ operator means you
  'are using a hexadecimal value instead of
  'a decimal one.
  '...code omitted
  VAR
    long val
  PUB Go
    '... code omitted
    val := 10
    pst.Hex(val, 2)
}}
 
  ifnot cog
    start(115_200)

  value <<= (8 - digits) << 2
  repeat digits
    Char(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

PUB HexIn : value
{{Receive carriage return terminated string
of characters representing a hexadecimal
value.
  Returns: the corresponding hexadecimal
  value.

Example:

  ' Get a binary value that is typed into
  ' the Parallax Serial Terminal's
  ' Transmit windowpane.
  '...code omitted
  VAR
    long val
  PUB Go
    '...code omitted
    val := pst.BinIn
}}

  ifnot cog
    start(115_200)

  StrInMax(@str_buffer, MAXSTR_LENGTH)
  value := StrToBase(@str_buffer, 16)

PUB Clear
{{Clear screen and place cursor at top-left.

Example:
  pst.Clear
}}
  
  ifnot cog
    start(115_200)

  Char(CS)

PUB ClearEnd
{{Clear line from cursor to end of line.

Example:
  pst.ClearEnd
}}
  
  ifnot cog
    start(115_200)

  Char(CE)
  
PUB ClearBelow
{{Clear all lines below cursor.

Example:
  pst.ClearBelow
}}
  
  ifnot cog
    start(115_200)

  Char(CB)
  
PUB Home
{{Send cursor to home position (top-left).

Example:
  pst.Home
}}
  
  ifnot cog
    start(115_200)

  Char(HM)
  
PUB Position(x, y)
{{Position cursor at column x, row y (from
top-left).

Example:
  'Position cursor 5 spaces to the right
  'and 6 carriage returns from the top.
  pst.Position(5, 6)
}}
  
  ifnot cog
    start(115_200)

  Char(PC)
  Char(x)
  Char(y)
  
PUB PositionX(x)
{{Position cursor at column x of current row.

Example:
  'Position cursor 5 spaces to the right in
  'whatever row the cursor is located.
  pst.PositionX(5)
}}
  Char(PX)
  Char(x)
  
PUB PositionY(y)
{{Position cursor at row y of current column.
Example:
  'Position cursor 6 carriage returns down
  'from its current position.
  pst.PositionY(6)
}}
  ifnot cog
    start(115_200)

  Char(PY)
  Char(y)

PUB NewLine
{{Send cursor to new line (carriage return
plus line feed).}}
  
  ifnot cog
    start(115_200)

  Char(NL)
  
PUB LineFeed
{{Send cursor down to next line.

Example:
  pst.LineFeed
}}
  
  ifnot cog
    start(115_200)

  Char(LF)
  
PUB MoveLeft(x)
{{Move cursor left x characters.

Example:
  'Move cursor 3 characters to the left.
  pst.MoveLeft(3)
}}
  
  ifnot cog
    start(115_200)

  repeat x
    Char(ML)
  
PUB MoveRight(x)
{{Move cursor right x characters.

Example:
  'Move cursor 3 characters to the right.
  pst.MoveRight(3)
}}
  
  ifnot cog
    start(115_200)

  repeat x
    Char(MR)
  
PUB MoveUp(y)
{{Move cursor up y lines.

Example:
  'Move cursor 3 lines upward.
  pst.MoveUp(3)
}}
  
  ifnot cog
    start(115_200)

  repeat y
    Char(MU)
  
PUB MoveDown(y)
{{Move cursor down y lines.

Example:
  'Move cursor 3 lines down.
  pst.MoveDown(3)
}}
  
  ifnot cog
    start(115_200)

  repeat y
    Char(MD)
  
PUB Tab
{{Send cursor to next tab position.

Example:
  pst.Tab
}}
  
  ifnot cog
    start(115_200)

  Char(TB)
  
PUB Backspace
{{Delete one character to left of cursor and
move cursor there.

Example:
  pst.Backspace
}}
  
  ifnot cog
    start(115_200)

  Char(BS)
  
PUB Beep
{{Play bell tone on PC speaker.

Example:
  pst.Bell
}}
  
  ifnot cog
    start(115_200)

  Char(BP)
  
PUB RxCount : count
{{Get count of characters in receive buffer.
  Returns: number of characters waiting in
  receive buffer.

Examples:
  'Store how many characters are in the
  'input buffer in a variable named val.
  '...code omitted
  VAR
    word val
  PUB Go
  '...code omitted
    val := pst.RxCount

  'Clear the buffer if it has more than
  '20 characters
  VAR
    byte mystr(21)
  PUB Go
  '...code omitted
    if pst.RxCount > 20
      pst.MaxStr(@myStr, 20)
  '...       
}}

  ifnot cog
    start(115_200)

  count := rx_head - rx_tail
  count -= BUFFER_LENGTH*(count < 0)

PUB RxFlush
{{Flush receive buffer.

This method can be useful if you know there
will be a bunch of characters in the buffer
that do not matter to your application.  For
example, maybe the first 5 seconds of
characters that get sent don't matter

Example:

  if t > 5
    pst.RxFlush
}}

  ifnot cog
    start(115_200)

  repeat while rxcheck => 0
    
PRI RxCheck : bytechr
{Check if character received; return immediately.
  Returns: -1 if no byte received, $00..$FF if character received.}

  bytechr~~
  if rx_tail <> rx_head
    bytechr := rx_buffer[rx_tail]
    rx_tail := (rx_tail + 1) & BUFFER_MASK

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
       
DAT

'***********************************
'* Assembly language serial driver *
'***********************************

                        org
'
'
' Entry
'
entry                   mov     t1,par                'get structure address
                        add     t1,#4 << 2            'skip past heads and tails

                        rdlong  t2,t1                 'get rx_pin
                        mov     rxmask,#1
                        shl     rxmask,t2

                        add     t1,#4                 'get tx_pin
                        rdlong  t2,t1
                        mov     txmask,#1
                        shl     txmask,t2

                        add     t1,#4                 'get rxtx_mode
                        rdlong  rxtxmode,t1

                        add     t1,#4                 'get bit_ticks
                        rdlong  bitticks,t1

                        add     t1,#4                 'get buffer_ptr
                        rdlong  rxbuff,t1
                        mov     txbuff,rxbuff
                        add     txbuff,#BUFFER_LENGTH

                        test    rxtxmode,#%100  wz    'init tx pin according to mode
                        test    rxtxmode,#%010  wc
        if_z_ne_c       or      outa,txmask
        if_z            or      dira,txmask

                        mov     txcode,#transmit      'initialize ping-pong multitasking
'
'
' Receive
'
receive                 jmpret  rxcode,txcode         'run chunk of tx code, then return

                        test    rxtxmode,#%001  wz    'wait for start bit on rx pin
                        test    rxmask,ina      wc
        if_z_eq_c       jmp     #receive

                        mov     rxbits,#9             'ready to receive byte
                        mov     rxcnt,bitticks
                        shr     rxcnt,#1
                        add     rxcnt,cnt                          

:bit                    add     rxcnt,bitticks        'ready next bit period

:wait                   jmpret  rxcode,txcode         'run chunk of tx code, then return

                        mov     t1,rxcnt              'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        test    rxmask,ina      wc    'receive bit on rx pin
                        rcr     rxdata,#1
                        djnz    rxbits,#:bit

                        shr     rxdata,#32-9          'justify and trim received byte
                        and     rxdata,#$FF
                        test    rxtxmode,#%001  wz    'if rx inverted, invert byte
        if_nz           xor     rxdata,#$FF

                        rdlong  t2,par                'save received byte and inc head
                        add     t2,rxbuff
                        wrbyte  rxdata,t2
                        sub     t2,rxbuff
                        add     t2,#1
                        and     t2,#BUFFER_MASK
                        wrlong  t2,par

                        jmp     #receive              'byte done, receive next byte
'
'
' Transmit
'
transmit                jmpret  txcode,rxcode         'run chunk of rx code, then return

                        mov     t1,par                'check for head <> tail
                        add     t1,#2 << 2
                        rdlong  t2,t1
                        add     t1,#1 << 2
                        rdlong  t3,t1
                        cmp     t2,t3           wz
        if_z            jmp     #transmit

                        add     t3,txbuff             'get byte and inc tail
                        rdbyte  txdata,t3
                        sub     t3,txbuff
                        add     t3,#1
                        and     t3,#BUFFER_MASK
                        wrlong  t3,t1

                        or      txdata,#$100          'ready byte to transmit
                        shl     txdata,#2
                        or      txdata,#1
                        mov     txbits,#11
                        mov     txcnt,cnt

:bit                    test    rxtxmode,#%100  wz    'output bit on tx pin 
                        test    rxtxmode,#%010  wc    'according to mode
        if_z_and_c      xor     txdata,#1
                        shr     txdata,#1       wc
        if_z            muxc    outa,txmask        
        if_nz           muxnc   dira,txmask
                        add     txcnt,bitticks        'ready next cnt

:wait                   jmpret  txcode,rxcode         'run chunk of rx code, then return

                        mov     t1,txcnt              'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        djnz    txbits,#:bit          'another bit to transmit?

                        jmp     #transmit             'byte done, transmit next byte
'
'
' Uninitialized data
'
t1                      res     1
t2                      res     1
t3                      res     1

rxtxmode                res     1
bitticks                res     1

rxmask                  res     1
rxbuff                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1

txmask                  res     1
txbuff                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1
txcode                  res     1

{{
File: Parallax Serial Terminal Plus.spin
Date: 2012.05.12
Version: 1.01.1
  - Does not require a Start method call
  - If a method other than Start is
    called first, this object starts
    automatically, and its settings
    will match the Parallax Serial
    Terminal software's defaults.

Authors: Jeff Martin, Andy Lindsay, Chip Gracey  

This object is heavily based on
FullDuplexSerialPlus (by Andy Lindsay),
which is itself heavily based on
FullDuplexSerial (by Chip Gracey).

Copyright (c) 2012 Parallax, Inc.

┌────────────────────────────────────────────┐
│TERMS OF USE: MIT License                   │
├────────────────────────────────────────────┤
│Permission is hereby granted, free of       │
│charge, to any person obtaining a copy      │
│of this software and associated             │
│documentation files (the "Software"),       │
│to deal in the Software without             │
│restriction, including without limitation   │
│the rights to use, copy, modify, merge,     │
│publish, distribute, sublicense, and/or     │
│sell copies of the Software, and to permit  │
│persons to whom the Software is furnished   │
│to do so, subject to the following          │
│conditions:                                 │
│                                            │
│The above copyright notice and this         │
│permission notice shall be included in all  │
│copies or substantial portions of the       │
│Software.                                   │
│                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT   │
│WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES │
│OF MERCHANTABILITY, FITNESS FOR A           │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN  │
│NO EVENT SHALL THE AUTHORS OR COPYRIGHT     │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR │
│OTHER LIABILITY, WHETHER IN AN ACTION OF    │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM,  │
│OUT OF OR IN CONNECTION WITH THE SOFTWARE   │
│OR THE USE OR OTHER DEALINGS IN THE         │
│SOFTWARE.                                   │
└────────────────────────────────────────────┘
}}
