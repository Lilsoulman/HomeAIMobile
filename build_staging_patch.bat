@echo off
setlocal EnableExtensions
cd /d "%~dp0"
chcp 65001 >nul
title NexusMind Staging - Dart Patch

echo ========================================
echo  NexusMind Staging Dart Patch
echo ========================================
echo  1. Patch DryRun (build only, no upload)
echo  2. Build and upload Patch
echo.
choice /C 12 /N /M "Select 1 or 2: "
set "MENU=%ERRORLEVEL%"

if "%MENU%"=="1" set "DRY_ARG=-DryRun"
if "%MENU%"=="2" set "DRY_ARG="
if not "%MENU%"=="1" if not "%MENU%"=="2" (
    echo [FAILED] Invalid menu selection.
    pause
    exit /b 1
)

for /f %%I in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "TIMESTAMP=%%I"
set "LOG_DIR=%~dp0.release-logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "LOG_FILE=%LOG_DIR%\%TIMESTAMP%-staging-patch.log"

echo.
echo Log: %LOG_FILE%
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$started=$false; $code=1; try { Start-Transcript -LiteralPath '%LOG_FILE%' -Force | Out-Null; $started=$true; & '%~dp0scripts\build_android_patch.ps1' %DRY_ARG%; $code=0 } catch { Write-Host ('[FAILED] ' + $_.Exception.Message); Write-Host ($_ | Out-String); $code=1 } finally { if ($started) { Stop-Transcript | Out-Null } }; exit $code"
set "RESULT=%ERRORLEVEL%"

echo.
if "%RESULT%"=="0" (
    echo [SUCCESS] Staging Patch task completed.
) else (
    echo [FAILED] See the error above and: %LOG_FILE%
)
echo.
pause
exit /b %RESULT%
