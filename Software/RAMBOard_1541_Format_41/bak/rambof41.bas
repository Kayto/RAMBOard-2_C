!- ========================================
!- Project    RAMBOard1541FORMAT 41 Tracks (CBM prg Studio)
!- Target     Commodore 64
!- Comments   BASIC Code based on 64'er format41 adapted by AdamT117, 
!-            to use drive code stored in the RAMBOard. Requires 
!-            format.1541.obj on same .d64
!- Author     AdamT117. https://github.com/Kayto
!- ========================================
10000 rem ***************************
10010 rem * format tracks 1-41 *
10020 rem  ***************************
10030 open3,8,3,"#2"
10040 print"{clear}{down}{right}{white}  format tracks 1 to 41{light blue}{down}"
10050 open15,8,15: rem the open command channel
10060 print#15,"io": rem initialise
10070 input#15,en$,em$,et$,es$ : rem input the error status
10080 if en$="00"then goto 10110: rem no error encountered
10090 print en$","em$","et$","es$ : rem print the error status on screen
10100 print"drive not ready{down}":close 15 : end : rem abort on bad status
10110 input" drive code already loaded y/n";dc$
10120 ifdc$="y" then goto 11150
10130 ifdc$<>"n" then goto 10160
10140 :
10150 :
10160 rem * open drive code file and get track and sector # *
10170 :
10180 open2,8,2,"format.1541.obj"
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
10300 print" {down}{right}{reverse on}{white}loading{reverse off}{light blue} drive code..."
10310 open2,8,2,"#2"
10320 print#15,"u1";2;0;t;s
10330 print#15,"m-r"chr$(2)chr$(5)chr$(2)
10340 get#15,lb$:iflb$=""thenlb$=chr$(0)
10350 get#15,hb$:ifhb$=""thenhb$=chr$(0)
10360 hb=asc(hb$):lb=asc(lb$): rem print " ";hb;lb
10370 : rem * create drive code array *
10380 dimtf%(256)
10390 fori=0to256
10400 get#2,y$:ify$=""theny$=chr$(0)
10410 y=asc(y$)
10420 tf%(i)=y
10430 ifst=64theni=256:rem print y
10440 nexti
10450 close2
10460 rem * read array into ramboard *
10470 rem * to be available until power off *
10480 print" {right}{reverse on}{white}writing{reverse off}{light blue} drive code to ramboard..."
10490 mw$="m"+"-"+"w"
10500 fori=32768to32913:rem fori=1536to1681
10510 x=tf%(i-32768):rem x=tf%(i-1536)
10520 rem hb=int(i/256):lb=i-(32768):rem hb=int(i/256):lb=i-(hb*256)
10530 print#15,mw$+chr$(lb)chr$(hb)chr$(1)chr$(x)
10540 rem print hb;lb;x
10550 lb=lb+1:next i
10560 close 15
10570 :
10580 rem *** disk format
10590 :
10600 print"{down} insert blank disc in drive"
10610 print" press {reverse on}return{reverse off} to continue"
10620 getc$:ifc$=""then10620
10630 ifc$<>chr$(13)then10620
10640 input"{down} enter disc name ";n$
10650 iflen(n$)>16then10640
10660 dn$=n$
10670 input" enter disc id";n$
10680 iflen(n$)>2then10670
10690 di$=n$:ifdn$="*"then10730
10700 :
10710 :
10720 print"{up} {up} "
10730 rem *** formatting 1-35
10740 print" {up}{right}{reverse on}{white}formatting{reverse off}{light blue} tracks 1 to 35..."
10750 print"                  "
10760 open15,8,15,"n:"+dn$+","+di$
10770 close15
10780 open15,8,15
10790 
10800 :
10810 rem *** load format routine into floppy buffer
10820 :
10830 print"  {reverse on}{white}writing{reverse off}{light blue} drive code to buffer...{down}"
10840 hi=6:lo=0
10850 mw$="m"+"-"+"w"
10860 fori=32768to32913:rem fori=1536to1681
10870 x=tf%(i-32768):rem x=tf%(i-1536)
10880 hb=int(i/256):lb=i-(32768):rem hb=int(i/256):lb=i-(hb*256)
10890 print#15,mw$+chr$(lo)chr$(hi)chr$(1)chr$(x)
10900 rem print hb;lb;hi;lo;x
10910 lo=lo+1::nexti
10920 :
10930 rem *** load jump address into
10940 rem     floppy buffer
10950 :
10960 fori=36to41:print" {right}formatting track{white}";i;"{light blue}..."
10970 print#15,mw$+chr$(0)chr$(5)chr$(3)chr$(76)chr$(41)chr$(6)
10980 : rem 3 refers to the bytes needed for the jmp
10990 : rem 76-41-6 = jmp $0629
11000 :
11010 rem *** pass disk-id into
11020 rem     floppy buffer
11030 :
11040 i1$=mid$(di$,1,1):i2$=mid$(di$,2,1):i1=asc(i1$):i2=asc(i2$)
11050 print#15,mw$+chr$(3)+chr$(5)+chr$(1)+chr$(i1)
11060 print#15,mw$+chr$(4)+chr$(5)+chr$(1)+chr$(i2)
11070 :
11080 rem *** format track 36 to track 41
11090 :
11100 u3$="u"+"3"+" 3 0"+str$(i)+" 00"
11110 print#15,u3$:input#15,f,ft$,t,s:iffthenprintu3$;f;ft$;t;s
11120 next
11130 close15:close3:end
11140 :
11150 print"{down}{right} {white}{reverse on}reading{reverse off}{light blue} stored code from ramboard..."
11160 rem * read drive code stored in ramboard back to array *
11170 dimtf%(256):hi=128:lo=0:hb=128:lb=0
11180 close15:open15,8,15
11190 for i =0to255
11200 print#15,"m-r"chr$(lo)chr$(hi)chr$(1)
11210 get#15,z$:ifz$=""thenz$=chr$(0)
11220 z=asc(z$)
11230 rem print hi;lo;z
11240 tf%(i)=z:lo=lo+1
11250 if st=64theni=256
11260 next i
11270 close15
11280 goto 10580



