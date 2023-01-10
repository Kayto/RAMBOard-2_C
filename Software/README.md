## 1541 MEMORY MAP

### 2K of RAM memory

0000-00FF     Zero page work area: job queue , important variables & pointers

0100-0lFF     Stack work area

0200-02FF     Command buffers & tables: channels, parser, output, variables

0300-07FF     Data buffers 0-4, 1 per page of memory 

### Input/Output chips

1800-180F     6522 VIA: I/0 to computer

1C00-1C0F     6522 VIA: I/O to disk controller

### Disk Operating System ROM

C100-F258     Interface Processor: receive & interpret commands from computer

F259-FE66     Floppy Disk Controller: executes IP's commands, controls mechanism

FE67-FE84     IRQ handler: switches from lP to FDC & back every 10 ms.

FE85-FEE6     ROM tables & constants

FEE7-FF0F     Patch area

FFE6-FFFF     JMP table: User command vectors 

## MEMORY-WRITE 

The Memory-Write command is the equivalent of the Basic Poke command, but has
its effect in disk memory instead of within the computer. M-W allows you to write up to
34 bytes at a time into disk memory. The Memory-Execute and some User commands can
be used to run any programs written this way. 


PRINT# 15 ,"M-W"CHR$( <address)CHR$(>address)CHR$(# of bytes)CHR$(data byte(s))

where **" < address"** is the low order part, and **" >address"** is the high order part of the
address in disk memory to begin writing, **"# of bytes"** is the number of memory
locations that will be written (from 1-34), and **"data byte"** is 1 or more byte values to be
written into disk memory, each as a CHR$() value . If desired, a colon (:) may follow MW within the quotation marks.

ALTERNATE FORMAT:

PRINT# 15,"M-W:"CHR$( <address)CHR$(> address)CHR$(#of bytes)CHR$(data byte(s)) 









 
