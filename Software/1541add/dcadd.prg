#'� *************************** B'� * ADDITION IN THE 1541 * e$'�  *************************** �8'�"�  ADDITION IN THE 1541�" �B'�15,8,15: � THE OPEN COMMAND CHANNEL �L'�15,"IO": � INITIALISE  	V'�15,EN$,EM$,ET$,ES$ : � INPUT THE ERROR STATUS 0	`'� EN$�"00"� � 10110: � NO ERROR ENCOUNTERED q	j'� EN$","EM$","ET$","ES$ : � PRINT THE ERROR STATUS ON SCREEN �	t'�"DRIVE NOT READY":� 15 : � : � ABORT ON BAD STATUS �	~'�" DRIVE CODE ALREADY LOADED Y/N";DC$ �	�'�DC$�"Y" � � 20000 
�'�DC$��"N" � � 10160 =
�'� * OPEN DRIVE CODE FILE AND GET TRACK AND SECTOR # * C
�': `
�'�2,8,2,"DC.ADD.1541.OBJ" {
�'�15,"M-R"�(24)�(0)�(2) �
�'�#15,T$:� GET TRACK # �
�'T��(T$��(0)) �
�'�#15,S$:� GET SECTOR # �
�'S��(S$��(0)) �
 (�2  
(� " DRIVE CODE @ TRACK"T;"SECTOR"S (: (: 8((� * REOPEN FILE AND READ LOAD ADDRESS * f2(� * IN THIS CASE ITS $8000 FOR RAMBOARD * �<(�" LOADING�� DRIVE CODE..." �F(�2,8,2,"#2" �P(�15,"U1";2;0;T;S �Z(�15,"M-R"�(2)�(5)�(2) �d(�#15,LB$:�LB$�""�LB$��(0) n(�#15,HB$:�HB$�""�HB$��(0) 1x(HB��(HB$):LB��(LB$): � PRINT " ";HB;LB U�(: � * CREATE DRIVE CODE ARRAY * b�(�TF%(41) n�(�I�0�40 ��(�#2,Y$:�Y$�""�Y$��(0) ��(Y��(Y$) ��(TF%(I)�Y ��(�ST�64�I�256 ��(�I ��(�2:� CLOSE15 ��(� * READ ARRAY INTO RAMBOARD * �(� * TO BE AVAILABLE UNTIL POWER OFF * )�(� HB=128:LB=0 X�(�" WRITING�� DRIVE CODE TO RAMBOARD..." l�(MW$�"M"�"-"�"W" �)�I�0�40:� FORI=1536TO1681 �)X�TF%(I):� X=TF%(I-1536) �)� HB=INT(I/256):LB=I-(32768):REM HB=INT(I/256):LB=I-(HB*256) ")�15,MW$��(LB)�(HB)�(1)�(X) ,)� PRINT HB;LB;X +6)LB�LB�1:� I 4@)� 15 E N�15:�15,8,15 U*N�5,8,5,"#1" p/N�"ENTER NUMBER 0-250" |4N� I�0�7 �>N� V �HN�15,"M-W"�(I)�(3)�(1)�(V) �RN� I �\N�"EXECUTING FLOPPY PROGRAM" �fN�15,"B-E";5;0;1;0 �pN�"READING FROM MEMORY..." uN� "������������"  zN� I�0�7 6�N�15,"M-R"�(I)�(3) T�N�#15,V$:� V$�"" � V$��(0) l�N� �5);"+5 = ";�(V$) t�N� I ~�N� "" ��N�5 ��N�15   