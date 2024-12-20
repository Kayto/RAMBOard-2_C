10 rem * based on code within the 1541-ii user guide
20 rem * modified to allow address input as hex
30 open 15,8,15
40 input"# of bytes to read (o=end)";nl
50 if nl<1 then close 15:end
60 if nl>255 then 40
70 input "enter starting address as hex";h$
80 print " "
90 ad=0
100 for i=0 to 3
110 n=asc(mid$(h$,i+1,1))-48
120 if n<10 then ad=ad+n*(16^(3-i))
130 if n>16 then ad=ad+(n-7)*(16^(3-i))
140 next i
150 print "$"h$" hex ="ad"dec"
160 ah = int(ad/256):al = ad-ah*256
170 print "high byte ="ah" low byte = "al
180 print " "
190 i=0:e=nl-1
200 for i=i to (nl-1)
210 print#15, "m-r"chr$(al)chr$(ah)chr$(1)
220 : get#15,a$:if a$="" then a$=chr$(0)
230 : a=asc(a$):print ad,a
240 :al=al+1:ad=ad+1
250 next i
260 print
270 goto 40
