05 rem * based on code within the 1541-ii user guide
06 rem * modified to allow address input as hex
10 open 15,8,15
20 input"# of bytes to read (o=end)";nl
30 if nl<1 then close 15:end
40 if nl>256 then 20
50 input "enter starting address as hex";h$
55 print " "
60 ad=0
70 for i=0 to 3
80 n=asc(mid$(h$,i+1,1))-48
90 if n<10 then ad=ad+n*(16^(3-i))
100 if n>16 then ad=ad+(n-7)*(16^(3-i))
110 next i
120 print "$"h$" hex ="ad"dec"
130 ah = int(ad/256):al = ad-ah*256
135 print "high byte ="ah" low byte = "al
138 print " "
140 print#15, "m-r"chr$(al)chr$(ah)chr$(nl)
150 i=0: for i= i to nl-1
160 : get#15,a$:if a$="" then a$=chr$(0)
170 : print asc(a$);
180 next i
190 print
200 goto 20
