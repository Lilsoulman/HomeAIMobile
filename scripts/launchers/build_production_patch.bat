@echo off
setlocal
chcp 65001 >nul
title NexusMind Production - Dart Patch 构建与上传

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run_android_release.ps1" -Mode Patch -TargetEnvironment Production
set "RESULT=%ERRORLEVEL%"

echo.
if "%RESULT%"=="0" (
    echo [成功] Production Patch 任务执行完成。
) else (
    echo [失败] Production Patch 任务执行失败，请查看上方原因和日志文件。
)
echo.
pause
exit /b %RESULT%
