05 rem * Based on code within the 1541-II user guide
06 rem * modified to allow address input as HEX
10 open 15,8,15
20 input"# of bytes to read (o=end)";NL
30 if NL<1 then close 15:end
40 if NL>255 then 20
50 INPUT "enter starting address as hex";H$
55 PRINT " "
60 AD=0
70 FOR I=0 TO 3
80 N=ASC(MID$(H$,I+1,1))-48
90 IF N<10 THEN AD=AD+N*(16^(3-I))
100 IF N>16 THEN AD=AD+(N-7)*(16^(3-I))
110 NEXT I
120 PRINT "$"H$" hex ="AD"dec"
130 AH = int(AD/256):AL = AD-AH*256
135 PRINT "high byte ="AH" low byte = "AL
138 PRINT " "
140 print#15, "m-r"chr$(AL)chr$(AH)chr$(NL)
150 for i= i to NL
160 : get#15,a$:if a$="" then a$=chr$(0)
170 : print asc(a$);
180 next i
190 print
200 goto 20
