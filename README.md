# RAMBOard 2/C - Redrawn 2022
Recreating a functional RAMBOard for the Commodore 64 1541-II disc drive, using a modified schematic that I stumbled across online. 

Expending time and energy so you can make up your mind if its worth it....you're welcome.

## Background

The RAMBOard was a RAM enhancement for the Commodore floppy disc drives.
It provided extra RAM within the drive for use in disk copiers such as Maverick. 
By adding 8K of RAM to the system board it could achieve full-track GCR disk copies on a Commodore 5.25" floppy drive. This provided a further option to archive disks that couldn't be processed by software alone.

To get a better idea of use in the era, look at some of the 1980s [advertisements](External_Photos/Adverts.md).

The original 1989 RAMBOard was developed by Chip Level Designs (CLD) and then picked up and redesigned in 2006 by Wolfgang Moser (Womo).

Modern PCB versions are available among the C64 community but are not that easy to find.

Given that niche hardware comes and goes, I thought I would have a go at making a RAMBOard using the information that was available.

Note that the original and 2006 redesign source files were never released. On this basis I intend to use the exercise to learn more KiCad, do a bit of PCB testing. I share the schematics, images and findings from my build - sorry no KiCad or Gerber files. I have also collated the useful information available as a backup archive but avoided duplication - refer to the original links in the first instance.

## Credits:
The designs presented here are by others, the information I used is linked where available;

* Chip Level Design for the original RAMBOard design.

* Wolfgang Moser - his web page covering detail of the RAMBOard and including a reverse-engineered schematic. This forms the basis for my tinkering. http://d81.de/CLD-RAMBOard/RAMBOard-2C.shtml

* Glenn Holmer for providing the original manual and installation photographs of the original board. https://www.lyonlabs.org/commodore/hardware/index.html


## What is it good for?

In 2022 the use case of such a board is quite niche, given the abundance of modern hardware alternatives to original drives and floppies.

However, I wanted to backup some original 5.25 discs that I own to "new" floppy discs. It was Project Stealth Fighter if you are wondering. I wanted a replica of the original disc rather than say a cracked version.
Uncracked "backup" images can be found online but the integrity and ability to duplicate, onto original media using original hardware, in my experience was rather mixed. I would still need to resort to parameter methods to get things done. So why not add a RAMBOard to the toolkit!  

Besides all this domestic insight, its quite satisfying as a project to take a schematic and physically produce something. There is no better way of learning than by example.

- ### Is that it?

From within the C64 community, it was brought to my attention that there are other more obscure uses for a ram board, making it viable to run 'drive side' software. https://www.facebook.com/groups/286184360297310/permalink/465480915700986/

The benefit of drive ram is that the added memory won't be seen by the C64 unless you tell it to. This allows a safe space for additional programs to be called from.
'Drive side' software can be found in some publications from the C64 heyday which for example allow special operation such as extra "hidden tracks" and additional track sectors on a disc.

If only my coding skills were better - in the meantime I aim to collate some detailed examples, this will be a work in progress - as and when I find them and the time.

## Project Details

* ### Schematics and board layout

The IC and track layout for the PCB and supporting schematics from KiCAD can be found **[here](Schematics/README.md)**.

* U1 - the existing drive ROM
* U2 - 4168 RAM or SRAM aternative
* U3 - 74LS139

I made one mistake on the PCB traces - at solder jumper JP1, pads "1" and "2" needed to be preconfigured as closed - bridged by a trace. However a solder bridge will do. 

* ### RAM IC

As documented by Wolfgang Moser there is a key difference between the latest RAMBOard and the original.
This relates to the type of RAM that is used. The original used a 4168 pseudo static 8Kx8 RAM "iRAM" which was effectively a DRAM, requiring refresh cycles. To accomodate this, the board needed connection to the PHI2 clock as well as a refresh delay provided by a capacitor. 

I didn't try to look for an original 4168 but I am guessing that these are pretty hard to find these days.
I therefore opted for a more common SRAM, as Womo had already done the hard work on determining the use of SRAM.

One thing to note is that I only had a 62256 32Kx8 bit Static RAM available. With this option I had to make the following modifications to make it work. Both of which are mentioned by Wolfgang Moser as a potential requirement.

* Free wire "C" - connect to a steady HIGH 5V - instead of the PHI2.
* Disconnect or don't bother to install the capacitor - to remove the RAM OE delay.

* ### Installation

Photos of the installation are **[here](Installation/README.md)**.

The board connects to the exiting ROM socket in the drive. Typically, the existing ROM IC is socketed. Remove the IC and place in the RAMBOard before installing. Refer to the original installation instructions for the detail.

The fitting of the board is very tight with minimal clearance to the drive flywheel and belt.
The original installation instructions note this, the board height needed care when building the board. I opted to socket all chips, as this was a prototype, so it made things even more tight.

It was possible to socket all the ICs and provide clearance by;

1) Shortening the male headers that connect to the original ROM socket. I installed standard headers but put the bottom section of the header through the top face of the PCB and soldered from the bottom. Then trimmed the headers flush at the top of the PCB. This shortened the PCB height to flush on the existing ROM socket.  

2) Using low profile pin socket headers instead of IC sockets for U1 and U2.

The other free wires "A" and "B" need connection to existing ICs within the drive. I found it more convenient to connect as the original instalation instructions. 

* "A" requires connection to A14 - 6502 - U3 - Pin 24
* "B" requires connecton to RAM-WE - 6522 - U6 - Pin 22

As noted the RAM IC section above, wire "C" could be removed altogether and a bodge wire added to the RAMBOard from "C" to the 5V through hole on the PCB. In my case i connected to 6522 - U8 - Pin 20.

## Testing

To test the board, the original software was used. A copy of the disc image can be obtained from the credit link to Glen Holmers site.

The original disc contains a RAMBOARD TEST.prg which verifies the RAM. Images of the software in action **[here](Original_Software/README.md)**.

For those interested the Vice emulator has support for RAMBOards so you can have a go yourself without the bother of PCBs and soldering!

## Want one?

You sure? Modern boards do appear now and again for purchase.

https://www.protovision.games/shop/

## Next Steps

Some ideas for further work.

- [ ] Collate some software examples that utilise the RAMBOard
- [ ] Utilise more RAM blocks
- [ ] Rationalise the board layout and jumpers
- [ ] Fix the mistake at JP1.


