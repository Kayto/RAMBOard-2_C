## Software

### Background

This section is a work in progress and hopes to detail some examples of "drive code", ideally using the RAMBOard. It's not the best guide as I am really a novice programmer. My days with the C64 were mainly spent with some BASIC type-ins and lots of gaming. I only had a datasette then, so the 1541 is relatively new to me.

If you want to skip the below and see a more exciting example of "drive code" then look here. This example is not using extra drive RAM, so I imagine there is potential for improvement. 

**[Realtime filled vectors with calculations performed in drive](https://codebase64.org/doku.php?id=base:drivecalc_vectors)**

### Sources

I have provided a summary page with some useful information and links to guides, books and articles about drive coding and the RAMBOard. Some of the information is not maintained any more, so where it seems to be at risk of disappearing I have archived it here. Original credits and sources will be linked.

**[Useful info](USEFULINFO.md)**

**[Sources and credits](https://github.com/Kayto/RAMBOard-2_C/tree/main/Sources)**

## Examples

Some examples are collated that I have been using and developing to specifically test the RAMBOard.
| Name  | Description |
|----------|:-------------|
| **[WHEREISMYRAM.bas](whereismyram.bas)** | This BASIC program runs through and checks 2K blocks of RAM. |
| **[1541RAMREAD.bas](1541RAMREAD.bas)** | This BASIC program list the contents of a particular area of drive ROM/RAM. Useful to check whether the code you want is actually there. |
| **[RAMBoard Format 41]() **| My adaptation of a format routine for 41 tracks. It uses the RAMBOard to store the extra track routine. Once stored in the RAMBOard it can be called via the basic program at any time. Well unless power is cycled on the 1541. Demonstrates the use of the RAMBOard as a place to store away programs. Again it still rather pointless as you still need to load the RAMBOard at least once. How many 41 track discs do you need? Erm...and this could also be done without the board...still its something?























 
