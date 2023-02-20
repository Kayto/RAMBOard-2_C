10 open15,8,15
20 open5,8,5,"#1"
25 v=0
30 for i=0to199
40 rem input v
50 print#15,"m-w"chr$(i)chr$(3)chr$(1)chr$(v)
55 v=v+1
60 next i
70 print"executing floppy program"
80 print#15,"b-e";5;0;1;0
90 print"reading from memory..."
100 for i=0to199
110 print#15,"m-r"chr$(i)chr$(3)
120 get#15,v$:if v$="" then v$=chr$(0)
130 print asc(v$)
140 next i
150 close5
160 close15