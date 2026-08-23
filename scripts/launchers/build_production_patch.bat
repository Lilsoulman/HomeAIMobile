@echo off
setlocal
chcp 65001 >nul
title NexusMind Production - Dart Patch

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run_android_release.ps1" -Mode Patch -TargetEnvironment Production
set "RESULT=%ERRORLEVEL%"

echo.
if "%RESULT%"=="0" (
    echo [SUCCESS] Production Patch task completed.
) else (
    echo [FAILED] See the Chinese error above and the saved log file.
)
echo.
pause
exit /b %RESULT%
