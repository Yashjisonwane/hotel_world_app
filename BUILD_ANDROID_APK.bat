@echo off
title Hotel World - Build Release APK
echo ========================================================
echo   HOTEL WORLD MOBILE APP - ANDROID RELEASE APK BUILDER
echo ========================================================
echo.

set JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot
set PATH=%JAVA_HOME%\bin;D:\flutter_windows_3.50.0-stable\flutter\bin;%PATH%

cd /d "%~dp0"

echo [1/3] Checking Flutter and Android environment...
flutter --version
if errorlevel 1 (
    echo [ERROR] Flutter not found!
    pause
    exit /b 1
)

echo.
echo [2/3] Getting latest pub dependencies...
call flutter pub get

echo.
echo [3/3] Compiling Release APK (Self-contained, installable on any Android phone)...
call flutter build apk --release

if errorlevel 1 (
    echo.
    echo [ERROR] APK build failed. Check the error log above.
    pause
    exit /b 1
)

echo.
echo ========================================================
echo   SUCCESS! Release APK is ready:
echo   build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
echo.
pause

