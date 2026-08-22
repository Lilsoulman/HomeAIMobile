@echo off
if not "%NEXUS_SHOREBIRD_CAPTURE_FILE%"=="" echo %*>>"%NEXUS_SHOREBIRD_CAPTURE_FILE%"
if "%1"=="--json" if "%2"=="releases" echo {"status":"success","data":{"releases":[]}}
if "%1"=="--json" if "%2"=="patches" echo {"status":"success","data":{"patches":[]}}
exit /b 0
