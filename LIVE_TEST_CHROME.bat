@echo off
title Hotel World Mobile App - Live Hot Reload (Chrome)
echo ========================================================
echo   HOTEL WORLD APP - LIVE CHROME PREVIEW (HOT RELOAD)
echo ========================================================
echo.
echo Instructions:
echo  1. App will open in Chrome. Press F12 and toggle "Mobile View" (Ctrl+Shift+M).
echo  2. Code me koi bhi change karein aur file save karein.
echo  3. Is terminal window me 'r' dabayein -> INSTANT HOT RELOAD (1 second me update!)
echo  4. 'R' dabayein -> Hot Restart.
echo  5. 'q' dabayein -> Quit / Stop.
echo ========================================================
echo.

set JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot
set PATH=%JAVA_HOME%\bin;D:\flutter_windows_3.50.0-stable\flutter\bin;%PATH%

cd /d "%~dp0"
call flutter run -d chrome

pause

