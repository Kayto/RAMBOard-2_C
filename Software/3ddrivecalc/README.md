### Work in progress

In my attempts to explore some additional uses for the RAMBOard, I came across the drive code examples on codebase64.

One of which provided a use of the 1541 to undertake program calculations for a nice looking graphics demo. 

Currently I am trying to convert and compile original TASM code. The aim is to have some working source code that I can use as a playground to mess around with memory locations and sizing within the 1541 and RAMBOard.

- [ ] First problem to solve is getting a workable source. 

#### Source code

1. Original folder contains original source and prg
2. My hand corrections for TASM to KickASS - compiles but runs with errors, looks like tape buffer
3. My hand corrections for TASM within C64Studio - build fails on error below.

**Item 2**

garbage start screen, tape load?

**Item 3**

Error relates to the drive code address as follows;

1208;E1001;Could not evaluate * position value

```
;--------
;---     start drive code
;--------
save
;--------
.driverun = $0300
         *= driverun       
         .offs = save-*       
.ofsetto  = driverun-save
;--------
.adstart  = save+*-driverun
