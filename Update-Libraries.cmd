@echo off
setlocal

where py >nul 2>nul
if not errorlevel 1 (
    py -3 "%~dp0tools\update_libraries.py" %*
) else (
    python "%~dp0tools\update_libraries.py" %*
)

set "RESULT=%ERRORLEVEL%"
if not defined CI pause
exit /b %RESULT%
