
# Commodore 1541 Drive Code Addition

This program loads and executes custom drive code on the Commodore 1541 disk drive. 
The `.obj` file is a binary object file containing the machine code to be executed on the 1541 drive.
The code is a simple exampe that just takes input numbers and adds 5 to them.
The memory location in the drive is defined in the .obj. In this example it uses $8100, which assume extra RAM is located in the drive.
Without a physical RAMBOard you can use the Vice emulator to test as this provides option to add RAM to the drive.
Alternatively this can be run on an unmodified 1541 by adjusting the .obj to use the existing drive RAM at $0400.

Note that;
- the drive code resides in the 1541 RAM at $8100
- the input values and subsequent processed values are also in the 1541 RAM at $0300.

## Title Display and Initialization
```basic
10 rem ***************************
20 rem * addition in the 1541 *
30 rem ***************************
40 print chr$(147);chr$(17);chr$(29);chr$(5);
50 print "  addition in the 1541";chr$(17)
```
- **Purpose**: Sets up the program's visual interface by displaying the title and clearing the screen.

## Command Channel Setup
```basic
60 open15,8,15: rem the open command channel
70 print#15,"io": rem initialise
80 input#15,en$,em$,et$,es$: rem input the error status
```
- **Purpose**: Establishes communication with the disk drive and initializes it.
- **Details**:
  - Line 60 opens the command channel (device 15) for communication.
  - Line 70 sends the "io" command to initialize the disk drive.
  - Line 80 retrieves the error status and stores it in variables `en$`, `em$`, `et$`, and `es$` for further processing.

## Error Handling and Drive Code Loading
```basic
90 if en$="00"then goto 120: rem no error encountered
100 rem load drive code if not already loaded
110 open2,8,2,"dc.add.1541.obj,s,r": rem open drive code file
```
- **Purpose**: Checks for errors and loads the drive code if necessary.
- **Details**:
  - Line 90 checks if the error status (`en$`) is "00" (no error). If true, it skips to line 120.
  - Line 110 opens the drive code file `dc.add.1541.obj` in read mode.

### Handling `.obj` File
- The `.obj` file is a binary object file containing the machine code to be executed on the 1541 drive.
- It is loaded into the drive's memory using direct access commands (e.g., `m-w` for memory write).
- The file is read block by block, and each block is written to the appropriate memory location on the drive.

## Extracting Track and Sector Numbers
```basic
200 t=asc(t$+chr$(0))
210 s=asc(s$+chr$(0))
```
- **Purpose**: Converts track and sector numbers from ASCII to numeric values for processing.
- **Details**:
  - Line 200 converts the ASCII value of the track number (`t$`) to its numeric equivalent.
  - Line 210 converts the ASCII value of the sector number (`s$`) to its numeric equivalent.

## Loading Drive Code into Memory
```basic
290 print chr$(17);chr$(29);chr$(18);chr$(5);
300 print "loading";chr$(146);chr$(5);" drive code...";chr$(17)
310 open2,8,2,"#2"
320 print#15,"u1";2;0;t;s
330 print#15,"m-r"chr$(2)chr$(5)chr$(2)
340 get#15,lb$:iflb$=""thenlb$=chr$(0)
350 get#15,hb$:ifhb$=""thenhb$=chr$(0)
360 hb=asc(hb$):lb=asc(lb$): rem print " ";hb;lb
```
- **Purpose**: Reads the drive code from the disk and loads it into memory.
- **Details**:
  - Line 290 clears the screen and positions the cursor.
  - Line 300 displays a loading message.
  - Line 310 opens a file on device 8, channel 2.
  - Line 320 sends a "u1" command to read a block from the disk.
  - Line 330 sends a "memory read" command to retrieve the .obj load address. high byte and low byte.
  - Lines 340-350 retrieve the low and high bytes of the load address and convert them to numeric values.

## Writing Data to Memory
```basic
400 for i=0to255
410 get#2,a$:ifa$=""thena$=chr$(0)
420 tf%(i)=asc(a$)
430 next i
510 mw$="m"+"-"+"w"
520 for i=0to40
530 x=tf%(i)
550 print#15,mw$+chr$(lb)chr$(hb)chr$(1)chr$(x)
```
- **Purpose**: Transfers data from the file to the disk drive's memory.
- **Details**:
  - Lines 400-430 read 256 bytes of data from the file and store them in an array.
  - Line 510 defines the memory write command string `mw$` as "m-w" and uses the high byte/low byte address.
  - Lines 520-550 write the data from the array to the disk drive's memory using the "m-w" command.

## Executing the Program
```basic
600 for i=0to7
610 print#15,"m-w"chr$(i)chr$(3)
620 next i
630 print chr$(17);"executing floppy program"
640 print#15,"b-e";5;0;1;0
650 print"reading from memory..."
```
- **Purpose**: Executes the program stored in the disk drive's memory.
- **Details**:
  - Lines 600-620 send commands to write data to memory.
  - Line 630 displays a message indicating the program's execution.
  - Line 640 sends a "block execute" command to run the program.
  - Line 650 displays a message indicating data retrieval.

## Data Retrieval and Display
```basic
720 for i=0to7
740 get#15,v$:if v$="" then v$=chr$(0)
750 print tab(5);"+5 = ";asc(v$)
760 next i
```
- **Purpose**: Reads and displays data from the disk drive's memory.
- **Details**:
  - Line 720 starts a loop to iterate over 8 memory locations.
  - Line 740 retrieves data from the disk drive and assigns a default value of 0 if empty.
  - Line 750 prints the numeric value of the retrieved data.
  - Line 760 increments the loop counter and continues the loop.

## Closing Channels
```basic
780 close5
790 close15
```
- **Purpose**: Closes the file and command channel to the disk drive.
- **Details**:
  - Line 780 closes the file opened earlier.
  - Line 790 closes the command channel to the disk drive.

