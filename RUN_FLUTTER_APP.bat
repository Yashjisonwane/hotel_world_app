@echo off
title Hotel World Mobile App - Run
echo ========================================================
echo   HOTEL WORLD MOBILE APP - RUN / TEST
echo ========================================================
echo.

set JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot
set PATH=%JAVA_HOME%\bin;D:\flutter_windows_3.50.0-stable\flutter\bin;%PATH%

cd /d "%~dp0"

echo Connected devices:
call flutter devices

echo.
echo Launching Hotel World App...
call flutter run

pause

