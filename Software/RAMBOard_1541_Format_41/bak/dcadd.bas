10000 rem ***************************
10010 rem * addition in the 1541 *
10020 rem  ***************************

10040 print"{clear}{down}{right}{white}  addition in the 1541{light blue}{down}"
10050 open15,8,15: rem the open command channel
10060 print#15,"io": rem initialise
10070 input#15,en$,em$,et$,es$ : rem input the error status
10080 if en$="00"then goto 10110: rem no error encountered
10090 print en$","em$","et$","es$ : rem print the error status on screen
10100 print"drive not ready{down}":close 15 : end : rem abort on bad status
10110 input" drive code already loaded y/n";dc$
10120 ifdc$="y" then goto 20000
10130 ifdc$<>"n" then goto 10160

10160 rem * open drive code file and get track and sector # *
10170 :
10180 open2,8,2,"dc.add.1541.obj"
10190 print#15,"m-r"chr$(24)chr$(0)chr$(2)
10200 get#15,t$:rem get track #
10210 t=asc(t$+chr$(0))
10220 get#15,s$:rem get sector #
10230 s=asc(s$+chr$(0))
10240 close2
10250 print " drive code @ track"t;"sector"s
10260 :
10270 : 
10280 rem * reopen file and read load address *
10290 rem * in this case its $8000 for ramboard *
10300 print" {down}{right}{reverse on}{white}loading{reverse off}{light blue} drive code...{down}"
10310 open2,8,2,"#2"
10320 print#15,"u1";2;0;t;s
10330 print#15,"m-r"chr$(2)chr$(5)chr$(2)
10340 get#15,lb$:iflb$=""thenlb$=chr$(0)
10350 get#15,hb$:ifhb$=""thenhb$=chr$(0)
10360 hb=asc(hb$):lb=asc(lb$): rem print " ";hb;lb
10370 : rem * create drive code array *
10380 dimtf%(41)
10390 fori=0to40
10400 get#2,y$:ify$=""theny$=chr$(0)
10410 y=asc(y$)
10420 tf%(i)=y
10430 ifst=64theni=256
10440 nexti
10450 close2:rem close15
10460 rem * read array into ramboard *
10470 rem * to be available until power off *
10475 rem hb=128:lb=0
10480 print" {right}{reverse on}{white}writing{reverse off}{light blue} drive code to ramboard..."
10490 mw$="m"+"-"+"w"
10500 fori=0to40:rem fori=1536to1681
10510 x=tf%(i):rem x=tf%(i-1536)
10520 rem hb=int(i/256):lb=i-(32768):rem hb=int(i/256):lb=i-(hb*256)
10530 print#15,mw$+chr$(lb)chr$(hb)chr$(1)chr$(x)
10540 rem print hb;lb;x
10550 lb=lb+1:next i
10560 close 15


20000 close15:open15,8,15
20010 open5,8,5,"#1"
20015 print"{down}enter number 0-250"
20020 for i=0to7
20030 input v
20040 print#15,"m-w"chr$(i)chr$(3)chr$(1)chr$(v)
20050 next i
20060 print"{down}executing floppy program"
20070 print#15,"b-e";5;0;1;0
20080 print"reading from memory..."
20085 print "{up*12}"
20090 for i=0to7
20100 print#15,"m-r"chr$(i)chr$(3)
20110 get#15,v$:if v$="" then v$=chr$(0)
20120 print tab(5);"+5 = ";asc(v$)
20130 next i
20135 print "{down}"
20140 close5
20150 close15