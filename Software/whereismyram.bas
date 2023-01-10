10 rem * Checks for additional 1541 drive RAM
20 rem * and at what address.
30 rem * Starts at $2000 and checks 2K blocks
40 rem * to $A000.
50 rem * by https://github.com/Kayto/
60 rem * code needs a bit of work to display $A000 ;)
70 print"standby, finding drive ram"
80 open 15,8,15
90 hi=0:lo=0
100 for b= 0 to 4
110 hi=hi+32: rem start at $2000 in drive memory
120 print"trying $";(hi/1.6);"00"
130 A=123
140 for i= 0 to 15: rem * runs 15 passes until failure
150 lo=lo+1:A=A+5
160 rem print"writing value:";A;"to drive memory"
170 print#15,"m-w"chr$(lo)chr$(hi)chr$(1)chr$(A)
180 print#15, "m-r"chr$(lo)chr$(hi)
190 get#15,g$:if g$="" then g$=chr$(0) 
200 g=asc(g$)
210 rem print "reading value:";g
220 if g<>A then m$="failed":goto 250
230 if g=A then m$="ok"
240 next i
250 print"memory ";m$
260 print
270 next b
280 close 15:end
