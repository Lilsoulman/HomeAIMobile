@echo off
setlocal
chcp 65001 >nul
title NexusMind Staging - Dart Patch

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run_android_release.ps1" -Mode Patch -TargetEnvironment Staging
set "RESULT=%ERRORLEVEL%"

echo.
if "%RESULT%"=="0" (
    echo [SUCCESS] Staging Patch task completed.
) else (
    echo [FAILED] See the Chinese error above and the saved log file.
)
echo.
pause
exit /b %RESULT%
