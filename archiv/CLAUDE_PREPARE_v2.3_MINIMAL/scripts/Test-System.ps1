#Requires -RunAsAdministrator
<#
.SYNOPSIS
    System-Pruefung vor Windows 11 Setup
.DESCRIPTION
    Prueft ob das System bereit fuer das Setup ist
#>

Clear-Host

Write-Host @"
╔════════════════════════════════════════════════════════════════════════════╗
║              Windows 11 Setup - System-Check                               ║
╚════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$checks = @()

# Admin-Rechte
Write-Host "Pruefe Administrator-Rechte..." -NoNewline
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host " [OK]" -ForegroundColor Green
    $checks += @{Name="Admin-Rechte"; Status=$true}
} else {
    Write-Host " [X]" -ForegroundColor Red
    $checks += @{Name="Admin-Rechte"; Status=$false}
}

# PowerShell Version
Write-Host "Pruefe PowerShell Version..." -NoNewline
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5) {
    Write-Host " [OK] (v$psVersion)" -ForegroundColor Green
    $checks += @{Name="PowerShell"; Status=$true}
} else {
    Write-Host " [X] (v$psVersion - mindestens v5 erforderlich)" -ForegroundColor Red
    $checks += @{Name="PowerShell"; Status=$false}
}

# Windows Version
Write-Host "Pruefe Windows Version..." -NoNewline
$os = Get-CimInstance Win32_OperatingSystem
$osName = $os.Caption
if ($osName -like "*Windows 11*") {
    Write-Host " [OK] ($osName)" -ForegroundColor Green
    $checks += @{Name="Windows 11"; Status=$true}
} else {
    Write-Host " [!] ($osName - Windows 11 empfohlen)" -ForegroundColor Yellow
    $checks += @{Name="Windows 11"; Status=$true}
}

# Build Nummer
Write-Host "Pruefe Build-Nummer..." -NoNewline
$buildNumber = $os.BuildNumber
if ($buildNumber -ge 22000) {
    Write-Host " [OK] (Build $buildNumber)" -ForegroundColor Green
    $checks += @{Name="Build-Nummer"; Status=$true}
} else {
    Write-Host " [!] (Build $buildNumber - moeglicherweise nicht Windows 11)" -ForegroundColor Yellow
    $checks += @{Name="Build-Nummer"; Status=$true}
}

# Execution Policy
Write-Host "Pruefe Execution Policy..." -NoNewline
$execPolicy = Get-ExecutionPolicy -Scope Process
if ($execPolicy -ne 'Restricted') {
    Write-Host " [OK] ($execPolicy)" -ForegroundColor Green
    $checks += @{Name="Execution Policy"; Status=$true}
} else {
    Write-Host " [!] ($execPolicy - wird temporaer umgangen)" -ForegroundColor Yellow
    $checks += @{Name="Execution Policy"; Status=$true}
}

# Freier Speicherplatz
Write-Host "Pruefe freien Speicherplatz..." -NoNewline
$disk = Get-PSDrive C
$freeGB = [math]::Round($disk.Free / 1GB, 2)
if ($freeGB -gt 10) {
    Write-Host " [OK] ($freeGB GB frei)" -ForegroundColor Green
    $checks += @{Name="Speicherplatz"; Status=$true}
} else {
    Write-Host " [!] ($freeGB GB frei - wenig Platz)" -ForegroundColor Yellow
    $checks += @{Name="Speicherplatz"; Status=$true}
}

# Internet-Verbindung (optional)
Write-Host "Pruefe Internet-Verbindung..." -NoNewline
try {
    $ping = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
    if ($ping) {
        Write-Host " [OK]" -ForegroundColor Green
        $checks += @{Name="Internet"; Status=$true}
    } else {
        Write-Host " [!] (Offline - fuer Modul 5+ benoetigt)" -ForegroundColor Yellow
        $checks += @{Name="Internet"; Status=$true}
    }
} catch {
    Write-Host " [!] (Nicht pruefbar)" -ForegroundColor Yellow
    $checks += @{Name="Internet"; Status=$true}
}

# Registry-Zugriff
Write-Host "Pruefe Registry-Zugriff..." -NoNewline
try {
    $testPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
    $test = Get-ItemProperty -Path $testPath -ErrorAction Stop
    Write-Host " [OK]" -ForegroundColor Green
    $checks += @{Name="Registry"; Status=$true}
} catch {
    Write-Host " [X]" -ForegroundColor Red
    $checks += @{Name="Registry"; Status=$false}
}

# System-Informationen
Write-Host "`n$('='*80)" -ForegroundColor Cyan
Write-Host "System-Informationen:" -ForegroundColor Cyan
Write-Host "$('='*80)" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME"
Write-Host "Benutzer: $env:USERNAME"
Write-Host "OS: $osName"
Write-Host "Build: $buildNumber"
Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
Write-Host "Architektur: $($os.OSArchitecture)"
Write-Host "Installationsdatum: $($os.InstallDate.ToString('dd.MM.yyyy'))"

# Zusammenfassung
Write-Host "`n$('='*80)" -ForegroundColor Cyan
$failedChecks = $checks | Where-Object { -not $_.Status }
if ($failedChecks.Count -eq 0) {
    Write-Host "[OK] SYSTEM BEREIT FUeR SETUP!" -ForegroundColor Green
    Write-Host "`nSie koennen jetzt das Setup ausfuehren:" -ForegroundColor White
    Write-Host "  .\Win11-Setup-Complete.ps1" -ForegroundColor Yellow
} else {
    Write-Host "[X] SYSTEM NICHT BEREIT!" -ForegroundColor Red
    Write-Host "`nFehlgeschlagene Pruefungen:" -ForegroundColor Red
    $failedChecks | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Red
    }
}
Write-Host "$('='*80)" -ForegroundColor Cyan

# Wartezeit
Write-Host "`n"
Read-Host "Druecken Sie Enter zum Beenden"
