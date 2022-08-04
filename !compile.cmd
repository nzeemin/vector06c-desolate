@echo off
if exist desolcate.rom del desolcate.rom
if exist desolcod0.bin del desolcod0.bin
if exist desolcod0.inc del desolcod0.inc
if exist desolcode.bin del desolcode.bin
if exist desolcode.txt del desolcode.txt
if exist desolcode.zx0 del desolcode.zx0

rem Define ESCchar to use in ANSI escape sequences
rem https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem"') do set "ESCchar=%%E"

@echo on
tools\tasm -85 -b desolcod0.asm desolcod0.bin
@if errorlevel 1 goto Failed
@echo off

dir /-c desolcod0.bin|findstr /R /C:"desolcod0.bin"

powershell -Command "(gc desolcod0.exp) -replace '.EQU', 'EQU' | Out-File -encoding ASCII desolcod0.inc"
if exist desolcod0.exp del desolcod0.exp

@echo on
tools\pasmo --w8080 desolcoda.asm desolcode.bin desolcode.txt
@if errorlevel 1 goto Failed
@echo off

findstr /B "Desolate" desolcode.txt

dir /-c desolcode.bin|findstr /R /C:"desolcode.bin"

tools\zx0.exe -c -q desolcode.bin desolcode.zx0

dir /-c desolcode.zx0|findstr /R /C:"desolcode.zx0"

copy /b desolcod0.bin+desolcode.zx0 desolate.rom >nul

dir /-c desolate.rom|findstr /R /C:"desolate.rom"

echo %ESCchar%[92mSUCCESS%ESCchar%[0m
exit

:Failed
@echo off
echo %ESCchar%[91mFAILED%ESCchar%[0m
exit /b
