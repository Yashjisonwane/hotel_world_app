@echo off
title Hotel World Mobile App - Live Phone USB Hot Reload
echo ========================================================
echo   HOTEL WORLD APP - LIVE ON REAL ANDROID PHONE (USB)
echo ========================================================
echo.
echo Setup Steps (Sirf pehli baar):
echo  1. Apne Android phone ko USB cable se PC se connect karein.
echo  2. Phone me "Developer Options" on karein -> "USB Debugging" ko ON karein.
echo  3. Phone par pop-up aayega: "Allow USB Debugging?" -> "Always allow" par check karke OK karein.
echo.
echo Hot Reload Feature:
echo  - Phone par app chalte hue code me jo bhi change karoge:
echo  - Is terminal me sirf 'r' dabayein -> Phone ki screen par turant 1 second me LIVE change dikhega!
echo ========================================================
echo.

set JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot
set PATH=%JAVA_HOME%\bin;D:\flutter_windows_3.50.0-stable\flutter\bin;C:\Android\Sdk\platform-tools;%PATH%

cd /d "%~dp0"
call flutter run

pause

