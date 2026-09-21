@echo off
setlocal
if "%MASM32%"=="" set MASM32=C:\masm32
set PATH=%MASM32%\bin;%PATH%
set LIB=%MASM32%\lib

ml /c /coff /Cp justquest.asm
if errorlevel 1 goto :err

link /subsystem:console /entry:mainCRTStartup /nodefaultlib ^
     /LIBPATH:"%MASM32%\lib" ^
     justquest.obj kernel32.lib
if errorlevel 1 goto :err

echo Built: justquest.exe
pause

:err
echo BUILD FAILED
pause