10 open 15,8,15
20 rem print#15,"b-a";0;1;0
30 rem input#15,en,em$,et,es
40 rem printen;em$;et;es
50 open2,8,2,"#"
60 print#15,"u1";2;0;1;0
70 print#15,"b-p";2;0
80 for i=1to35
90 read d
100 print#2,chr$(d);
110 nexti
120 print#15,"u2";2;0;1;0
130 close2
140 close15
150 end
500 data165,180,72,165,181,72,169,0,133
510 data180,169,3,133,181,160,0,24,169
520 data5,113,180,145,180,200,192,199,208
530 data244,104,133,181,104,133,180,96
