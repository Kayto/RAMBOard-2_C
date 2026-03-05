10 rem *checks for additional 1541 drive
20 rem *ram drive ram and at what address.
30 rem *starts at $2000 and checks 
40 rem *2k blocks to $a000.
50 rem *by https://github.com/kayto/
60 a=0:lo=0:count=0
70 print chr$(147)
80 print chr$(5);" where is my extra 1541 ram?";chr$(154);chr$(17)
90 print " standby, finding drive ram..."
100 open 15,8,15 : rem the open command channel
110 input#15,en,em$,et,es : rem input the error status
120 print en;em$;et;es;chr$(17): goto 130:rem print the status on screen
125 print chr$(17) 
130 rem open 15,8,15
140 hi=0:if count=19 then hi=0
150 for b= 0 to 4
160 hi=hi+32: rem start at $2000 in drive memory
170 if hi=160 then goto 190
180 print " trying $";(hi/1.6*100):goto 200
190 print" trying $ a000"
200 for i= 0 to 25: rem * runs 25 passes until failure
210 a=a+2:if a>255 then a=0:if lo>255 then lo=0
220 print#15,"m-w"chr$(lo)chr$(hi)chr$(1)chr$(a)
230 print#15, "m-r"chr$(lo)chr$(hi)
240 get#15,g$:if g$="" then g$=chr$(0) 
250 g=asc(g$)
260 rem print "reading value:";g
270 if g<>a then m$="not found":goto 310
275 :
280 if g=a then m$="found"
285 :
290 lo=lo+3:if lo>255 then lo=0
300 next i
305 print chr$(5);chr$(18);chr$(145)
310 print" memory ";m$
315 print chr$(146);chr$(154)
330 next b
340 close15:input"check again y/n";y$
350 count = count+1
360 if y$="y"then a=a+2:rem increments data byte
370 if y$="y"then hi=hi+1:rem increments high byte
380 if y$="y" then lo=lo+25:goto 70:rem increments lo byte
390 close15:end
