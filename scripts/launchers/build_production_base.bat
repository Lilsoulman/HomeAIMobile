@echo off
setlocal
chcp 65001 >nul
title NexusMind Production - 底包构建与上传

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run_android_release.ps1" -Mode Base -TargetEnvironment Production
set "RESULT=%ERRORLEVEL%"

echo.
if "%RESULT%"=="0" (
    echo [成功] Production 底包任务执行完成。
) else (
    echo [失败] Production 底包任务执行失败，请查看上方原因和日志文件。
)
echo.
pause
exit /b %RESULT%
