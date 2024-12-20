## Software

### Background

This section is a work in progress and hopes to detail some examples of "drive code", ideally using the RAMBOard. It's not the best guide as I am really a novice programmer. My days with the C64 were mainly spent with some BASIC type-ins and lots of gaming. I only had a datasette then, so the 1541 is relatively new to me.

If you want to skip the below and see a more exciting example of "drive code" then look here. This example is not using any extra drive RAM. 

**[Realtime filled vectors with calculations performed in drive](https://codebase64.org/doku.php?id=base:drivecalc_vectors)**

### Sources

I have provided a summary page with some useful information and links to guides, books and articles about drive coding and the RAMBOard. Some of the information is not maintained any more, so where it seems to be at risk of disappearing I have archived it here. Original credits and sources will be linked.

**[Useful info](USEFULINFO.md)**

**[Sources and credits](https://github.com/Kayto/RAMBOard-2_C/tree/main/Sources)**

## Examples

Some examples are collated that I have been using and developing to specifically test the RAMBOard and look at `drive code` in general.
| Name  | Description |
|----------|:-------------|
| **[WHEREISMYRAM.bas](whereismyram.bas)** | This BASIC program runs through and checks 2K blocks of RAM. |
| **[1541RAMREAD.bas](1541RAMREAD.bas)** | This BASIC program list the contents of a particular area of drive ROM/RAM. Useful to check whether the code you want is actually there. |
| **[RAMBoard Format 41](https://github.com/Kayto/RAMBOard-2_C/tree/main/Software/RAMBOard_1541_Format_41)** | My adaptation of a format routine for 41 tracks. It uses the RAMBOard to store the extra track routine. Once stored in the RAMBOard it can be called via the basic program at any time. Well until you power cycle the 1541. Demonstrates the use of the RAMBOard as a place to store away programs. Again it is still rather pointless as you still need to load the RAMBOard at least once. How many 41 track discs do you need? Erm...and this could also be done without the board...still its something? **CAUTION** tested in Vice only, I would not recommend it in a real 1541 unless you know what you are doing as it shifts the head quite close to the limit! I perhaps should have made it for 38 tracks. |
| **[1541add](https://github.com/Kayto/RAMBOard-2_C/tree/main/Software/1541add)** | Based on the work here https://www.youtube.com/@w.o.p.r. a concept to show addition within the 1541. A seperate README explains what is going on. The BASIC program acts as a front end for code loading and execution in the 1541. The code is in an .obj file and the examples takes the input numbers and outputs them with a fixed addition, using the 1541 CPU/RAM. | 























 
