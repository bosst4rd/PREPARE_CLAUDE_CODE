@echo off
:: ============================================================================
:: PREPARE_CLAUDE_CODE - Windows 11 Vorbereitung
:: Start-Skript mit automatischer Admin-Erhöhung
:: ============================================================================

title Windows 11 Vorbereitung

:: Pruefe auf Admin-Rechte
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Starte als Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Wechsle in das Skript-Verzeichnis
cd /d "%~dp0"

echo ============================================
echo  Windows 11 Vorbereitung - Starte...
echo ============================================
echo.

:: Check if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo FEHLER: PowerShell nicht gefunden!
    echo Bitte PowerShell 5.1 oder hoeher installieren.
    pause
    exit /b 1
)

:: Launch the PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Scripts\Main.ps1"

:: Check exit code
if %errorlevel% neq 0 (
    echo.
    echo Anwendung mit Fehlercode beendet: %errorlevel%
    pause
)
