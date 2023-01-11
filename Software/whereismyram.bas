10 rem * checks for additional 1541 drive ram
20 rem * and at what address.
30 rem * starts at $2000 and checks 2K blocks
40 rem * to $a000.
50 rem * by https://github.com/kayto/
60 rem * code needs a bit of work to display $a000 ;)
70 print"standby, finding drive ram"
80 open 15,8,15
90 hi=0:lo=0
100 for b= 0 to 4
110 hi=hi+32: rem start at $2000 in drive memory
120 if hi=160 then goto 140
130 print"trying $";(hi/1.6);"00":goto 150
140 print"trying $ a0 00"
150 a=123
160 for i= 0 to 15: rem * runs 15 passes until failure
170 lo=lo+1:a=a+5
180 rem print"writing value:";a;"to drive memory"
190 print#15,"m-w"chr$(lo)chr$(hi)chr$(1)chr$(A)
200 print#15, "m-r"chr$(lo)chr$(hi)
210 get#15,g$:if g$="" then g$=chr$(0) 
220 g=asc(g$)
230 rem print "reading value:";g
240 if g<>a then m$="failed":goto 270
250 if g=a then m$="ok"
260 next i
270 print"memory ";m$
280 print
290 next b
300 close 15:end
