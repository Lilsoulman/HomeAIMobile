@echo off
setlocal
chcp 65001 >nul
title NexusMind Staging - Dart Patch 构建与上传

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run_android_release.ps1" -Mode Patch -TargetEnvironment Staging
set "RESULT=%ERRORLEVEL%"

echo.
if "%RESULT%"=="0" (
    echo [成功] Staging Patch 任务执行完成。
) else (
    echo [失败] Staging Patch 任务执行失败，请查看上方原因和日志文件。
)
echo.
pause
exit /b %RESULT%
