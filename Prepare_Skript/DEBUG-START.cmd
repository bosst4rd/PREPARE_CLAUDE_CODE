@echo off
setlocal EnableDelayedExpansion

:: Debug-Modus
echo ============================================================================
echo   DEBUG: Windows 11 Setup Tool Starter
echo ============================================================================
echo.

:: Admin-Check
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [X] Keine Admin-Rechte!
    pause
    exit /b 1
)
echo [OK] Admin-Rechte vorhanden
echo.

:: Pfade prüfen
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scripts\Win11-Setup.ps1"

echo Skript-Verzeichnis: %SCRIPT_DIR%
echo PowerShell-Skript: %PS_SCRIPT%
echo.

if not exist "%PS_SCRIPT%" (
    echo [X] FEHLER: PowerShell-Skript nicht gefunden!
    echo    Pfad: %PS_SCRIPT%
    echo.
    pause
    exit /b 1
)
echo [OK] PowerShell-Skript gefunden
echo.

echo Starte PowerShell-Skript mit -RunAll Parameter...
echo.
echo ============================================================================
echo.

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -RunAll

set ERROR_CODE=%errorLevel%

echo.
echo ============================================================================
echo   PowerShell beendet mit Exit-Code: %ERROR_CODE%
echo ============================================================================
echo.

if %ERROR_CODE% neq 0 (
    echo [!] Es ist ein Fehler aufgetreten!
    echo     Bitte Screenshot machen und Fehler melden.
)

pause
