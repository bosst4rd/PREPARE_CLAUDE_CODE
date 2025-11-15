@echo off
REM PowerShell GUI Tool Launcher
REM Quick start batch file for Windows

echo Starting PowerShell GUI Tool...
echo.

REM Check if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: PowerShell not found!
    echo Please install PowerShell 5.1 or higher.
    pause
    exit /b 1
)

REM Launch the PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Main.ps1"

REM Check exit code
if %errorlevel% neq 0 (
    echo.
    echo Application exited with error code: %errorlevel%
    pause
)
