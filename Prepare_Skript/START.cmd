@echo off
setlocal EnableDelayedExpansion
title Windows 11 Setup Tool v1.2 - eXpletus

:: ============================================================================
:: Windows 11 OOTB Setup Tool v1.2
:: Copyright (C) 2025 - Steve Lingner
:: Entwickelt fuer: eXpletus IT-Systemhaus
:: Web: www.eXpletus.de
:: ============================================================================

:: Variablen
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scripts\Win11-Setup.ps1"

:: Admin-Check
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [X] FEHLER: Keine Administrator-Rechte!
    echo.
    echo Bitte Rechtsklick auf START.cmd -^> "Als Administrator ausfuehren"
    echo.
    pause
    exit /b 1
)

:MAIN_MENU
cls
color 0B
echo.
echo ============================================================================
echo   Windows 11 OOTB Setup Tool v1.2 - eXpletus Edition
echo ============================================================================
echo.
echo   [1]  Modul 1: Einstieg und Backup
echo   [2]  Modul 2: Cleanup (Widgets, Pins, Desktop)
echo   [3]  Modul 3: Optik und Ergonomie
echo   [4]  Modul 4: Performance und Energieoptionen
echo   [5]  Modul 5: Software und Daten
echo   [6]  Modul 6: Runtime-Komponenten (Java, .NET, VC++)
echo   [7]  Modul 7: Funktionalitaet
echo   [8]  Modul 8: ALBIS Spezifisch
echo.
echo   [A]  ALLE Module ausfuehren (1-7)     ^<-- Mit Software
echo   [B]  LIGHT-SETUP (1-4,7-8)            ^<-- OHNE Software!
echo.
echo   [L]  Log-Datei anzeigen
echo   [Q]  Beenden
echo.
echo ============================================================================
echo.
set /p "choice=Ihre Wahl: "

if /i "%choice%"=="1" goto MODULE_1
if /i "%choice%"=="2" goto MODULE_2
if /i "%choice%"=="3" goto MODULE_3
if /i "%choice%"=="4" goto MODULE_4
if /i "%choice%"=="5" goto MODULE_5
if /i "%choice%"=="6" goto MODULE_6
if /i "%choice%"=="7" goto MODULE_7
if /i "%choice%"=="8" goto MODULE_8
if /i "%choice%"=="A" goto FULL_SETUP
if /i "%choice%"=="B" goto LIGHT_SETUP
if /i "%choice%"=="L" goto VIEW_LOGS
if /i "%choice%"=="Q" goto EXIT

echo.
echo [!] Ungueltige Auswahl!
timeout /t 2 >nul
goto MAIN_MENU

:: ============================================================================
:: KOMPLETT-SETUP
:: ============================================================================
:FULL_SETUP
cls
color 0A
echo.
echo ============================================================================
echo   KOMPLETT-SETUP - Alle Module 1-7
echo ============================================================================
echo.
set /p "confirm=Alle Module ausfuehren? (J/N): "
if /i not "%confirm%"=="J" goto MAIN_MENU

echo.
echo Starte Setup...
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
    echo [!] Setup mit Warnungen abgeschlossen
    echo     Bitte Logs pruefen: C:\CGM\Logs\
    echo.
)

pause
goto MAIN_MENU

:: ============================================================================
:: LIGHT-SETUP (Module 1-4 und 7, OHNE Software!)
:: ============================================================================
:LIGHT_SETUP
cls
color 0E
echo.
echo ============================================================================
echo   LIGHT-SETUP - Basis-Konfiguration (OHNE Software)
echo ============================================================================
echo.
echo   Module die ausgefuehrt werden:
echo.
echo   [x] Modul 1: Einstieg und Backup
echo   [x] Modul 2: Cleanup
echo   [x] Modul 3: Optik und Ergonomie
echo   [x] Modul 4: Performance
echo   [ ] Modul 5: Software          ^<-- UEBERSPRUNGEN
echo   [ ] Modul 6: Runtime           ^<-- UEBERSPRUNGEN
echo   [x] Modul 7: Funktionalitaet
echo   [x] Modul 8: ALBIS
echo.
echo ============================================================================
echo.
set /p "confirm=Light-Setup starten? (J/N): "
if /i not "%confirm%"=="J" goto MAIN_MENU

echo.
echo Starte Light-Setup...
echo.
echo ============================================================================
echo.

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -LightSetup

set ERROR_CODE=%errorLevel%

echo.
echo ============================================================================
echo   PowerShell beendet mit Exit-Code: %ERROR_CODE%
echo ============================================================================
echo.

if %ERROR_CODE% neq 0 (
    echo [!] Setup mit Warnungen abgeschlossen
    echo     Bitte Logs pruefen: C:\CGM\Logs\
    echo.
)

pause
goto MAIN_MENU

:: ============================================================================
:: EINZELNE MODULE
:: ============================================================================
:MODULE_1
cls
echo.
echo ============================================================================
echo   MODUL 1: Einstieg und Backup
echo ============================================================================
echo.
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Module 1
echo.
pause
goto MAIN_MENU

:MODULE_2
cls
echo.
echo ============================================================================
echo   MODUL 2: Cleanup
echo ============================================================================
echo.
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Module 2
echo.
pause
goto MAIN_MENU

:MODULE_3
cls
echo.
echo ============================================================================
echo   MODUL 3: Optik und Ergonomie
echo ============================================================================
echo.
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Module 3
echo.
pause
goto MAIN_MENU

:MODULE_4
cls
echo.
echo ============================================================================
echo   MODUL 4: Performance
echo ============================================================================
echo.
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Module 4
echo.
pause
goto MAIN_MENU

:MODULE_5
cls
echo.
echo ============================================================================
echo   MODUL 5: Software und Daten
echo ============================================================================
echo.
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Module 5
echo.
pause
goto MAIN_MENU

:MODULE_6
cls
echo.
echo ============================================================================
echo   MODUL 6: Runtime-Komponenten
echo ============================================================================
echo.
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Module 6
echo.
pause
goto MAIN_MENU

:MODULE_7
cls
echo.
echo ============================================================================
echo   MODUL 7: Funktionalitaet
echo ============================================================================
echo.
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Module 7
echo.
pause
goto MAIN_MENU

:MODULE_8
cls
echo.
echo ============================================================================
echo   MODUL 8: ALBIS Spezifisch
echo ============================================================================
echo.
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Module 8
echo.
pause
goto MAIN_MENU

:: ============================================================================
:: LOG ANZEIGEN
:: ============================================================================
:VIEW_LOGS
cls
echo.
echo ============================================================================
echo   LOG-DATEIEN
echo ============================================================================
echo.

if exist "C:\CGM\Logs\" (
    echo Verfuegbare Logs:
    echo.
    dir /b /o-d "C:\CGM\Logs\Win11-Setup-*.log" 2>nul
    echo.
    echo Oeffne neueste Log-Datei...
    for /f "delims=" %%i in ('dir /b /o-d "C:\CGM\Logs\Win11-Setup-*.log" 2^>nul') do (
        notepad "C:\CGM\Logs\%%i"
        goto MAIN_MENU
    )
    echo [!] Keine Log-Dateien gefunden
) else (
    echo [!] Log-Ordner existiert noch nicht
    echo     Fuehren Sie erst ein Modul aus
)

echo.
pause
goto MAIN_MENU

:: ============================================================================
:: BEENDEN
:: ============================================================================
:EXIT
cls
echo.
echo ============================================================================
echo   Setup-Tool wird beendet
echo ============================================================================
echo.
echo Danke fuer die Nutzung!
echo.
timeout /t 2 >nul
exit /b 0
