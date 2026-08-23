@echo off
setlocal EnableExtensions
cd /d "%~dp0"
chcp 65001 >nul
title NexusMind Production - Base Release

echo ========================================
echo  NexusMind Production Base Release
echo ========================================
echo  1. APK DryRun (build only, no upload)
echo  2. APK build and upload
echo  3. AAB DryRun (build only, no upload)
echo  4. AAB build and upload
echo.
choice /C 1234 /N /M "Select 1, 2, 3 or 4: "
set "MENU=%ERRORLEVEL%"

if "%MENU%"=="1" set "ARTIFACT=apk"& set "DRY_ARG=-DryRun"
if "%MENU%"=="2" set "ARTIFACT=apk"& set "DRY_ARG="
if "%MENU%"=="3" set "ARTIFACT=aab"& set "DRY_ARG=-DryRun"
if "%MENU%"=="4" set "ARTIFACT=aab"& set "DRY_ARG="
if not defined ARTIFACT (
    echo [FAILED] Invalid menu selection.
    pause
    exit /b 1
)

set /p "RELEASE_VERSION=Enter versionName (for example 1.2.0): "
if not defined RELEASE_VERSION (
    echo [FAILED] versionName is required.
    pause
    exit /b 1
)

for /f %%I in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "TIMESTAMP=%%I"
set "LOG_DIR=%~dp0.release-logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "LOG_FILE=%LOG_DIR%\%TIMESTAMP%-production-base.log"

echo.
echo Log: %LOG_FILE%
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$started=$false; $code=1; try { Start-Transcript -LiteralPath '%LOG_FILE%' -Force | Out-Null; $started=$true; & '%~dp0scripts\build_android_base.ps1' -Artifact '%ARTIFACT%' -ReleaseVersion '%RELEASE_VERSION%' %DRY_ARG%; $code=0 } catch { Write-Host ('[FAILED] ' + $_.Exception.Message); Write-Host ($_ | Out-String); $code=1 } finally { if ($started) { Stop-Transcript | Out-Null } }; exit $code"
set "RESULT=%ERRORLEVEL%"

echo.
if "%RESULT%"=="0" (
    echo [SUCCESS] Production base release task completed.
) else (
    echo [FAILED] See the error above and: %LOG_FILE%
)
echo.
pause
exit /b %RESULT%
