@echo off
setlocal EnableExtensions
cd /d "%~dp0"
chcp 65001 >nul
title NexusMind Staging Android Build

set "EXPECTED_BRANCH=main"
set "FLAVOR=staging"
set "VERSION_NAME=0.0.0"
set "CONFIG_FILE=config/test.json"
set "FLUTTER_EXE=D:\Flutter\flutter\bin\flutter.bat"

if not exist "%FLUTTER_EXE%" (
    for /f "delims=" %%I in ('where flutter.bat 2^>nul') do set "FLUTTER_EXE=%%I"
)
if not exist "%FLUTTER_EXE%" (
    echo [FAILED] Flutter was not found.
    pause
    exit /b 1
)
if not exist "%CONFIG_FILE%" (
    echo [FAILED] Missing %CONFIG_FILE%.
    pause
    exit /b 1
)

for /f "delims=" %%I in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%I"
if not "%CURRENT_BRANCH%"=="%EXPECTED_BRANCH%" (
    echo [FAILED] This launcher requires branch %EXPECTED_BRANCH%. Current branch: %CURRENT_BRANCH%
    pause
    exit /b 1
)
for /f "delims=" %%I in ('git status --porcelain') do set "DIRTY_WORKTREE=1"
if defined DIRTY_WORKTREE echo [WARNING] The staging build contains uncommitted local changes.

echo ========================================
echo  NexusMind Staging Android Build
echo ========================================
echo  1. Build APK
echo  2. Build AAB
echo.
choice /C 12 /N /M "Select 1 or 2: "
set "MENU=%ERRORLEVEL%"
if "%MENU%"=="1" (
    set "BUILD_COMMAND=apk"
    set "ARTIFACT_EXT=apk"
    set "SOURCE_ARTIFACT=build\app\outputs\flutter-apk\app-staging-release.apk"
)
if "%MENU%"=="2" (
    set "BUILD_COMMAND=appbundle"
    set "ARTIFACT_EXT=aab"
    set "SOURCE_ARTIFACT=build\app\outputs\bundle\stagingRelease\app-staging-release.aab"
)
if not defined BUILD_COMMAND (
    echo [FAILED] Invalid menu selection.
    pause
    exit /b 1
)

for /f %%I in ('powershell.exe -NoProfile -Command "[int64][Math]::Floor(([DateTimeOffset]::UtcNow-[DateTimeOffset]::Parse('2020-01-01T00:00:00Z')).TotalSeconds)"') do set "BUILD_NUMBER=%%I"
for /f %%I in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "TIMESTAMP=%%I"
for /f "delims=" %%I in ('git rev-parse HEAD') do set "GIT_COMMIT=%%I"
if not defined BUILD_NUMBER (
    echo [FAILED] Unable to generate buildNumber.
    pause
    exit /b 1
)
if %BUILD_NUMBER% LSS 1 (
    echo [FAILED] Invalid buildNumber: %BUILD_NUMBER%
    pause
    exit /b 1
)
if %BUILD_NUMBER% GTR 2100000000 (
    echo [FAILED] Invalid buildNumber: %BUILD_NUMBER%
    pause
    exit /b 1
)

set "FULL_VERSION=%VERSION_NAME%+%BUILD_NUMBER%"
set "LOG_DIR=%~dp0.build-logs"
set "LOG_FILE=%LOG_DIR%\%TIMESTAMP%-staging-%ARTIFACT_EXT%.log"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo.
echo Branch: %CURRENT_BRANCH%
echo Flavor: %FLAVOR%
echo Version: %FULL_VERSION%
echo Git commit: %GIT_COMMIT%
echo Log: %LOG_FILE%
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$started=$false; try { Start-Transcript -LiteralPath '%LOG_FILE%' -Force | Out-Null; $started=$true; & '%FLUTTER_EXE%' build %BUILD_COMMAND% --release --flavor %FLAVOR% --target-platform=android-arm,android-arm64,android-x64 --build-name=%VERSION_NAME% --build-number=%BUILD_NUMBER% --dart-define-from-file=%CONFIG_FILE%; $code=$LASTEXITCODE } catch { Write-Host ('[FAILED] ' + $_.Exception.Message); Write-Host ($_ | Out-String); $code=1 } finally { if ($started) { Stop-Transcript | Out-Null } }; exit $code"
set "RESULT=%ERRORLEVEL%"

if not "%RESULT%"=="0" goto :failed
if not exist "%SOURCE_ARTIFACT%" (
    echo [FAILED] Flutter returned success but the expected artifact is missing: %SOURCE_ARTIFACT%
    set "RESULT=1"
    goto :failed
)

set "ARTIFACT_DIR=%~dp0artifacts\%FLAVOR%\%FULL_VERSION%"
if not exist "%ARTIFACT_DIR%" mkdir "%ARTIFACT_DIR%"
set "TARGET_ARTIFACT=%ARTIFACT_DIR%\NexusMind-%FLAVOR%-%FULL_VERSION%.%ARTIFACT_EXT%"
copy /Y "%SOURCE_ARTIFACT%" "%TARGET_ARTIFACT%" >nul
if errorlevel 1 (
    echo [FAILED] Unable to copy the build artifact.
    set "RESULT=1"
    goto :failed
)

echo.
echo [SUCCESS] Standard Flutter build completed.
echo Artifact: %TARGET_ARTIFACT%
echo Log: %LOG_FILE%
echo.
pause
exit /b 0

:failed
echo.
echo [FAILED] Android build failed. See: %LOG_FILE%
echo.
pause
exit /b %RESULT%
