10 rem *checks for additional 1541 drive
20 rem *ram drive ram and at what address.
30 rem *starts at $2000 and checks 
40 rem *2k blocks to $a000.
50 rem *by https://github.com/kayto/
60 gosub 310
65 print:close 15
70 print"standby, finding drive ram"
80 open 15,8,15
90 hi=0:lo=1
100 for b= 0 to 4
110 hi=hi+32: rem start at $2000 in drive memory
120 if hi=160 then goto 140
130 print" trying $";(hi/1.6);"00":goto 150
140 print" trying $ a0 00"
150 a=111
160 for i= 0 to 9: rem * runs 10 passes until failure
170 a=a+5
180 rem print"writing value:";a;"to drive memory"
190 print#15,"m-w"chr$(lo)chr$(hi)chr$(1)chr$(a)
200 print#15, "m-r"chr$(lo)chr$(hi)
210 get#15,g$:if g$="" then g$=chr$(0) 
220 g=asc(g$)
230 rem print "reading value:";g
240 if g<>a then m$="not found":goto 270
250 if g=a then m$="found"
260 next i
270 print" memory ";m$
280 print
290 next b
300 close 15:end
310 OPEN 15,8,15 : REM THE OPEN COMMAND CHANNEL
500 INPUT#15,EN,EM$,ET,ES : REM INPUT THE ERROR STATUS
510 IF EN < 20 THEN RETURN : REM NO ERROR ENCOUNTERED
520 PRINT EN;EM$;ET;ES : goto 65:REM PRINT THE ERROR STATUS ON SCREEN
530 CLOSE 15 : END : REM ABORT ON BAD STATUS
