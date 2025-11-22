#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Diagnose-Tool fuer Windows 11 Setup
.DESCRIPTION
    Analysiert den aktuellen Zustand und findet Probleme
#>

Clear-Host

Write-Host @"
╔════════════════════════════════════════════════════════════════════════════╗
║              Windows 11 Setup - Diagnose-Tool                              ║
╚════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

function Test-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Description
    )
    
    Write-Host "Pruefe: $Description..." -NoNewline
    try {
        if (Test-Path $Path) {
            $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($null -ne $value) {
                Write-Host " [OK] (Wert: $($value.$Name))" -ForegroundColor Green
                return $true
            } else {
                Write-Host " [X] (Wert nicht gefunden)" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host " [X] (Pfad existiert nicht)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host " [X] (Fehler: $_)" -ForegroundColor Red
        return $false
    }
}

# ==============================================================================
# MODUL 2 CHECKS
# ==============================================================================
Write-Host "`n=== MODUL 2: CLEANUP ===" -ForegroundColor Yellow

$m2checks = @()

# Widgets
$m2checks += Test-RegistryValue `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "TaskbarDa" `
    -Description "Widgets deaktiviert (TaskbarDa = 0)"

# Wetter
$m2checks += Test-RegistryValue `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" `
    -Name "ShellFeedsTaskbarViewMode" `
    -Description "Wetter deaktiviert (ShellFeedsTaskbarViewMode = 2)"

# Copilot
$m2checks += Test-RegistryValue `
    -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" `
    -Name "TurnOffWindowsCopilot" `
    -Description "Copilot deaktiviert (TurnOffWindowsCopilot = 1)"

# Suche
$m2checks += Test-RegistryValue `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
    -Name "SearchboxTaskbarMode" `
    -Description "Suche deaktiviert (SearchboxTaskbarMode = 0)"

# Desktop-Verknuepfungen
Write-Host "Pruefe: Desktop bereinigt..." -NoNewline
$desktop = [Environment]::GetFolderPath('Desktop')
$unwantedShortcuts = @('Microsoft Edge.lnk', 'Benutzer.lnk', 'Geraete.lnk')
$found = $false
foreach ($shortcut in $unwantedShortcuts) {
    if (Test-Path (Join-Path $desktop $shortcut)) {
        $found = $true
        break
    }
}
if (-not $found) {
    Write-Host " [OK]" -ForegroundColor Green
    $m2checks += $true
} else {
    Write-Host " [X] (Unerwuenschte Verknuepfungen vorhanden)" -ForegroundColor Red
    $m2checks += $false
}

# Drucker
Write-Host "Pruefe: Unerwuenschte Drucker entfernt..." -NoNewline
$fax = Get-Printer -Name "Fax" -ErrorAction SilentlyContinue
$xps = Get-Printer -Name "Microsoft XPS Document Writer" -ErrorAction SilentlyContinue
if (-not $fax -and -not $xps) {
    Write-Host " [OK]" -ForegroundColor Green
    $m2checks += $true
} else {
    Write-Host " [X] (Fax/XPS noch vorhanden)" -ForegroundColor Red
    $m2checks += $false
}

# ==============================================================================
# MODUL 3 CHECKS
# ==============================================================================
Write-Host "`n=== MODUL 3: OPTIK und ERGONOMIE ===" -ForegroundColor Yellow

$m3checks = @()

# Taskleiste links
$m3checks += Test-RegistryValue `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "TaskbarAl" `
    -Description "Taskleiste links (TaskbarAl = 0)"

# Dateierweiterungen
$m3checks += Test-RegistryValue `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "HideFileExt" `
    -Description "Dateierweiterungen sichtbar (HideFileExt = 0)"

# Nie gruppieren
$m3checks += Test-RegistryValue `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "TaskbarGlomLevel" `
    -Description "Nie gruppieren (TaskbarGlomLevel = 2)"

# Lockscreen
$m3checks += Test-RegistryValue `
    -Path "HKCU:\Software\Policies\Microsoft\Windows\Personalization" `
    -Name "NoLockScreen" `
    -Description "Lockscreen deaktiviert (NoLockScreen = 1)"

# Bildschirmschoner
$m3checks += Test-RegistryValue `
    -Path "HKCU:\Control Panel\Desktop" `
    -Name "ScreenSaveActive" `
    -Description "Bildschirmschoner deaktiviert (ScreenSaveActive = 0)"

# ==============================================================================
# MODUL 4 CHECKS
# ==============================================================================
Write-Host "`n=== MODUL 4: PERFORMANCE ===" -ForegroundColor Yellow

$m4checks = @()

# Schnellstart
$m4checks += Test-RegistryValue `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" `
    -Name "HiberbootEnabled" `
    -Description "Schnellstart deaktiviert (HiberbootEnabled = 0)"

# Hibernate
Write-Host "Pruefe: Ruhezustand deaktiviert..." -NoNewline
if (Test-Path "C:\hiberfil.sys") {
    Write-Host " [X] (hiberfil.sys existiert noch)" -ForegroundColor Red
    $m4checks += $false
} else {
    Write-Host " [OK]" -ForegroundColor Green
    $m4checks += $true
}

# Energieschema
Write-Host "Pruefe: Energieschema..." -NoNewline
$activeScheme = (powercfg /getactivescheme) -replace '.*GUID: ([a-f0-9-]+).*','$1'
if ($activeScheme -eq '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c') {
    Write-Host " [OK] (Hoechstleistung aktiv)" -ForegroundColor Green
    $m4checks += $true
} else {
    Write-Host " [!] (Nicht Hoechstleistung: $activeScheme)" -ForegroundColor Yellow
    $m4checks += $true
}

# Autostart
Write-Host "Pruefe: Autostart bereinigt..." -NoNewline
$runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$items = Get-ItemProperty -Path $runPath -ErrorAction SilentlyContinue
$unwanted = @('OneDrive', 'Teams', 'Skype')
$found = $false
if ($items) {
    foreach ($program in $unwanted) {
        $items.PSObject.Properties | Where-Object { $_.Name -like "*$program*" } | ForEach-Object {
            $found = $true
        }
    }
}
if (-not $found) {
    Write-Host " [OK]" -ForegroundColor Green
    $m4checks += $true
} else {
    Write-Host " [X] (Unerwuenschte Programme im Autostart)" -ForegroundColor Red
    $m4checks += $false
}

# ==============================================================================
# ZUSAMMENFASSUNG
# ==============================================================================
Write-Host "`n$('='*80)" -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG" -ForegroundColor Cyan
Write-Host "$('='*80)" -ForegroundColor Cyan

$m2success = ($m2checks | Where-Object { $_ -eq $true }).Count
$m2total = $m2checks.Count
$m3success = ($m3checks | Where-Object { $_ -eq $true }).Count
$m3total = $m3checks.Count
$m4success = ($m4checks | Where-Object { $_ -eq $true }).Count
$m4total = $m4checks.Count

Write-Host "`nModul 2 (Cleanup):         $m2success/$m2total Checks erfolgreich" -ForegroundColor $(if($m2success -eq $m2total){'Green'}else{'Yellow'})
Write-Host "Modul 3 (Optik):           $m3success/$m3total Checks erfolgreich" -ForegroundColor $(if($m3success -eq $m3total){'Green'}else{'Yellow'})
Write-Host "Modul 4 (Performance):     $m4success/$m4total Checks erfolgreich" -ForegroundColor $(if($m4success -eq $m4total){'Green'}else{'Yellow'})

$totalSuccess = $m2success + $m3success + $m4success
$totalChecks = $m2total + $m3total + $m4total
$percentage = [math]::Round(($totalSuccess / $totalChecks) * 100, 1)

Write-Host "`nGESAMT: $totalSuccess/$totalChecks Checks erfolgreich ($percentage%)" -ForegroundColor $(if($percentage -ge 90){'Green'}elseif($percentage -ge 70){'Yellow'}else{'Red'})

if ($percentage -eq 100) {
    Write-Host "`n[OK] PERFEKT! Alle Einstellungen korrekt angewendet." -ForegroundColor Green
} elseif ($percentage -ge 90) {
    Write-Host "`n[OK] GUT! Fast alle Einstellungen korrekt." -ForegroundColor Green
    Write-Host "Pruefe die Log-Dateien fuer Details." -ForegroundColor Yellow
} elseif ($percentage -ge 70) {
    Write-Host "`n[!] TEILWEISE! Einige Einstellungen fehlen." -ForegroundColor Yellow
    Write-Host "Fuehre das Setup erneut aus oder pruefe die Logs." -ForegroundColor Yellow
} else {
    Write-Host "`n[X] PROBLEME! Viele Einstellungen fehlen." -ForegroundColor Red
    Write-Host "Setup erneut ausfuehren oder manuell pruefen!" -ForegroundColor Red
}

# ==============================================================================
# LOG-DATEIEN
# ==============================================================================
Write-Host "`n$('='*80)" -ForegroundColor Cyan
Write-Host "LOG-DATEIEN" -ForegroundColor Cyan
Write-Host "$('='*80)" -ForegroundColor Cyan

$logPath = "C:\CGM\Logs"
if (Test-Path $logPath) {
    Write-Host "`nVerfuegbare Logs:"
    Get-ChildItem -Path $logPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.Name) ($($_.LastWriteTime.ToString('dd.MM.yyyy HH:mm')))" -ForegroundColor Cyan
    }
    Write-Host "`nLog-Pfad: $logPath" -ForegroundColor White
} else {
    Write-Host "`nKeine Logs gefunden. Setup noch nicht ausgefuehrt?" -ForegroundColor Yellow
}

# ==============================================================================
# REGISTRY-BACKUPS
# ==============================================================================
Write-Host "`n$('='*80)" -ForegroundColor Cyan
Write-Host "REGISTRY-BACKUPS" -ForegroundColor Cyan
Write-Host "$('='*80)" -ForegroundColor Cyan

$backupPath = "C:\CGM\Registry-Backups"
if (Test-Path $backupPath) {
    Write-Host "`nVerfuegbare Backups:"
    Get-ChildItem -Path $backupPath -Filter "*.reg" | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.Name) ($($_.LastWriteTime.ToString('dd.MM.yyyy HH:mm')))" -ForegroundColor Cyan
    }
    Write-Host "`nBackup-Pfad: $backupPath" -ForegroundColor White
} else {
    Write-Host "`nKeine Backups gefunden." -ForegroundColor Yellow
}

# ==============================================================================
# EMPFEHLUNGEN
# ==============================================================================
Write-Host "`n$('='*80)" -ForegroundColor Cyan
Write-Host "EMPFEHLUNGEN" -ForegroundColor Cyan
Write-Host "$('='*80)" -ForegroundColor Cyan

if ($percentage -lt 100) {
    Write-Host "`n1. Explorer neu starten:" -ForegroundColor Yellow
    Write-Host "   Stop-Process -Name explorer -Force; Start-Process explorer" -ForegroundColor White
    
    Write-Host "`n2. Setup erneut ausfuehren:" -ForegroundColor Yellow
    Write-Host "   .\Win11-Setup-Complete.ps1" -ForegroundColor White
    
    Write-Host "`n3. System neu starten:" -ForegroundColor Yellow
    Write-Host "   Restart-Computer" -ForegroundColor White
}

Write-Host "`n"
Read-Host "Druecken Sie Enter zum Beenden"
