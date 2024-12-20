10 rem ***************************
20 rem * addition in the 1541 *
30 rem  ***************************
35 :
40 print chr$(147);chr$(17);chr$(29);chr$(5);
50 print "  addition in the 1541";chr$(17)
60 open15,8,15: rem the open command channel
70 rem opens the command channel to communicate with the disk drive.
70 print#15,"io": rem initialise
80 rem initializes the disk drive by sending the io command.
80 input#15,en$,em$,et$,es$ : rem input the error status
90 rem retrieves the error status from the disk drive.
90 if en$="00"then goto 120: rem no error encountered
100 rem checks if there is no error (error code 00) and proceeds accordingly.
100 print en$","em$","et$","es$ : rem print the error status on screen
110 print " drive not ready";chr$(17):close 15 : end : rem abort on bad status
120 input " drive code already loaded y/n";dc$
130 ifdc$="y" then goto 590
140 ifdc$<>"n" then goto 150
145:
150 rem * open drive code file and get track and sector # *
170 open2,8,2,"dc.add.1541.obj"
180 print#15,"m-r"chr$(24)chr$(0)chr$(2)
190 get#15,t$:rem get track #
200 t=asc(t$+chr$(0))
210 get#15,s$:rem get sector #
220 s=asc(s$+chr$(0))
230 close2
240 print " drive code @ track"t;"sector"s
250 :
270 rem * reopen file and read load address *
275 rem * from the .obj file, it is $8100
280 rem * (129), (0) in for the ramboard *
290 print chr$(17);chr$(29);chr$(18);chr$(5);
300 print "loading";chr$(146);chr$(5);" drive code...";chr$(17)
310 open2,8,2,"#2"
320 print#15,"u1";2;0;t;s
330 print#15,"m-r"chr$(2)chr$(5)chr$(2)
340 get#15,lb$:iflb$=""thenlb$=chr$(0)
350 get#15,hb$:ifhb$=""thenhb$=chr$(0)
355 rem we now have the hb and lb
360 hb=asc(hb$):lb=asc(lb$): rem print " ";hb;lb
365 :
370 rem * create drive code array *
380 dimtf%(41)
390 fori=0to40
400 get#2,y$:ify$=""theny$=chr$(0)
410 y=asc(y$)
420 tf%(i)=y
430 ifst=64theni=256
440 nexti
450 close2:rem close15
455 :
460 rem * read array into ramboard *
465 rem * using the address from the hb and lb
470 rem * data available until power off *
490 print chr$(29);chr$(18);chr$(5);"writing";chr$(146);
500 print chr$(5);" drive code to ramboard..."
510 mw$="m"+"-"+"w"
520 fori=0to40:rem fori=1536to1681
530 x=tf%(i):rem x=tf%(i-1536)
540 rem hb=int(i/256):lb=i-(32768):rem hb=int(i/256):lb=i-(hb*256)
550 print#15,mw$+chr$(lb)chr$(hb)chr$(1)chr$(x)
560 rem print hb;lb;x
570 lb=lb+1:next i
580 close 15
590 close15:open15,8,15
595 :
600 open5,8,5,"#1"
610 print chr$(17);"enter number 0-250"
620 for i=0to7
630 input v
640 print#15,"m-w"chr$(i)chr$(3)chr$(1)chr$(v)
650 rem m-w (memory write): writes data to  
660 rem memory location in the disk drive.
650 next i
655 :
660 print chr$(17);"executing floppy program"
670 print#15,"b-e";5;0;1;0
680 print"reading from memory..."
690 print chr$(145);chr$(145);chr$(145);chr$(145);
700 print chr$(145);chr$(145);chr$(145);chr$(145);
710 print chr$(145);chr$(145);chr$(145);chr$(145)
720 for i=0to7
730 print#15,"m-r"chr$(i)chr$(3)
740 rem m-r (memory read): reads data from 
750 rem memory location in the disk drive.
740 get#15,v$:if v$="" then v$=chr$(0)
750 print tab(5);"+5 = ";asc(v$)
760 next i
770 print chr$(17)
780 close5
790 close15