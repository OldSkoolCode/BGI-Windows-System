@ECHO OFF
ECHO OFF

:AGAIN
  GO-MENU START.MNU 0 GO-MENU.MSV
  IF ERRORLEVEL 10 GOTO QUIT
  IF ERRORLEVEL  8 GOTO VENDINF
  IF ERRORLEVEL  7 GOTO AMAZEFRM
  IF ERRORLEVEL  6 GOTO AMAZEINF
  IF ERRORLEVEL  4 GOTO GOHIST
  IF ERRORLEVEL  3 GOTO GOFRM
  IF ERRORLEVEL  2 GOTO GODOC
  IF ERRORLEVEL  1 GOTO OVERVIEW

:VENDINF
  SEE VENDOR.DOC
  GOTO AGAIN

:AMAZEFRM
  SEE AMAZE.TXT
  GOTO AGAIN

:AMAZEINF
  SEE AMAZE.DOC
  GOTO AGAIN

:GOHIST
  SEE CHANGE.LOG
  GOTO AGAIN

:GOFRM
  SEE GO-FORM.DAT
  GOTO AGAIN

:GODOC
  SEE GO.INF
  GOTO AGAIN

:OVERVIEW
  SEE INT.INF
  GOTO AGAIN

:QUIT
  ECHO �������������������������������������������������������������������������������
  ECHO �  ��������������� SHAREWARE *LOWERS* THE PRICE OF SOFTWARE! ���������������  �
  ECHO �������������������������������������������������������������������������������
  ECHO �                                                                             �
  ECHO �  *YOU* can help keep shareware growing:  give a copy of "GO" to somebody,   �
  ECHO �  or upload it to a BBS.  That's how to make shareware work for all of us.   �
  ECHO �                                                                             �
  ECHO �������������������������������������������������������������������������������
  ECHO �      IF YOU VALUE SHAREWARE, PLEASE SUPPORT THE AUTHORS -- BY SHARING       �
  ECHO �������������������������������������������������������������������������������


