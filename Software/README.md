## Software

Work in progress...

### Background

This section hopes to detail some examples of "drive code", ideally using the RAMBOard. It's not the best guide as I am really a novice programmer. My days with the C64 were mainly spent with some BASIC type ins and loads of gaming. I only had a datasette then so the 1541 is relatively new to me.

If you want to skip the below and see a more exciting example of "drive code" then look here.

**[Realtime filled vectors with calculations performed in drive](https://codebase64.org/doku.php?id=base:drivecalc_vectors)**

This example is not using extra drive RAM so I imagine there is potential for improvement.

### Sources

I have provided a summary page with some useful information and links to guides, books and articles about drive coding.

Some of the information is not maintained any more, so where it seems to be at risk of disapperaing I have archived. Original credits and sources will be linked.

Please take a look [here]


## Examples

Some examples are collated that I am using and developing to specifically test the RAMBOard.
| Name  | Description |
|----------|:-------------|
|**1541RAMREAD.bas**| This BASIC program list the contents of a particular area of drive ROM/RAM. Useful to check wheher the codeyou want is actually there.|
| **WHEREISMYRAM.bas** | This BASIC program runs through and check2K blocks of RAM. |












## 1541 User Guide

The original 1541-II user guide provides information on accessing drive memory, which I summarise below;

### MEMORY-WRITE 

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











 
