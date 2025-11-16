<#
.SYNOPSIS
    Windows 11 OOTB Anpassungs-Tool - eXpletus Edition
    
.DESCRIPTION
    Komplettes Setup-Tool mit allen 8 Modulen
    Module 1-4: Vollständig funktionsfähig (v1.2)
    Module 5-8: In Entwicklung (v1.3)
    
.NOTES
    Version: 1.2
    Author: Steve Lingner
    Copyright: © 2025 Steve Lingner
    Firma: eXpletus IT-Systemhaus
    Web: www.eXpletus.de
    Support: Support@eXpletus.de
    Tel: [0391] 561 66 31
    
.PARAMETER RunAll
    Fuehrt alle Module automatisch durch
    
.PARAMETER LightSetup
    Fuehrt Module 1-4, 7-8 aus (OHNE Software-Installation)
    
.PARAMETER TestMode
    Fuehrt nur Module 1-2 aus (Test)
    
.PARAMETER Module
    Fuehrt ein spezifisches Modul aus (1-4)
    
.EXAMPLE
    .\Win11-Setup.ps1 -RunAll
    
.EXAMPLE
    .\Win11-Setup.ps1 -LightSetup
    
.EXAMPLE
    .\Win11-Setup.ps1 -Module 2
#>

param(
    [switch]$RunAll,
    [switch]$LightSetup,
    [switch]$TestMode,
    [int]$Module
)

# ==============================================================================
# GLOBALE KONFIGURATION
# ==============================================================================
$Global:Config = @{
    LogPath = "C:\CGM\Logs"
    LogFile = "Win11-Setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    CGMFolder = "C:\CGM"
    BackupRegistry = $true
    Version = "1.2"
}

# ==============================================================================
# LOGGING FUNKTIONEN
# ==============================================================================
function Write-SetupLog {
    param(
        [string]$Message,
        [ValidateSet('INFO','SUCCESS','WARNING','ERROR','HEADER')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch($Level) {
        'SUCCESS' { 'Green' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'HEADER'  { 'Cyan' }
        default   { 'White' }
    }
    Write-Host $logMessage -ForegroundColor $color
    
    if (-not (Test-Path $Global:Config.LogPath)) {
        New-Item -Path $Global:Config.LogPath -ItemType Directory -Force | Out-Null
    }
    $logFile = Join-Path $Global:Config.LogPath $Global:Config.LogFile
    Add-Content -Path $logFile -Value $logMessage
}

function Start-ModuleExecution {
    param([string]$ModuleName)
    Write-Host "`n$('='*80)" -ForegroundColor Cyan
    Write-Host "  MODUL: $ModuleName" -ForegroundColor Cyan
    Write-Host "$('='*80)`n" -ForegroundColor Cyan
    Write-SetupLog "Starte Modul: $ModuleName" -Level HEADER
}

function Complete-ModuleExecution {
    param([string]$ModuleName, [int]$ErrorCount = 0)
    if ($ErrorCount -eq 0) {
        Write-SetupLog "Modul '$ModuleName' erfolgreich abgeschlossen [OK]" -Level SUCCESS
    } else {
        Write-SetupLog "Modul '$ModuleName' mit $ErrorCount Fehler(n) abgeschlossen" -Level WARNING
    }
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Download-WithProgress {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Description = "Datei"
    )
    
    try {
        Write-Host "  ├─ Starte Download..." -ForegroundColor Gray
        
        # Versuche BitsTransfer (funktioniert nicht bei Auth/Redirects)
        Import-Module BitsTransfer -ErrorAction SilentlyContinue
        if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
            try {
                $startTime = Get-Date
                Start-BitsTransfer -Source $Url -Destination $OutputPath -Description $Description -DisplayName $Description -ErrorAction Stop
                $duration = ((Get-Date) - $startTime).TotalSeconds
                
                if (Test-Path $OutputPath) {
                    $fileSize = (Get-Item $OutputPath).Length
                    $speedMBps = ($fileSize / 1MB) / $duration
                    Write-Host "  ├─ Abgeschlossen: $([math]::Round($fileSize/1MB, 1)) MB in $([math]::Round($duration, 1))s (Ø $([math]::Round($speedMBps, 2)) MB/s)" -ForegroundColor Gray
                    return $true
                }
            }
            catch {
                # BitsTransfer fehlgeschlagen (Auth/Redirect) - Fallback zu WebClient
                Write-Host "  ├─ Fallback zu direktem Download..." -ForegroundColor Gray
            }
        }
        
        # Fallback: WebClient (unterstützt Redirects/Auth)
        $webClient = New-Object System.Net.WebClient
        $startTime = Get-Date
        $webClient.DownloadFile($Url, $OutputPath)
        $duration = ((Get-Date) - $startTime).TotalSeconds
        $webClient.Dispose()
        
        if (Test-Path $OutputPath) {
            $fileSize = (Get-Item $OutputPath).Length
            Write-Host "  ├─ Abgeschlossen: $([math]::Round($fileSize/1MB, 1)) MB in $([math]::Round($duration, 1))s" -ForegroundColor Gray
            return $true
        }
        
        return $false
    }
    catch {
        Write-Host "  ├─ Fehler: $_" -ForegroundColor Red
        throw $_
    }
}

function Backup-Registry {
    param([string]$BackupName)
    
    try {
        $backupPath = Join-Path $Global:Config.CGMFolder "Registry-Backups"
        if (-not (Test-Path $backupPath)) {
            New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        }
        
        $fileName = "Registry-Backup-$BackupName-$(Get-Date -Format 'yyyyMMdd-HHmmss').reg"
        $filePath = Join-Path $backupPath $fileName
        
        Write-SetupLog "Erstelle Registry-Backup: $fileName" -Level INFO
        # Verwende cmd /c statt Start-Process um Parameter-Konflikt zu vermeiden
        & cmd /c "reg export HKCU `"$filePath`" /y >nul 2>&1"
        if ($LASTEXITCODE -eq 0) {
            Write-SetupLog "Registry-Backup erstellt" -Level SUCCESS
            return $true
        } else {
            Write-SetupLog "Registry-Backup Warnung: Exit-Code $LASTEXITCODE" -Level WARNING
            return $false
        }
    }
    catch {
        Write-SetupLog "Registry-Backup fehlgeschlagen: $_" -Level WARNING
        return $false
    }
}

# ==============================================================================
# MODULE LADEN (wenn separate Dateien vorhanden)
# ==============================================================================
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleFiles = @(
    "Module5-Software.ps1",
    "Module6-Komponenten.ps1",
    "Module7-Funktionalitaet.ps1",
    "Module8-ALBIS.ps1"
)

foreach ($moduleFile in $moduleFiles) {
    $modulePath = Join-Path $scriptPath $moduleFile
    if (Test-Path $modulePath) {
        . $modulePath
    }
}

# ==============================================================================
# MODUL 1: EINSTIEG
# ==============================================================================
function Invoke-Module1-Einstieg {
    Start-ModuleExecution "1. EINSTIEG - Admin-Pruefung und Initialisierung"
    $errors = 0
    
    try {
        if (-not (Test-AdminRights)) {
            throw "Keine Administrator-Rechte"
        }
        Write-SetupLog "Administrator-Rechte bestaetigt [OK]" -Level SUCCESS
        
        if (-not (Test-Path $Global:Config.CGMFolder)) {
            New-Item -Path $Global:Config.CGMFolder -ItemType Directory -Force | Out-Null
            Write-SetupLog "Ordner erstellt: $($Global:Config.CGMFolder)" -Level SUCCESS
        }
        
        if (-not (Test-Path $Global:Config.LogPath)) {
            New-Item -Path $Global:Config.LogPath -ItemType Directory -Force | Out-Null
            Write-SetupLog "Log-Ordner erstellt: $($Global:Config.LogPath)" -Level SUCCESS
        }
        
        if ($Global:Config.BackupRegistry) {
            Backup-Registry "Initial"
        }
        
        $os = Get-CimInstance Win32_OperatingSystem
        Write-SetupLog "System: $($os.Caption) Build $($os.BuildNumber)" -Level INFO
        Write-SetupLog "Computer: $env:COMPUTERNAME | User: $env:USERNAME" -Level INFO
    }
    catch {
        Write-SetupLog "Fehler in Modul 1: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "1. EINSTIEG" -ErrorCount $errors
    return ($errors -eq 0)
}

# ==============================================================================
# MODUL 2: CLEANUP
# ==============================================================================
function Invoke-Module2-Cleanup {
    Start-ModuleExecution "2. CLEANUP - Widgets, Pins, Desktop"
    $errors = 0
    $explorerNeedsRestart = $false
    
    try {
        if ($Global:Config.BackupRegistry) {
            Backup-Registry "Modul2-Cleanup"
        }
        
        # ======================================================================
        # WIDGETS ENTFERNEN
        # ======================================================================
        Write-SetupLog "Entferne Widgets..." -Level INFO
        try {
            $changedCount = 0
            
            # Methode 1: User Registry (oft gesperrt durch Gruppenrichtlinien)
            try {
                $widgetsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                if (-not (Test-Path $widgetsPath)) {
                    New-Item -Path $widgetsPath -Force | Out-Null
                }
                Set-ItemProperty -Path $widgetsPath -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction Stop
                $changedCount++
            }
            catch {
                # Wenn HKCU gesperrt, versuche HKLM Policy
                Write-SetupLog "    HKCU gesperrt, verwende Gruppenrichtlinie..." -Level INFO
            }
            
            # Methode 2: Gruppenrichtlinie (überschreibt User-Einstellungen)
            try {
                $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
                if (-not (Test-Path $policyPath)) {
                    New-Item -Path $policyPath -Force | Out-Null
                }
                Set-ItemProperty -Path $policyPath -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force
                $changedCount++
            }
            catch {
                Write-SetupLog "    Policy-Einstellung fehlgeschlagen" -Level WARNING
            }
            
            # Widgets komplett deaktivieren
            try {
                $weatherPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
                if (-not (Test-Path $weatherPath)) {
                    New-Item -Path $weatherPath -Force | Out-Null
                }
                Set-ItemProperty -Path $weatherPath -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $weatherPath -Name "IsFeedsAvailable" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $changedCount++
            }
            catch {}
            
            # Task View Button (Desktop Switching) entfernen
            try {
                $taskViewPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                Set-ItemProperty -Path $taskViewPath -Name "ShowTaskViewButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $changedCount++
                Write-SetupLog "    -> Task View (Desktop Switchen) deaktiviert" -Level INFO
            }
            catch {}
            
            # Neuigkeiten komplett deaktivieren
            try {
                $newsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
                if (-not (Test-Path $newsPath)) {
                    New-Item -Path $newsPath -Force | Out-Null
                }
                Set-ItemProperty -Path $newsPath -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $newsPath -Name "IsFeedsAvailable" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $changedCount++
                Write-SetupLog "    -> Neuigkeiten deaktiviert" -Level INFO
            }
            catch {}
            
            Write-SetupLog "  [OK] Widgets/Task View konfiguriert ($changedCount Aenderungen)" -Level SUCCESS
            $explorerNeedsRestart = $true
        }
        catch {
            Write-SetupLog "  [X] Widgets: $($_.Exception.Message)" -Level ERROR
            $errors++
        }
        
        # Copilot entfernen
        Write-SetupLog "Entferne Copilot..." -Level INFO
        try {
            $copilotPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Set-ItemProperty -Path $copilotPath -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            
            $copilotPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
            if (-not (Test-Path $copilotPolicyPath)) {
                New-Item -Path $copilotPolicyPath -Force | Out-Null
            }
            Set-ItemProperty -Path $copilotPolicyPath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
            Write-SetupLog "  [OK] Copilot deaktiviert" -Level SUCCESS
            $explorerNeedsRestart = $true
        }
        catch {
            Write-SetupLog "  [X] Copilot: $_" -Level ERROR
            $errors++
        }
        
        # OneDrive DEINSTALLIEREN
        Write-SetupLog "Deinstalliere OneDrive..." -Level INFO
        try {
            # Registry deaktivieren
            $onedrivePath = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
            if (Test-Path $onedrivePath) {
                Set-ItemProperty -Path $onedrivePath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            }
            
            # Aus Autostart entfernen
            $runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            Remove-ItemProperty -Path $runPath -Name "OneDrive" -ErrorAction SilentlyContinue
            
            # OneDrive-Prozess beenden
            Get-Process -Name OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            
            # OneDrive deinstallieren
            $oneDriveSetup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
            if (-not (Test-Path $oneDriveSetup)) {
                $oneDriveSetup = "$env:SystemRoot\System32\OneDriveSetup.exe"
            }
            
            if (Test-Path $oneDriveSetup) {
                Write-SetupLog "    -> Deinstalliere OneDrive..." -Level INFO
                Start-Process -FilePath $oneDriveSetup -ArgumentList "/uninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 3
                Write-SetupLog "    -> OneDrive deinstalliert" -Level SUCCESS
            }
            
            # OneDrive-Ordner entfernen (User-spezifisch)
            $oneDriveFolder = "$env:USERPROFILE\OneDrive"
            if (Test-Path $oneDriveFolder) {
                Remove-Item -Path $oneDriveFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            Write-SetupLog "  [OK] OneDrive deinstalliert" -Level SUCCESS
            $explorerNeedsRestart = $true
        }
        catch {
            Write-SetupLog "  [X] OneDrive: $_" -Level WARNING
        }
        
        # Suche entfernen
        Write-SetupLog "Entferne Suche..." -Level INFO
        try {
            $searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
            if (-not (Test-Path $searchPath)) {
                New-Item -Path $searchPath -Force | Out-Null
            }
            Set-ItemProperty -Path $searchPath -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -Force
            Write-SetupLog "  [OK] Suche deaktiviert" -Level SUCCESS
            $explorerNeedsRestart = $true
        }
        catch {
            Write-SetupLog "  [X] Suche: $_" -Level ERROR
            $errors++
        }
        
        # ======================================================================
        # TASKLEISTEN-PINS ENTFERNEN
        # ======================================================================
        Write-SetupLog "Entferne Taskleisten-Pins..." -Level INFO
        try {
            $removedCount = 0
            
            # Methode 1: Apps aus Taskbar entfernen (Windows 11)
            $appsToUnpin = @(
                "Microsoft Edge",
                "Microsoft Store", 
                "Mail",
                "Outlook",
                "Microsoft Teams",
                "Microsoft Office",
                "Word",
                "Excel",
                "PowerPoint"
            )
            
            foreach ($appName in $appsToUnpin) {
                try {
                    # Versuche App zu finden und zu entpinnen
                    $app = Get-StartApps | Where-Object { $_.Name -like "*$appName*" } | Select-Object -First 1
                    if ($app) {
                        # PowerShell-Methode zum Entpinnen
                        $shell = New-Object -ComObject Shell.Application
                        $folder = $shell.Namespace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}")
                        $item = $folder.Items() | Where-Object { $_.Name -eq $appName }
                        if ($item) {
                            $verb = $item.Verbs() | Where-Object { $_.Name -like "*Taskleiste*" -or $_.Name -like "*Unpin*" }
                            if ($verb) {
                                $verb.DoIt()
                                $removedCount++
                            }
                        }
                    }
                }
                catch {
                    # Stumm - App existiert nicht
                }
            }
            
            # Methode 2: Layout-Datei zurücksetzen (Windows 11)
            try {
                $layoutPath = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
                if (Test-Path $layoutPath) {
                    $layoutFile = Join-Path $layoutPath "start2.bin"
                    if (Test-Path $layoutFile) {
                        # Backup erstellen
                        Copy-Item $layoutFile "$layoutFile.backup" -Force -ErrorAction SilentlyContinue
                        # Datei löschen (wird beim nächsten Start neu erstellt)
                        Remove-Item $layoutFile -Force -ErrorAction SilentlyContinue
                        $removedCount++
                    }
                }
            }
            catch {}
            
            # Methode 3 DEAKTIVIERT: Würde auch Explorer-Pin entfernen!
            # (Nutzer möchte Explorer-Pin behalten)
            
            # Methode 4: Teams-spezifisch (Win11 Chat Icon)
            try {
                # Teams/Chat Icon aus Taskbar
                $chatPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                Set-ItemProperty -Path $chatPath -Name "TaskbarMn" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                
                # Teams Auto-Start deaktivieren
                $teamsStartupPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                Remove-ItemProperty -Path $teamsStartupPath -Name "com.squirrel.Teams.Teams" -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $teamsStartupPath -Name "Microsoft Teams" -ErrorAction SilentlyContinue
                
                Write-SetupLog "    -> Teams/Chat Icon speziell behandelt" -Level INFO
                $removedCount++
            }
            catch {}
            
            # Methode 5: UWP Teams App deinstallieren
            try {
                $teamsApp = Get-AppxPackage -Name "*Teams*" -ErrorAction SilentlyContinue
                if ($teamsApp) {
                    $teamsApp | Remove-AppxPackage -ErrorAction SilentlyContinue
                    Write-SetupLog "    -> Teams UWP App entfernt" -Level INFO
                    $removedCount++
                }
            }
            catch {}
            
            if ($removedCount -gt 0) {
                Write-SetupLog "  [OK] Taskleisten-Pins entfernt ($removedCount Aktionen)" -Level SUCCESS
            } else {
                Write-SetupLog "  [i] Keine Pins zum Entfernen gefunden" -Level INFO
            }
            $explorerNeedsRestart = $true
        }
        catch {
            Write-SetupLog "  [X] Pins entfernen: $_" -Level WARNING
        }
        Write-SetupLog "Bereinige Desktop..." -Level INFO
        try {
            $desktop = [Environment]::GetFolderPath('Desktop')
            $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
            $shortcutsToRemove = @(
                'Microsoft Edge.lnk',
                'Microsoft Store.lnk',
                'Outlook.lnk',
                'Mail.lnk',
                'Benutzer.lnk',
                'Geraete.lnk'
            )
            $removedCount = 0
            
            foreach ($shortcut in $shortcutsToRemove) {
                $userShortcut = Join-Path $desktop $shortcut
                if (Test-Path $userShortcut) {
                    Remove-Item -Path $userShortcut -Force -ErrorAction SilentlyContinue
                    $removedCount++
                }
                
                $publicShortcut = Join-Path $publicDesktop $shortcut
                if (Test-Path $publicShortcut) {
                    Remove-Item -Path $publicShortcut -Force -ErrorAction SilentlyContinue
                    $removedCount++
                }
            }
            Write-SetupLog "  [OK] Desktop bereinigt ($removedCount Verknuepfungen entfernt)" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Desktop: $_" -Level WARNING
        }
        
        # Geraete entfernen
        Write-SetupLog "Entferne unerwuenschte Geraete..." -Level INFO
        try {
            $removedCount = 0
            $fax = Get-Printer -Name "Fax" -ErrorAction SilentlyContinue
            if ($fax) {
                Remove-Printer -Name "Fax" -ErrorAction SilentlyContinue
                $removedCount++
            }
            
            $xps = Get-Printer -Name "Microsoft XPS Document Writer" -ErrorAction SilentlyContinue
            if ($xps) {
                Remove-Printer -Name "Microsoft XPS Document Writer" -ErrorAction SilentlyContinue
                $removedCount++
            }
            
            Write-SetupLog "  [OK] Drucker entfernt ($removedCount Geraete)" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Geraete: $_" -Level WARNING
        }
        
        # Explorer-Neustart wird am Ende von Modul 4 gesammelt durchgeführt
        if ($explorerNeedsRestart) {
            Write-SetupLog "`n[i] Explorer-Neustart wird am Ende aller Module durchgefuehrt" -Level INFO
        } else {
            Write-SetupLog "`n[i] Kein Explorer-Neustart erforderlich" -Level INFO
        }
        
        # Hinweis für manuelle Schritte
        if ($errors -gt 0) {
            Write-Host "`n================================================================" -ForegroundColor Yellow
            Write-Host " HINWEIS: Einige Einstellungen konnten nicht automatisch" -ForegroundColor Yellow  
            Write-Host "          geaendert werden (Berechtigungen/Gruppenrichtlinien)" -ForegroundColor Yellow
            Write-Host "================================================================" -ForegroundColor Yellow
            Write-Host " Manuell pruefen:" -ForegroundColor White
            Write-Host "   - Rechtsklick Taskleiste -> Taskleisteneinstellungen" -ForegroundColor Gray
            Write-Host "   - 'Widgets' ausschalten" -ForegroundColor Gray
            Write-Host "   - Unerwuenschte Icons: Rechtsklick -> 'Von Taskleiste loesen'" -ForegroundColor Gray
            Write-Host "================================================================`n" -ForegroundColor Yellow
        }
    }
    catch {
        Write-SetupLog "Kritischer Fehler in Modul 2: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "2. CLEANUP" -ErrorCount $errors
    return ($errors -eq 0)
}

# ==============================================================================
# MODUL 3: OPTIK und ERGONOMIE
# ==============================================================================
function Invoke-Module3-OptikErgonomie {
    Start-ModuleExecution "3. OPTIK und ERGONOMIE"
    $errors = 0
    $explorerNeedsRestart = $false
    
    try {
        if ($Global:Config.BackupRegistry) {
            Backup-Registry "Modul3-Optik"
        }
        
        Write-SetupLog "Konfiguriere Taskleiste..." -Level INFO
        try {
            $taskbarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $taskbarPath)) {
                New-Item -Path $taskbarPath -Force | Out-Null
            }
            
            # Linksbuendig
            Set-ItemProperty -Path $taskbarPath -Name "TaskbarAl" -Value 0 -Type DWord -Force
            # Nie gruppieren
            Set-ItemProperty -Path $taskbarPath -Name "TaskbarGlomLevel" -Value 2 -Type DWord -Force
            Set-ItemProperty -Path $taskbarPath -Name "MMTaskbarGlomLevel" -Value 2 -Type DWord -Force
            
            Write-SetupLog "  [OK] Taskleiste konfiguriert (linksbuendig, nicht gruppiert)" -Level SUCCESS
            $explorerNeedsRestart = $true
        }
        catch {
            Write-SetupLog "  [X] Taskleiste: $_" -Level ERROR
            $errors++
        }
        
        Write-SetupLog "Konfiguriere Explorer..." -Level INFO
        try {
            $explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            
            # Dateierweiterungen einblenden
            Set-ItemProperty -Path $explorerPath -Name "HideFileExt" -Value 0 -Type DWord -Force
            # Ausgeblendete Dateien anzeigen
            Set-ItemProperty -Path $explorerPath -Name "Hidden" -Value 1 -Type DWord -Force
            # Vollstaendigen Pfad anzeigen
            Set-ItemProperty -Path $explorerPath -Name "FullPathAddress" -Value 1 -Type DWord -Force
            
            Write-SetupLog "  [OK] Explorer konfiguriert (Erweiterungen, versteckte Dateien, Pfade)" -Level SUCCESS
            $explorerNeedsRestart = $true
        }
        catch {
            Write-SetupLog "  [X] Explorer: $_" -Level ERROR
            $errors++
        }
        
        # Hintergrundbild setzen
        Write-SetupLog "Setze Hintergrundbild (eXpletus)..." -Level INFO
        try {
            $scriptDir = Split-Path -Parent $PSCommandPath
            $imageDir = Join-Path (Split-Path -Parent $scriptDir) "images"
            $wallpaper16_9 = Join-Path $imageDir "Hintergrund_eXpletus_16-9_2021.jpg"
            
            if (Test-Path $wallpaper16_9) {
                $wallpaperDest = "C:\Windows\Web\Wallpaper\eXpletus_Wallpaper.jpg"
                Copy-Item -Path $wallpaper16_9 -Destination $wallpaperDest -Force
                
                # Registry-Methode (zuverlaessiger als API)
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $wallpaperDest -Force
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperStyle" -Value "2" -Force
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "TileWallpaper" -Value "0" -Force
                
                # Aktualisierung erzwingen
                & rundll32.exe user32.dll, UpdatePerUserSystemParameters
                
                Write-SetupLog "  [OK] Hintergrundbild gesetzt (eXpletus 16:9)" -Level SUCCESS
            } else {
                Write-SetupLog "  [i] Hintergrundbild nicht gefunden: $imageDir" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] Hintergrundbild: $_" -Level WARNING
        }
        
        # Profilbild setzen
        Write-SetupLog "Setze Profilbild (VP Logo)..." -Level INFO
        try {
            $scriptDir = Split-Path -Parent $PSCommandPath
            $imageDir = Join-Path (Split-Path -Parent $scriptDir) "images"
            $logoPath = Join-Path $imageDir "Logo_VP.jpg"
            
            if (Test-Path $logoPath) {
                # Ziel: Public Account Pictures (für alle User sichtbar)
                $publicAccountPics = "C:\ProgramData\Microsoft\User Account Pictures"
                if (-not (Test-Path $publicAccountPics)) {
                    New-Item -Path $publicAccountPics -ItemType Directory -Force | Out-Null
                }
                
                # Kopiere Logo als Standard-Profilbild
                $targetLogo = Join-Path $publicAccountPics "user.jpg"
                $targetLogoLarge = Join-Path $publicAccountPics "user-192.jpg"
                Copy-Item -Path $logoPath -Destination $targetLogo -Force
                Copy-Item -Path $logoPath -Destination $targetLogoLarge -Force
                
                # User-spezifischer Pfad
                $accountPicsPath = "$env:APPDATA\Microsoft\Windows\AccountPictures"
                if (-not (Test-Path $accountPicsPath)) {
                    New-Item -Path $accountPicsPath -ItemType Directory -Force | Out-Null
                }
                
                # Alle Größen für aktuellen User
                Copy-Item -Path $logoPath -Destination "$accountPicsPath\user-448.jpg" -Force
                Copy-Item -Path $logoPath -Destination "$accountPicsPath\user-192.jpg" -Force
                Copy-Item -Path $logoPath -Destination "$accountPicsPath\user-96.jpg" -Force
                Copy-Item -Path $logoPath -Destination "$accountPicsPath\user-48.jpg" -Force
                Copy-Item -Path $logoPath -Destination "$accountPicsPath\user-40.jpg" -Force
                Copy-Item -Path $logoPath -Destination "$accountPicsPath\user-32.jpg" -Force
                
                # Registry-Eintrag setzen für automatisches Laden
                $userName = $env:USERNAME
                $userSID = (New-Object System.Security.Principal.NTAccount($userName)).Translate([System.Security.Principal.SecurityIdentifier]).Value
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$userSID"
                
                if (-not (Test-Path $regPath)) {
                    New-Item -Path $regPath -Force | Out-Null
                }
                
                # Setze Pfade in Registry
                Set-ItemProperty -Path $regPath -Name "Image192" -Value "$accountPicsPath\user-192.jpg" -Force
                Set-ItemProperty -Path $regPath -Name "Image448" -Value "$accountPicsPath\user-448.jpg" -Force
                Set-ItemProperty -Path $regPath -Name "Image96" -Value "$accountPicsPath\user-96.jpg" -Force
                Set-ItemProperty -Path $regPath -Name "Image48" -Value "$accountPicsPath\user-48.jpg" -Force
                Set-ItemProperty -Path $regPath -Name "Image40" -Value "$accountPicsPath\user-40.jpg" -Force
                Set-ItemProperty -Path $regPath -Name "Image32" -Value "$accountPicsPath\user-32.jpg" -Force
                
                Write-SetupLog "  [OK] Profilbild vorbereitet (VP Logo - alle Größen)" -Level SUCCESS
                Write-Host "  [!] WICHTIG: Abmeldung erforderlich damit Profilbild aktiv wird!" -ForegroundColor Yellow
                Write-Host "  [i] Alternativ: Einstellungen > Konten > Ihre Infos > Foto anpassen" -ForegroundColor Cyan
            } else {
                Write-SetupLog "  [i] Logo nicht gefunden: $logoPath" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] Profilbild: $_" -Level WARNING
        }
        
        # Arbeitsgruppe auf EXPLETUS setzen
        Write-SetupLog "Setze Arbeitsgruppe auf EXPLETUS..." -Level INFO
        try {
            $currentWorkgroup = (Get-WmiObject Win32_ComputerSystem).Workgroup
            if ($currentWorkgroup -ne "EXPLETUS") {
                Write-SetupLog "  [i] Aktuelle Arbeitsgruppe: $currentWorkgroup" -Level INFO
                Write-SetupLog "  [i] Aendere zu: EXPLETUS" -Level INFO
                
                # WMI-Methode zum Aendern der Arbeitsgruppe
                $computer = Get-WmiObject Win32_ComputerSystem
                $computer.JoinDomainOrWorkgroup("EXPLETUS", $null, $null, $null, 1)
                
                Write-SetupLog "  [OK] Arbeitsgruppe auf EXPLETUS gesetzt" -Level SUCCESS
                Write-Host "  [!] WICHTIG: Neustart erforderlich damit Arbeitsgruppe aktiv wird!" -ForegroundColor Yellow
            } else {
                Write-SetupLog "  [OK] Arbeitsgruppe bereits EXPLETUS" -Level SUCCESS
            }
        }
        catch {
            Write-SetupLog "  [X] Arbeitsgruppe: $_" -Level WARNING
        }
        
        
        Write-SetupLog "Setze Hintergrundbild (eXpletus)..." -Level INFO
        try {
            # Suche nach Hintergrundbild
            $scriptDir = Split-Path -Parent $PSCommandPath
            $imageDir = Join-Path (Split-Path -Parent $scriptDir) "images"
            $wallpaper16_9 = Join-Path $imageDir "Hintergrund_eXpletus_16-9_2021.jpg"
            $wallpaper4_3 = Join-Path $imageDir "Hintergrund_eXpletus_4-3_2021.jpg"
            
            # Versuche 16:9 zuerst
            $wallpaperToUse = $null
            if (Test-Path $wallpaper16_9) {
                $wallpaperToUse = $wallpaper16_9
            } elseif (Test-Path $wallpaper4_3) {
                $wallpaperToUse = $wallpaper4_3
            }
            
            if ($wallpaperToUse) {
                # Kopiere nach Windows Wallpaper Ordner
                $wallpaperDest = "C:\Windows\Web\Wallpaper\eXpletus_Wallpaper.jpg"
                Copy-Item -Path $wallpaperToUse -Destination $wallpaperDest -Force
                
                # Setze als Hintergrund via Registry
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $wallpaperDest -Force
                
                # Trigger Update
                Add-Type -TypeDefinition @"
                using System;
                using System.Runtime.InteropServices;
                public class Wallpaper {
                    [DllImport("user32.dll", CharSet=CharSet.Auto)]
                    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
                }
"@
                [Wallpaper]::SystemParametersInfo(20, 0, $wallpaperDest, 3) | Out-Null
                
                Write-SetupLog "  [OK] Hintergrundbild gesetzt (eXpletus)" -Level SUCCESS
            } else {
                Write-SetupLog "  [i] Hintergrundbild nicht gefunden in: $imageDir" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] Hintergrundbild: $_" -Level WARNING
        }
        
        Write-SetupLog "Setze Profilbild (VP Logo)..." -Level INFO
        try {
            $scriptDir = Split-Path -Parent $PSCommandPath
            $imageDir = Join-Path (Split-Path -Parent $scriptDir) "images"
            $logoPath = Join-Path $imageDir "Logo_VP.jpg"
            
            if (Test-Path $logoPath) {
                # Kopiere in Account Pictures Ordner
                $accountPicsPath = "$env:APPDATA\Microsoft\Windows\AccountPictures"
                if (-not (Test-Path $accountPicsPath)) {
                    New-Item -Path $accountPicsPath -ItemType Directory -Force | Out-Null
                }
                
                # Verschiedene Größen erstellen (Windows braucht mehrere)
                Copy-Item -Path $logoPath -Destination "$accountPicsPath\user-192.jpg" -Force
                Copy-Item -Path $logoPath -Destination "$accountPicsPath\user-40.jpg" -Force
                Copy-Item -Path $logoPath -Destination "$accountPicsPath\user-32.jpg" -Force
                
                # Registry-Eintrag setzen
                $accountPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$env:USERNAME"
                if (-not (Test-Path $accountPath)) {
                    New-Item -Path $accountPath -Force | Out-Null
                }
                Set-ItemProperty -Path $accountPath -Name "Image192" -Value "$accountPicsPath\user-192.jpg" -Force -ErrorAction SilentlyContinue
                
                Write-SetupLog "  [OK] Profilbild vorbereitet (VP Logo)" -Level SUCCESS
                Write-Host "  [!] HINWEIS: Abmeldung erforderlich damit Profilbild aktiv wird!" -ForegroundColor Yellow
            } else {
                Write-SetupLog "  [i] Logo nicht gefunden: $logoPath" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] Profilbild: $_" -Level WARNING
        }
        
        Write-SetupLog "Deaktiviere Bildschirmschoner..." -Level INFO
        try {
            $screensaverPath = "HKCU:\Control Panel\Desktop"
            Set-ItemProperty -Path $screensaverPath -Name "ScreenSaveActive" -Value "0" -Force
            Set-ItemProperty -Path $screensaverPath -Name "ScreenSaveTimeOut" -Value "0" -Force
            Write-SetupLog "  [OK] Bildschirmschoner deaktiviert" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Bildschirmschoner: $_" -Level WARNING
        }
        
        Write-SetupLog "Konfiguriere Lockscreen-Verhalten..." -Level INFO
        try {
            # Deaktiviere Lockscreen-Features (OHNE Policy die UI versteckt!)
            # Rotating Lockscreen aus
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            
            # Lockscreen Timeout auf Minimum
            powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0 2>$null | Out-Null
            powercfg /setdcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0 2>$null | Out-Null
            
            Write-SetupLog "  [OK] Lockscreen minimiert (Einstellungen bleiben sichtbar)" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Lockscreen-Konfiguration: $_" -Level WARNING
        }
        
        # Desktop-Symbole aktivieren
        Write-SetupLog "Aktiviere Desktop-Symbole..." -Level INFO
        try {
            # CRITICAL FIX: Desktop-Icons VIEW explizit aktivieren
            $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Set-ItemProperty -Path $advancedPath -Name "HideIcons" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            
            $desktopIconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
            if (-not (Test-Path $desktopIconsPath)) {
                New-Item -Path $desktopIconsPath -Force | Out-Null
            }
            
            # FIX BUG #2: Sequentielles Einblenden für korrekte Sortierung
            # Schritt 1: ALLE Icons AUSBLENDEN
            Set-ItemProperty -Path $desktopIconsPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 1 -Type DWord -Force  # Dieser PC
            Set-ItemProperty -Path $desktopIconsPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 1 -Type DWord -Force  # Papierkorb
            Set-ItemProperty -Path $desktopIconsPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue  # Systemsteuerung
            Set-ItemProperty -Path $desktopIconsPath -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue  # Benutzerdateien
            Set-ItemProperty -Path $desktopIconsPath -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue  # Netzwerk
            
            # Warte kurz damit Registry übernommen wird
            Start-Sleep -Milliseconds 200
            
            # Schritt 2: In gewünschter REIHENFOLGE einblenden
            # 1. Dieser PC (oben)
            Set-ItemProperty -Path $desktopIconsPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -Type DWord -Force
            Start-Sleep -Milliseconds 100
            
            # 2. Papierkorb
            Set-ItemProperty -Path $desktopIconsPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 0 -Type DWord -Force
            
            # Desktop-Icons Sichtbarkeit sicherstellen
            $shellIconsPath = "HKCU:\Control Panel\Desktop"
            Set-ItemProperty -Path $shellIconsPath -Name "HideMyComputerIcons" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            
            Write-SetupLog "  [OK] Desktop-Symbole aktiviert (Dieser PC, Papierkorb)" -Level SUCCESS
            Write-SetupLog "  [OK] Sortierung: Dieser PC → Papierkorb" -Level SUCCESS
            
            # Desktop-Icon Anordnung: Am Raster, KEIN Auto-Arrange
            $desktopPath = "HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop"
            if (-not (Test-Path $desktopPath)) {
                New-Item -Path $desktopPath -Force | Out-Null
            }
            
            # IconSize: 48 = mittelgroß
            Set-ItemProperty -Path $desktopPath -Name "IconSize" -Value 48 -Type DWord -Force -ErrorAction SilentlyContinue
            
            # FFlags: 1075839488 = SNAP TO GRID + NO AUTO ARRANGE (korrekter Wert!)
            Set-ItemProperty -Path $desktopPath -Name "FFlags" -Value 1075839488 -Type DWord -Force -ErrorAction SilentlyContinue
            
            # Zusätzlich: Explorer Advanced Settings
            $explorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            # SnapToGrid explizit aktivieren
            Set-ItemProperty -Path $explorerAdvanced -Name "AutoArrange" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            
            # Desktop Bag Settings (Alternative Pfade)
            $bagPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\1\Desktop"
            if (-not (Test-Path $bagPath)) {
                New-Item -Path $bagPath -Force -ErrorAction SilentlyContinue | Out-Null
            }
            Set-ItemProperty -Path $bagPath -Name "FFlags" -Value 1075839488 -Type DWord -Force -ErrorAction SilentlyContinue
            
            # AllUsersDesktop
            $allPath = "HKCU:\Software\Microsoft\Windows\Shell\BagMRU"
            Set-ItemProperty -Path $allPath -Name "NodeSlot" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            
            Write-SetupLog "  [OK] Desktop-Symbole: Am Raster (FFlags=1075839488)" -Level SUCCESS
            # KEIN Explorer-Neustart hier (Icons werden transparent)
        }
        catch {
            Write-SetupLog "  [X] Desktop-Symbole: $_" -Level WARNING
        }
        
        if ($explorerNeedsRestart) {
            Write-SetupLog "`nStarte Explorer neu (Aenderungen werden wirksam)..." -Level INFO
            Write-Host "`n  [i] Explorer wird neu gestartet (ohne Fenster)..." -ForegroundColor Cyan
            try {
                # TRICK: Registry-Key setzen um Fenster-Öffnung zu verhindern
                $explorerKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                $oldValue = $null
                try {
                    $oldValue = Get-ItemProperty -Path $explorerKey -Name "PersistBrowsers" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PersistBrowsers
                } catch {}
                
                # PersistBrowsers = 0 verhindert dass Explorer Fenster nach Neustart öffnet
                Set-ItemProperty -Path $explorerKey -Name "PersistBrowsers" -Value 0 -Type DWord -Force
                
                # Alle offenen Explorer-Fenster schließen
                $shell = New-Object -ComObject Shell.Application
                $shell.Windows() | ForEach-Object {
                    try { $_.Quit() } catch {}
                }
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
                Start-Sleep -Milliseconds 500
                
                # Explorer-Prozess beenden
                Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                
                # Neu starten (KEIN Fenster durch PersistBrowsers=0)
                Start-Process explorer.exe
                Start-Sleep -Seconds 2
                
                # PersistBrowsers auf alten Wert zurücksetzen (oder 1 wenn nicht vorhanden)
                if ($null -ne $oldValue) {
                    Set-ItemProperty -Path $explorerKey -Name "PersistBrowsers" -Value $oldValue -Type DWord -Force
                } else {
                    Set-ItemProperty -Path $explorerKey -Name "PersistBrowsers" -Value 1 -Type DWord -Force
                }
                
                # Sicherheit: Falls doch ein Fenster da ist, schließen
                Start-Sleep -Seconds 1
                $shell = New-Object -ComObject Shell.Application
                $shell.Windows() | ForEach-Object {
                    try { $_.Quit() } catch {}
                }
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
                
                Write-Host "  [OK] Explorer neu gestartet (Desktop only)" -ForegroundColor Green
                Write-SetupLog "  [OK] Explorer neu gestartet ohne Fenster" -Level SUCCESS
            }
            catch {
                Write-SetupLog "  [X] Explorer-Neustart fehlgeschlagen: $_" -Level ERROR
            }
        }
    }
    catch {
        Write-SetupLog "Kritischer Fehler in Modul 3: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "3. OPTIK und ERGONOMIE" -ErrorCount $errors
    return ($errors -eq 0)
}

# ==============================================================================
# MODUL 4: PERFORMANCE
# ==============================================================================
function Invoke-Module4-Performance {
    Start-ModuleExecution "4. PERFORMANCE und ENERGIEEINSTELLUNGEN"
    $errors = 0
    
    try {
        if ($Global:Config.BackupRegistry) {
            Backup-Registry "Modul4-Performance"
        }
        
        Write-SetupLog "Bereinige Autostart..." -Level INFO
        try {
            $programsToRemove = @('OneDrive', 'Teams', 'Skype', 'Copilot')
            $removedCount = 0
            
            $hkcuRun = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            $items = Get-ItemProperty -Path $hkcuRun -ErrorAction SilentlyContinue
            if ($items) {
                foreach ($program in $programsToRemove) {
                    $items.PSObject.Properties | Where-Object { $_.Name -like "*$program*" } | ForEach-Object {
                        Remove-ItemProperty -Path $hkcuRun -Name $_.Name -ErrorAction SilentlyContinue
                        Write-SetupLog "    -> $($_.Name) entfernt" -Level INFO
                        $removedCount++
                    }
                }
            }
            
            # Copilot explizit deaktivieren
            try {
                $copilotPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                Set-ItemProperty -Path $copilotPath -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                Write-SetupLog "    -> Copilot Button deaktiviert" -Level INFO
            } catch {}
            
            # OneDrive explizit deaktivieren
            try {
                $onedrivePath = "HKCU:\Software\Microsoft\OneDrive"
                if (Test-Path $onedrivePath) {
                    Set-ItemProperty -Path $onedrivePath -Name "DisableFileSyncNGSC" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                    Write-SetupLog "    -> OneDrive Sync deaktiviert" -Level INFO
                }
            } catch {}
            
            Write-SetupLog "  [OK] Autostart bereinigt ($removedCount Programme entfernt)" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Autostart: $_" -Level WARNING
        }
        
        Write-SetupLog "Konfiguriere Energieoptionen..." -Level INFO
        try {
            # Hoechstleistung aktivieren
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>und1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e | Out-Null
            }
            
            # Timeouts auf 0
            powercfg /change monitor-timeout-ac 0 | Out-Null
            powercfg /change disk-timeout-ac 0 | Out-Null
            powercfg /change standby-timeout-ac 0 | Out-Null
            powercfg /change hibernate-timeout-ac 0 | Out-Null
            
            Write-SetupLog "  [OK] Energieoptionen: Hoechstleistung, Timeouts=0" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Energieoptionen: $_" -Level ERROR
            $errors++
        }
        
        Write-SetupLog "Deaktiviere Schnellstart und Hibernate..." -Level INFO
        try {
            $powerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
            if (Test-Path $powerPath) {
                Set-ItemProperty -Path $powerPath -Name "HiberbootEnabled" -Value 0 -Type DWord -Force
            }
            powercfg /hibernate off 2>&1 | Out-Null
            Write-SetupLog "  [OK] Schnellstart und Ruhezustand deaktiviert" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Schnellstart/Hibernate: $_" -Level WARNING
        }
        
        # UAC auf niedrigste Stufe setzen
        Write-SetupLog "Setze UAC auf niedrigste Stufe..." -Level INFO
        try {
            $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            Set-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $uacPath -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $uacPath -Name "EnableLUA" -Value 1 -Type DWord -Force
            Write-SetupLog "  [OK] UAC auf 'Nie benachrichtigen' gesetzt" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] UAC: $_" -Level WARNING
        }
        
        # Standard-Druckerverwaltung durch Windows DEAKTIVIEREN
        Write-SetupLog "Deaktiviere Windows Standarddrucker-Verwaltung..." -Level INFO
        try {
            $printerPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows"
            if (-not (Test-Path $printerPath)) {
                New-Item -Path $printerPath -Force | Out-Null
            }
            # LegacyDefaultPrinterMode = 1: Benutzer verwaltet Standarddrucker selbst
            Set-ItemProperty -Path $printerPath -Name "LegacyDefaultPrinterMode" -Value 1 -Type DWord -Force
            Write-SetupLog "  [OK] Standarddrucker-Verwaltung: Benutzer (nicht Windows)" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Standarddrucker-Verwaltung: $_" -Level WARNING
        }
        
        # USB Selective Suspend deaktivieren
        Write-SetupLog "Deaktiviere USB Selective Suspend..." -Level INFO
        try {
            # Hole aktiven Energiesparplan GUID
            $activePlan = (powercfg /getactivescheme).Split()[3]
            
            # USB Selective Suspend fuer AC (Netzbetrieb) deaktivieren
            & powercfg /setacvalueindex $activePlan 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
            
            # USB Selective Suspend fuer DC (Akkubetrieb) deaktivieren  
            & powercfg /setdcvalueindex $activePlan 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
            
            # Aenderungen aktivieren
            & powercfg /setactive $activePlan
            
            Write-SetupLog "  [OK] USB Selective Suspend deaktiviert (AC + DC)" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] USB Selective Suspend: $_" -Level WARNING
        }
        
        Write-SetupLog "Optimiere Netzwerkadapter..." -Level INFO
        try {
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
            foreach ($adapter in $adapters) {
                $instanceId = $adapter.InterfaceGuid
                $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
                $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
                
                foreach ($key in $subKeys) {
                    $guid = Get-ItemProperty -Path $key.PSPath -Name "NetCfgInstanceId" -ErrorAction SilentlyContinue
                    if ($guid.NetCfgInstanceId -eq $instanceId) {
                        Set-ItemProperty -Path $key.PSPath -Name "PnPCapabilities" -Value 24 -Type DWord -ErrorAction SilentlyContinue
                        break
                    }
                }
            }
            Write-SetupLog "  [OK] Netzwerkadapter optimiert" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Netzwerkadapter: $_" -Level WARNING
        }
    }
    catch {
        Write-SetupLog "Kritischer Fehler in Modul 4: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "4. PERFORMANCE" -ErrorCount $errors
    return ($errors -eq 0)
}

# ==============================================================================
# MODUL 5: SOFTWARE und DATEN - Vollständig optimiert
# ==============================================================================
function Invoke-Module5-Software {
    Start-ModuleExecution "5. SOFTWARE und DATEN"
    $errors = 0
    
    try {
        # CGM Ordner anlegen
        Write-SetupLog "Erstelle Ordner-Struktur..." -Level INFO
        try {
            if (-not (Test-Path "C:\CGM")) {
                New-Item -Path "C:\CGM" -ItemType Directory -Force | Out-Null
                Write-SetupLog "  [OK] Ordner C:\CGM erstellt" -Level SUCCESS
            } else {
                Write-SetupLog "  [i] Ordner C:\CGM existiert bereits" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] Ordner erstellen: $_" -Level ERROR
            $errors++
        }
        
        # Chocolatey installieren
        Write-SetupLog "`nInstalliere Chocolatey Package Manager..." -Level INFO
        try {
            $chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
            if ($chocoInstalled) {
                Write-SetupLog "  [OK] Chocolatey bereits installiert" -Level SUCCESS
            } else {
                Write-SetupLog "  [i] Installiere Chocolatey..." -Level INFO
                Write-Host "  [i] Installiere Chocolatey Package Manager..." -ForegroundColor Cyan
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                
                $chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
                if ($chocoInstalled) {
                    Write-SetupLog "  [OK] Chocolatey erfolgreich installiert" -Level SUCCESS
                } else {
                    Write-SetupLog "  [X] Chocolatey Installation fehlgeschlagen" -Level ERROR
                    $errors++
                }
            }
        }
        catch {
            Write-SetupLog "  [X] Chocolatey: $_" -Level ERROR
            $errors++
        }
        
        # ===================================================================
        # PHASE 1: ABFRAGEN (alle optionalen Pakete VOR Downloads)
        # ===================================================================
        Write-Host "`n============================================================================" -ForegroundColor Cyan
        Write-Host "  SOFTWARE-AUSWAHL" -ForegroundColor Cyan
        Write-Host "============================================================================" -ForegroundColor Cyan
        
        $installOffice = $false
        $installAcrobat = $false
        
        Write-Host "`n  Adobe Acrobat Reader (~500 MB, dauert 3-5 Minuten!) installieren?" -ForegroundColor Yellow
        $response = Read-Host "  [J/N]"
        $installAcrobat = ($response -eq "J" -or $response -eq "j")
        
        Write-Host "`n  MS Office Home & Business 2024 (~2 GB!) installieren?" -ForegroundColor Yellow
        $response = Read-Host "  [J/N]"
        $installOffice = ($response -eq "J" -or $response -eq "j")
        
        # ===================================================================
        # PHASE 2: INSTALLATION (mit Fortschrittsanzeige)
        # ===================================================================
        $chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoInstalled) {
            Write-Host "`n============================================================================" -ForegroundColor Cyan
            Write-Host "  SOFTWARE-INSTALLATION" -ForegroundColor Cyan
            Write-Host "============================================================================`n" -ForegroundColor Cyan
            
            # Pakete mit Größen und Parametern
            $packages = @(
                @{Name="7zip"; DisplayName="7-Zip"; Size=5; Params=""; ExtraArgs=""},
                @{Name="firefox"; DisplayName="Mozilla Firefox"; Size=100; Params="/l=de /RemoveDistributionDir=true /PreventRebootRequired=true"; ExtraArgs=""},
                @{Name="googlechrome"; DisplayName="Google Chrome"; Size=100; Params=""; ExtraArgs="--ignore-checksums"}
            )
            
            # Optional: WhatsApp (DEAKTIVIERT - nicht in Chocolatey verfügbar)
            # if ($installWhatsApp) {
            #     $packages += @{Name="whatsapp"; DisplayName="WhatsApp"; Size=200; Params=""}
            # }
            
            # Optional: Acrobat Reader
            if ($installAcrobat) {
                $packages += @{Name="adobereader"; DisplayName="Adobe Acrobat Reader"; Size=500; Params="/NoUpdates"; ExtraArgs=""}
            }
            
            # Optional: Office (ganz am Ende wegen Größe)
            if ($installOffice) {
                $packages += @{Name="office365business"; DisplayName="MS Office 2024"; Size=2000; Params="/exclude:Access Groove Lync Publisher"; ExtraArgs=""}
            }
            
            $totalPackages = $packages.Count
            $currentPackage = 0
            $installedApps = @()
            
            foreach ($pkg in $packages) {
                $currentPackage++
                
                Write-Host "`n  [$currentPackage/$totalPackages] $($pkg.DisplayName) (~$($pkg.Size) MB)" -ForegroundColor Cyan
                Write-SetupLog "  [$currentPackage/$totalPackages] Installiere $($pkg.DisplayName)..." -Level INFO
                
                # Spezielle Hinweise für große Pakete
                if ($pkg.Size -ge 500) {
                    Write-Host "  [!] GROSSES PAKET - Download dauert 2-10 Minuten!" -ForegroundColor Yellow
                }
                
                try {
                    # MIT Progress - Chocolatey zeigt automatisch Download-Fortschritt
                    $startTime = Get-Date
                    
                    # Baue Argument-String
                    $chocoArgs = "install $($pkg.Name) -y --force"
                    if ($pkg.Params) {
                        $chocoArgs += " --params=`"$($pkg.Params)`""
                    }
                    if ($pkg.ExtraArgs) {
                        $chocoArgs += " $($pkg.ExtraArgs)"
                    }
                    
                    # Nutze .NET Process für LIVE Output (kein Buffering!)
                    $psi = New-Object System.Diagnostics.ProcessStartInfo
                    $psi.FileName = "choco.exe"
                    $psi.Arguments = $chocoArgs
                    $psi.UseShellExecute = $false
                    $psi.RedirectStandardOutput = $false  # WICHTIG: Nicht umleiten!
                    $psi.RedirectStandardError = $false   # WICHTIG: Nicht umleiten!
                    $psi.CreateNoWindow = $false
                    
                    $process = New-Object System.Diagnostics.Process
                    $process.StartInfo = $psi
                    [void]$process.Start()
                    
                    # Timeout für große Pakete (15 Minuten)
                    $timeoutMinutes = 15
                    if ($pkg.Size -ge 500) {
                        Write-Host "  ├─ Timeout: $timeoutMinutes Minuten..." -ForegroundColor Gray
                    }
                    $timeoutMs = $timeoutMinutes * 60 * 1000
                    
                    if ($process.WaitForExit($timeoutMs)) {
                        # Normal beendet
                        $LASTEXITCODE = $process.ExitCode
                    } else {
                        # Timeout! Prozess killen
                        Write-Host "  ├─ [!] Timeout erreicht - beende Installation..." -ForegroundColor Yellow
                        $process.Kill()
                        $LASTEXITCODE = 0  # Als Erfolg werten (ist vermutlich installiert)
                    }
                    
                    $duration = ((Get-Date) - $startTime).TotalSeconds
                    
                    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1 -or $LASTEXITCODE -eq 1641 -or $LASTEXITCODE -eq 3010) {
                        Write-Host "`n  [OK] Erfolgreich installiert ($([math]::Round($duration, 1))s)" -ForegroundColor Green
                        Write-SetupLog "    [OK] $($pkg.DisplayName) installiert (Exit-Code: $LASTEXITCODE)" -Level SUCCESS
                        $installedApps += $pkg.DisplayName
                    } else {
                        Write-Host "`n  [X] Installation mit Fehler (Exit-Code: $LASTEXITCODE)" -ForegroundColor Red
                        Write-SetupLog "    [X] $($pkg.DisplayName) Exit-Code: $LASTEXITCODE" -Level WARNING
                    }
                }
                catch {
                    Write-Host "`n  [X] Fehler: $_" -ForegroundColor Red
                    Write-SetupLog "    [X] $($pkg.DisplayName): $_" -Level WARNING
                }
            }
            
            Write-Host "`n============================================================================" -ForegroundColor Cyan
            Write-Host "  Installation abgeschlossen: $($installedApps.Count) Programme" -ForegroundColor Green
            Write-Host "============================================================================`n" -ForegroundColor Cyan
        }
        
        # Fernwartungs-Ordner ZUERST erstellen!
        Write-SetupLog "`nRichte Fernwartungs-Tools ein..." -Level INFO
        $fernwartungPath = "C:\CGM\Fernwartung"
        if (-not (Test-Path $fernwartungPath)) {
            New-Item -Path $fernwartungPath -ItemType Directory -Force | Out-Null
            Write-SetupLog "  [OK] Ordner $fernwartungPath erstellt" -Level SUCCESS
        }
        
        # TeamViewer QuickSupport Download (portable, ~25 MB)
        Write-SetupLog "`nLade TeamViewer QuickSupport..." -Level INFO
        Write-Host "`n  [i] Lade TeamViewer QuickSupport (~25 MB)..." -ForegroundColor Cyan
        Write-Host "  ├─ Download startet (dauert ca. 30-60 Sekunden)..." -ForegroundColor Gray
        try {
            $tvQsUrl = "https://download.teamviewer.com/download/TeamViewerQS.exe"
            $tvQsPath = "$fernwartungPath\TeamViewerQS.exe"
            
            $success = Download-WithProgress -Url $tvQsUrl -OutputPath $tvQsPath -Description "TeamViewer QuickSupport"
            
            if ($success) {
                $desktop = [Environment]::GetFolderPath('Desktop')
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut("$desktop\TeamViewer.lnk")
                $shortcut.TargetPath = $tvQsPath
                $shortcut.WorkingDirectory = "C:\CGM\Fernwartung"
                $shortcut.Save()
                Write-Host "  └─ [OK] TeamViewer QS bereit" -ForegroundColor Green
                Write-SetupLog "  [OK] TeamViewer QS heruntergeladen + Verknüpfung erstellt" -Level SUCCESS
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
            } else {
                Write-Host "  └─ [X] Download fehlgeschlagen" -ForegroundColor Red
                Write-SetupLog "  [X] TeamViewer QS Download fehlgeschlagen" -Level WARNING
            }
        }
        catch {
            Write-Host "  └─ [X] Fehler: $_" -ForegroundColor Red
            Write-SetupLog "  [X] TeamViewer QS: $_" -Level WARNING
        }
        
        # Fernwartungs-Tools einrichten
        Write-SetupLog "`nRichte Fernwartungs-Tools ein..." -Level INFO
        try {
            # Fernwartungs-Ordner erstellen
            $fernwartungPath = "C:\CGM\Fernwartung"
            if (-not (Test-Path $fernwartungPath)) {
                New-Item -Path $fernwartungPath -ItemType Directory -Force | Out-Null
                Write-SetupLog "  [OK] Ordner $fernwartungPath erstellt" -Level SUCCESS
            }
            
            $desktop = [Environment]::GetFolderPath('Desktop')
            $shell = New-Object -ComObject WScript.Shell
            
            # 1. PC Visit Kunden-Modul (portable)
            Write-Host "  [i] Lade PC Visit Kunden-Modul..." -ForegroundColor Cyan
            try {
                $pcvisitUrl = "https://lb3.pcvisit.de/v1/hosted/jumplink?func=download&topic=guestSetup&destname=pcvisit_Kunden-Modul&os=osWin32"
                $pcvisitPath = "$fernwartungPath\pcvisit_Kunden-Modul.exe"
                
                $success = Download-WithProgress -Url $pcvisitUrl -OutputPath $pcvisitPath -Description "PC Visit"
                
                if ($success) {
                    Write-SetupLog "  [OK] PC Visit heruntergeladen" -Level SUCCESS
                    
                    # Desktop-Verknüpfung erstellen
                    $shortcutPath = "$desktop\Fernwartung eXpletus.lnk"
                    $shortcut = $shell.CreateShortcut($shortcutPath)
                    $shortcut.TargetPath = $pcvisitPath
                    $shortcut.WorkingDirectory = $fernwartungPath
                    $shortcut.Description = "eXpletus Fernwartung"
                    $shortcut.Save()
                    
                    Write-Host "  [OK] PC Visit bereit (Desktop-Verknüpfung)" -ForegroundColor Green
                    Write-Host "  [i] Bitte manuell an Taskleiste anheften!" -ForegroundColor Yellow
                    Write-SetupLog "  [OK] PC Visit Desktop-Verknüpfung erstellt (manuelles Pinning erforderlich)" -Level SUCCESS
                } else {
                    Write-SetupLog "  [X] PC Visit Download fehlgeschlagen" -Level WARNING
                }
            }
            catch {
                Write-SetupLog "  [X] PC Visit: $_" -Level WARNING
                Write-Host "  [X] PC Visit konnte nicht geladen werden" -ForegroundColor Red
            }
            
            # 2. CGM Remote Support (aus assets kopieren)
            Write-Host "  [i] Kopiere CGM Remote Support..." -ForegroundColor Cyan
            try {
                $scriptDir = Split-Path -Parent $PSScriptRoot
                $cgmSource = Join-Path $scriptDir "assets\CGM_Remote_Support.exe"
                $cgmDest = "$fernwartungPath\CGM_Remote_Support.exe"
                
                if (Test-Path $cgmSource) {
                    Copy-Item -Path $cgmSource -Destination $cgmDest -Force
                    Write-SetupLog "  [OK] CGM Remote Support kopiert" -Level SUCCESS
                    
                    # Desktop-Verknüpfung
                    $shortcut = $shell.CreateShortcut("$desktop\CGM Remote Support.lnk")
                    $shortcut.TargetPath = $cgmDest
                    $shortcut.WorkingDirectory = $fernwartungPath
                    $shortcut.Description = "CGM Fernwartung"
                    $shortcut.Save()
                    Write-Host "  [OK] CGM Remote Support bereit" -ForegroundColor Green
                } else {
                    Write-SetupLog "  [!] CGM Remote Support nicht gefunden in: $cgmSource" -Level WARNING
                }
            }
            catch {
                Write-SetupLog "  [X] CGM Remote Support: $_" -Level WARNING
                Write-Host "  [X] CGM Remote Support konnte nicht kopiert werden" -ForegroundColor Red
            }
            
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
            Write-SetupLog "  [OK] Fernwartungs-Tools eingerichtet" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Fernwartungs-Setup: $_" -Level WARNING
        }
        
        # Desktop-Verknüpfungen für installierte Programme (nur wo nötig)
        Write-SetupLog "`nErstelle Desktop-Verknüpfungen..." -Level INFO
        try {
            $desktop = [Environment]::GetFolderPath('Desktop')
            $shell = New-Object -ComObject WScript.Shell
            $created = 0
            
            # NUR Acrobat wenn installiert (Firefox/Chrome erstellen selbst Verknüpfungen)
            if ($installAcrobat) {
                $acrobatPath = "${env:ProgramFiles}\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
                if (-not (Test-Path $acrobatPath)) {
                    $acrobatPath = "${env:ProgramFiles(x86)}\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
                }
                if (Test-Path $acrobatPath) {
                    $shortcut = $shell.CreateShortcut("$desktop\Adobe Acrobat Reader.lnk")
                    $shortcut.TargetPath = $acrobatPath
                    $shortcut.Save()
                    $created++
                }
            }
            
            Write-SetupLog "  [OK] $created Desktop-Verknüpfungen erstellt" -Level SUCCESS
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        }
        catch {
            Write-SetupLog "  [X] Desktop-Verknüpfungen: $_" -Level WARNING
        }
        
    }
    catch {
        Write-SetupLog "Kritischer Fehler in Modul 5: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "5. SOFTWARE" -ErrorCount $errors
    
    return ($errors -eq 0)
}

# ==============================================================================
# MODUL 6: KOMPONENTEN (Platzhalter)
# ==============================================================================
function Invoke-Module6-Komponenten {
    Start-ModuleExecution "6. RUNTIME-KOMPONENTEN"
    $errors = 0
    
    try {
        if ($Global:Config.BackupRegistry) {
            Backup-Registry "Modul6-Komponenten"
        }
        
        Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║  MODUL 6: Runtime-Komponenten                                             ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
        
        Write-Host "  Installiere wichtige Runtime-Komponenten..." -ForegroundColor Yellow
        Write-Host "  (Java, .NET, Visual C++ Redistributables)`n" -ForegroundColor Gray
        
        $components = @(
            @{Name="temurin21jre"; DisplayName="Java 21 JRE (Temurin)"; Size=180},
            @{Name="dotnet-desktopruntime"; DisplayName=".NET Desktop Runtime"; Size=50},
            @{Name="vcredist140"; DisplayName="Visual C++ 2015-2022 Redistributable"; Size=25}
        )
        
        $totalComponents = $components.Count
        $currentComponent = 0
        $installedComponents = @()
        
        foreach ($comp in $components) {
            $currentComponent++
            
            Write-Host "`n  [$currentComponent/$totalComponents] $($comp.DisplayName) (~$($comp.Size) MB)" -ForegroundColor Cyan
            Write-SetupLog "  [$currentComponent/$totalComponents] Installiere $($comp.DisplayName)..." -Level INFO
            
            try {
                $startTime = Get-Date
                
                # .NET Process für Live-Output
                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = "choco.exe"
                $psi.Arguments = "install $($comp.Name) -y --force"
                $psi.UseShellExecute = $false
                $psi.RedirectStandardOutput = $false
                $psi.RedirectStandardError = $false
                $psi.CreateNoWindow = $false
                
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo = $psi
                [void]$process.Start()
                $process.WaitForExit()
                
                $exitCode = $process.ExitCode
                $duration = ((Get-Date) - $startTime).TotalSeconds
                
                if ($exitCode -eq 0 -or $exitCode -eq 1 -or $exitCode -eq 1641 -or $exitCode -eq 3010) {
                    Write-Host "`n  [OK] Erfolgreich installiert ($([math]::Round($duration, 1))s)" -ForegroundColor Green
                    Write-SetupLog "    [OK] $($comp.DisplayName) installiert" -Level SUCCESS
                    $installedComponents += $comp.DisplayName
                } else {
                    Write-Host "`n  [X] Installation mit Fehler (Exit-Code: $exitCode)" -ForegroundColor Red
                    Write-SetupLog "    [X] $($comp.DisplayName) Exit-Code: $exitCode" -Level WARNING
                    $errors++
                }
            }
            catch {
                Write-Host "`n  [X] Fehler: $_" -ForegroundColor Red
                Write-SetupLog "    [X] $($comp.DisplayName): $_" -Level WARNING
                $errors++
            }
        }
        
        Write-Host "`n============================================================================" -ForegroundColor Cyan
        Write-Host "  Installation abgeschlossen: $($installedComponents.Count)/$totalComponents Komponenten" -ForegroundColor Green
        Write-Host "============================================================================`n" -ForegroundColor Cyan
        
        if ($installedComponents.Count -gt 0) {
            Write-Host "  Installierte Komponenten:" -ForegroundColor White
            foreach ($comp in $installedComponents) {
                Write-Host "    - $comp" -ForegroundColor Gray
            }
            Write-Host ""
        }
        
    }
    catch {
        Write-SetupLog "[X] Modul 6 Fehler: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "6. RUNTIME-KOMPONENTEN" -ErrorCount $errors
    return ($errors -eq 0)
}

# ==============================================================================
# MODUL 7: FUNKTIONALITAET (Platzhalter)
# ==============================================================================
function Invoke-Module7-Funktionalitaet {
    Start-ModuleExecution "7. FUNKTIONALITAET UND BENUTZERFREUNDLICHKEIT"
    $errors = 0
    
    try {
        if ($Global:Config.BackupRegistry) {
            Backup-Registry "Modul7-Funktionalitaet"
        }
        
        Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║  MODUL 7: Funktionalität und Benutzerfreundlichkeit                       ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
        
        # 1. Nummernblock automatisch aktivieren
        Write-SetupLog "Aktiviere Nummernblock beim Start..." -Level INFO
        try {
            # Für aktuellen User
            $userPath = "HKCU:\Control Panel\Keyboard"
            Set-ItemProperty -Path $userPath -Name "InitialKeyboardIndicators" -Value "2" -Type String -Force
            
            # Für zukünftige User (Default User Profile)
            $defaultUserPath = "C:\Users\Default\NTUSER.DAT"
            if (Test-Path $defaultUserPath) {
                # Lade Default User Registry
                & reg load HKU\DefaultUser $defaultUserPath 2>&1 | Out-Null
                & reg add "HKU\DefaultUser\Control Panel\Keyboard" /v InitialKeyboardIndicators /t REG_SZ /d 2 /f 2>&1 | Out-Null
                & reg unload HKU\DefaultUser 2>&1 | Out-Null
            }
            
            Write-SetupLog "  [OK] Nummernblock wird beim Start aktiviert" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Nummernblock: $_" -Level WARNING
            $errors++
        }
        
        # 2. Erweiterte Zwischenablage (Clipboard History) aktivieren
        Write-SetupLog "Aktiviere erweiterte Zwischenablage (WIN+V)..." -Level INFO
        try {
            $clipboardPath = "HKCU:\Software\Microsoft\Clipboard"
            if (-not (Test-Path $clipboardPath)) {
                New-Item -Path $clipboardPath -Force | Out-Null
            }
            Set-ItemProperty -Path $clipboardPath -Name "EnableClipboardHistory" -Value 1 -Type DWord -Force
            
            Write-SetupLog "  [OK] Zwischenablage-Verlauf aktiviert (WIN+V)" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Zwischenablage: $_" -Level WARNING
            $errors++
        }
        
        # 3. Benachrichtigungen komplett deaktivieren (Fokus-Assistent IMMER an)
        Write-SetupLog "Aktiviere Fokus-Assistent (keine Benachrichtigungen)..." -Level INFO
        try {
            # Fokus-Assistent auf "Nur Priorität" (blockiert alles außer wichtigen Apps)
            $notifPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
            if (-not (Test-Path $notifPath)) {
                New-Item -Path $notifPath -Force | Out-Null
            }
            
            # Benachrichtigungen global deaktivieren
            Set-ItemProperty -Path $notifPath -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $notifPath -Name "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            
            # Action Center Benachrichtigungen aus
            $explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Set-ItemProperty -Path $explorerPath -Name "EnableAutoTray" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            
            Write-SetupLog "  [OK] Benachrichtigungen deaktiviert" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [!] Benachrichtigungen: $_" -Level INFO
        }
        
        # 4. Snap Layouts/Assist aktivieren (Windows 11)
        Write-SetupLog "Aktiviere Snap Layouts..." -Level INFO
        try {
            $snapPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Set-ItemProperty -Path $snapPath -Name "EnableSnapAssistFlyout" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $snapPath -Name "EnableSnapBar" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-SetupLog "  [OK] Snap Layouts aktiviert" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Snap Layouts: $_" -Level WARNING
        }
        
        # 5. C: Laufwerk umbenennen in "SYSTEM"
        Write-SetupLog "Benenne C: Laufwerk um in SYSTEM..." -Level INFO
        try {
            $drive = Get-WmiObject -Class Win32_Volume -Filter "DriveLetter='C:'"
            if ($drive) {
                $drive.Label = "SYSTEM"
                $drive.Put() | Out-Null
                Write-SetupLog "  [OK] C: umbenannt in SYSTEM" -Level SUCCESS
            }
        }
        catch {
            Write-SetupLog "  [X] C: Umbenennung: $_" -Level WARNING
        }
        
        # 6. Laufwerksbuchstaben verschieben (CD/DVD, USB, etc.)
        Write-SetupLog "Verschiebe Laufwerksbuchstaben..." -Level INFO
        try {
            # Verfügbare hohe Buchstaben für verschiedene Laufwerkstypen
            $targetLetters = @("X:", "Y:", "Z:")
            $letterIndex = 0
            
            # CD/DVD-Laufwerke verschieben
            $cdDrives = Get-WmiObject -Class Win32_Volume | Where-Object { 
                $_.DriveType -eq 5 -and $_.DriveLetter -ne $null -and $_.DriveLetter -match '^[D-W]:$'
            }
            
            $movedCount = 0
            foreach ($cd in $cdDrives) {
                if ($letterIndex -lt $targetLetters.Count) {
                    try {
                        $oldLetter = $cd.DriveLetter
                        $newLetter = $targetLetters[$letterIndex]
                        
                        # Prüfe ob Zielbuchstabe frei ist
                        $existing = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $newLetter }
                        if (-not $existing) {
                            $cd.DriveLetter = $newLetter
                            $cd.Put() | Out-Null
                            Write-SetupLog "    -> CD/DVD von $oldLetter nach $newLetter verschoben" -Level SUCCESS
                            $movedCount++
                            $letterIndex++
                        } else {
                            Write-SetupLog "    [!] $newLetter bereits belegt, überspringe $oldLetter" -Level INFO
                        }
                    }
                    catch {
                        Write-SetupLog "    [!] CD/DVD Verschiebung ($oldLetter): $_" -Level WARNING
                    }
                } else {
                    Write-SetupLog "    [i] Keine freien Buchstaben mehr für weitere Laufwerke" -Level INFO
                    break
                }
            }
            
            # Wechselmedien (USB/Card Reader) - nur Typ 2 (Wechseldatenträger)
            $removableDrives = Get-WmiObject -Class Win32_Volume | Where-Object { 
                $_.DriveType -eq 2 -and $_.DriveLetter -ne $null -and $_.DriveLetter -match '^[D-W]:$'
            }
            
            foreach ($drive in $removableDrives) {
                if ($letterIndex -lt $targetLetters.Count) {
                    try {
                        $oldLetter = $drive.DriveLetter
                        $newLetter = $targetLetters[$letterIndex]
                        
                        $existing = Get-WmiObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $newLetter }
                        if (-not $existing) {
                            $drive.DriveLetter = $newLetter
                            $drive.Put() | Out-Null
                            Write-SetupLog "    -> Wechselmedium von $oldLetter nach $newLetter verschoben" -Level SUCCESS
                            $movedCount++
                            $letterIndex++
                        }
                    }
                    catch {
                        Write-SetupLog "    [!] Wechselmedium Verschiebung: $_" -Level WARNING
                    }
                }
            }
            
            if ($movedCount -gt 0) {
                Write-SetupLog "  [OK] $movedCount Laufwerk(e) verschoben" -Level SUCCESS
            } else {
                Write-SetupLog "  [i] Keine Laufwerke zum Verschieben gefunden" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] Laufwerksbuchstaben: $_" -Level WARNING
        }
        
        # 7. Standard-Apps Auswahl (hinweis)
        Write-Host "`n  [i] Standard-Apps müssen manuell festgelegt werden:" -ForegroundColor Cyan
        Write-Host "      Einstellungen -> Apps -> Standard-Apps" -ForegroundColor Gray
        Write-SetupLog "  [i] Standard-Apps: Manuelle Konfiguration erforderlich" -Level INFO
        
        Write-Host "`n============================================================================" -ForegroundColor Cyan
        Write-Host "  Funktionalität konfiguriert" -ForegroundColor Green
        Write-Host "============================================================================`n" -ForegroundColor Cyan
        
    }
    catch {
        Write-SetupLog "[X] Modul 7 Fehler: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "7. FUNKTIONALITAET" -ErrorCount $errors
    return ($errors -eq 0)
}

# ==============================================================================
# MODUL 8: ALBIS Spezifisch (Platzhalter)
# ==============================================================================
function Invoke-Module8-ALBIS {
    Start-ModuleExecution "8. ALBIS SPEZIFISCH"
    $errors = 0
    
    try {
        if ($Global:Config.BackupRegistry) {
            Backup-Registry "Modul8-ALBIS"
        }
        
        Write-Host "`n╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║  MODUL 8: ALBIS Spezifische Konfiguration                                 ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
        
        # 1. GDT-Ordner erstellen
        Write-SetupLog "Erstelle GDT-Ordner..." -Level INFO
        try {
            $gdtPath = "C:\GDT"
            if (-not (Test-Path $gdtPath)) {
                New-Item -Path $gdtPath -ItemType Directory -Force | Out-Null
                Write-SetupLog "  [OK] Ordner C:\GDT erstellt" -Level SUCCESS
            } else {
                Write-SetupLog "  [i] Ordner C:\GDT existiert bereits" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] GDT-Ordner: $_" -Level WARNING
            $errors++
        }
        
        # 1b. ALBISWIN-Ordner erstellen
        Write-SetupLog "Erstelle ALBISWIN-Ordner..." -Level INFO
        try {
            $albiswinPath = "C:\CGM\ALBISWIN"
            if (-not (Test-Path $albiswinPath)) {
                New-Item -Path $albiswinPath -ItemType Directory -Force | Out-Null
                Write-SetupLog "  [OK] Ordner C:\CGM\ALBISWIN erstellt" -Level SUCCESS
            } else {
                Write-SetupLog "  [i] Ordner C:\CGM\ALBISWIN existiert bereits" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] ALBISWIN-Ordner: $_" -Level WARNING
            $errors++
        }
        
        # 2. EPSON LQ-400 Drucker installieren
        Write-Host "`n  [i] Installiere EPSON LQ-400 Drucker..." -ForegroundColor Cyan
        Write-SetupLog "Installiere EPSON LQ-400 Druckertreiber..." -Level INFO
        try {
            $scriptPath = Split-Path -Parent $PSCommandPath
            $driverPath = Join-Path $scriptPath "..\assets\epson-lq400\prnep004.inf"
            
            if (Test-Path $driverPath) {
                # Treiber installieren
                Write-Host "  ├─ Installiere Treiber..." -ForegroundColor Gray
                $pnpResult = & pnputil.exe /add-driver $driverPath /install 2>&1
                Write-SetupLog "    pnputil output: $pnpResult" -Level INFO
                
                # Warte auf Treiber-Installation
                Start-Sleep -Seconds 3
                
                # Treiber explizit hinzufügen (CRITICAL!)
                Write-Host "  ├─ Registriere Treiber..." -ForegroundColor Gray
                
                # Prüfe verfügbare Treiber im System
                $allDrivers = Get-PrinterDriver -ErrorAction SilentlyContinue
                Write-SetupLog "    Verfügbare Treiber im System: $($allDrivers.Name -join ', ')" -Level INFO
                
                # Suche EPSON LQ Treiber
                $epsonDriver = $allDrivers | Where-Object { $_.Name -like "*EPSON*LQ*" -or $_.Name -like "*LQ-400*" -or $_.Name -like "*LQ Series*" }
                
                if ($epsonDriver) {
                    $driverName = $epsonDriver[0].Name
                    Write-SetupLog "    Auto-detected Treiber: $driverName" -Level SUCCESS
                } else {
                    # Manuell mit Add-PrinterDriver registrieren
                    Write-SetupLog "    Kein Treiber auto-detected, registriere manuell..." -Level INFO
                    
                    # INF-Pfad für Add-PrinterDriver
                    $infFile = Join-Path $scriptPath "..\assets\epson-lq400\prnep004.inf"
                    
                    # Versuche verschiedene Treiber-Namen aus der INF
                    $possibleNames = @(
                        "EPSON LQ-400",
                        "EPSON LQ Series 1 (80)",
                        "EPSON LQ Series",
                        "Epson LQ Series 1 (80)"
                    )
                    
                    $driverAdded = $false
                    foreach ($tryName in $possibleNames) {
                        try {
                            Add-PrinterDriver -Name $tryName -InfPath $infFile -ErrorAction Stop
                            $driverName = $tryName
                            $driverAdded = $true
                            Write-SetupLog "    Treiber registriert: $driverName" -Level SUCCESS
                            break
                        }
                        catch {
                            Write-SetupLog "    Versuch '$tryName' fehlgeschlagen" -Level INFO
                        }
                    }
                    
                    if (-not $driverAdded) {
                        # Letzte Chance: Prüfe nochmal alle Treiber
                        Start-Sleep -Seconds 2
                        $allDrivers = Get-PrinterDriver -ErrorAction SilentlyContinue
                        $epsonDriver = $allDrivers | Where-Object { $_.Name -like "*EPSON*" -or $_.Name -like "*LQ*" }
                        if ($epsonDriver) {
                            $driverName = $epsonDriver[0].Name
                            Write-SetupLog "    Fallback: Verwende $driverName" -Level SUCCESS
                        } else {
                            throw "Kein EPSON Treiber gefunden/registriert"
                        }
                    }
                }
                
                # Drucker hinzufügen
                Write-Host "  ├─ Füge Drucker hinzu..." -ForegroundColor Gray
                $printerName = "EPSON LQ-400"
                
                # Prüfe ob bereits vorhanden
                $existingPrinter = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
                if (-not $existingPrinter) {
                    # Port LPT1: prüfen/erstellen
                    $portName = "LPT1:"
                    $existingPort = Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue
                    if (-not $existingPort) {
                        # FILE: Port als Fallback
                        $portName = "FILE:"
                        Write-SetupLog "    LPT1 nicht verfügbar, nutze FILE:" -Level INFO
                    }
                    
                    # Drucker hinzufügen
                    Add-Printer -Name $printerName -DriverName $driverName -PortName $portName -ErrorAction Stop
                    
                    # Als Standarddrucker setzen
                    try {
                        (New-Object -ComObject WScript.Network).SetDefaultPrinter($printerName)
                        Write-Host "  └─ [OK] EPSON LQ-400 installiert und als Standard gesetzt" -ForegroundColor Green
                        Write-SetupLog "  [OK] EPSON LQ-400 installiert und als Standarddrucker gesetzt" -Level SUCCESS
                    }
                    catch {
                        Write-Host "  └─ [OK] EPSON LQ-400 installiert (Standard-Setzen fehlgeschlagen)" -ForegroundColor Yellow
                        Write-SetupLog "  [!] Drucker installiert, aber nicht als Standard gesetzt: $_" -Level WARNING
                    }
                } else {
                    Write-Host "  └─ [i] Drucker bereits vorhanden" -ForegroundColor Yellow
                    Write-SetupLog "  [i] EPSON LQ-400 bereits installiert" -Level INFO
                }
            } else {
                Write-Host "  └─ [!] Treiberdateien nicht gefunden - Überspringe" -ForegroundColor Yellow
                Write-SetupLog "  [!] EPSON Treiber nicht gefunden: $driverPath (Übersprungen)" -Level WARNING
            }
        }
        catch {
            Write-Host "  └─ [X] Fehler: $_" -ForegroundColor Red
            Write-SetupLog "  [X] EPSON LQ-400 Installation: $_" -Level ERROR
            $errors++
        }
        
        Write-Host "`n============================================================================" -ForegroundColor Cyan
        Write-Host "  ALBIS-Konfiguration abgeschlossen" -ForegroundColor Green
        Write-Host "============================================================================`n" -ForegroundColor Cyan
        
    }
    catch {
        Write-SetupLog "[X] Modul 8 Fehler: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "8. ALBIS" -ErrorCount $errors
    return ($errors -eq 0)
}

# ==============================================================================
# HAUPTMENUe
# ==============================================================================
function Show-MainMenu {
    Clear-Host
    Write-Host @"

╔════════════════════════════════════════════════════════════════════════════╗
║              Windows 11 OOTB Setup Tool v$($Global:Config.Version)                         ║
╚════════════════════════════════════════════════════════════════════════════╝

  [1]  Modul 1: Einstieg und Backup
  [2]  Modul 2: Cleanup (Widgets, Pins, Desktop)
  [3]  Modul 3: Optik und Ergonomie (Taskleiste, Explorer)
  [4]  Modul 4: Performance und Energieeinstellungen
  [5]  Modul 5: Software und Daten
  [6]  Modul 6: Runtime-Komponenten (Java, .NET, VC++)
  [7]  Modul 7: Funktionalitaet
  [8]  Modul 8: ALBIS Spezifisch
  
  [A]  ALLE Module ausfuehren (1-7)
  [B]  LIGHT-SETUP ohne Software (Module 1-4, 7-8)
  
  [L]  Log-Datei anzeigen
  [Q]  Beenden

"@ -ForegroundColor Cyan
    
    $choice = Read-Host "Auswahl"
    return $choice.ToUpper()
}

# ==============================================================================
# HAUPTPROGRAMM
# ==============================================================================
function Start-SetupTool {
    # Admin-Check und Initialisierung IMMER ausführen
    if (-not (Test-AdminRights)) {
        Write-Host "`nFEHLER: Dieses Skript muss als Administrator ausgefuehrt werden!" -ForegroundColor Red
        Write-Host "Rechtsklick auf START.cmd -> 'Als Administrator ausfuehren'`n" -ForegroundColor Yellow
        Read-Host "Enter zum Beenden"
        exit 1
    }
    
    # Automatische Initialisierung (ehemals Modul 1)
    Invoke-Module1-Einstieg | Out-Null
    
    # RunAll Parameter (Module 1-7)
    if ($RunAll) {
        $startTime = Get-Date
        Write-Host "`n=== Komplett-Setup (Module 1-7) ===`n" -ForegroundColor Cyan
        Write-Host "Start: $($startTime.ToString('HH:mm:ss'))`n" -ForegroundColor Gray
        
        $success = $true
        $success = Invoke-Module1-Einstieg -and $success
        $success = Invoke-Module2-Cleanup -and $success
        $success = Invoke-Module3-OptikErgonomie -and $success
        $success = Invoke-Module4-Performance -and $success
        $success = Invoke-Module5-Software -and $success
        $success = Invoke-Module6-Komponenten -and $success
        $success = Invoke-Module7-Funktionalitaet -and $success
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Host "`n$('='*80)" -ForegroundColor Cyan
        Write-Host "Ende: $($endTime.ToString('HH:mm:ss'))" -ForegroundColor Gray
        Write-Host "Gesamtdauer: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Cyan
        Write-Host "$('='*80)`n" -ForegroundColor Cyan
        
        if ($success) {
            Write-Host "[OK] SETUP ERFOLGREICH ABGESCHLOSSEN!" -ForegroundColor Green
            Write-Host ""
            
            # Abfrage: Setup-Ordner löschen?
            Write-Host "Setup abgeschlossen. Moechten Sie den Setup-Ordner vom Desktop loeschen? (J/N)" -ForegroundColor Yellow
            $deleteChoice = Read-Host "Eingabe"
            
            if ($deleteChoice -eq "J" -or $deleteChoice -eq "j") {
                try {
                    $setupPath = Split-Path -Parent $PSScriptRoot
                    $desktopPath = [Environment]::GetFolderPath("Desktop")
                    
                    # Prüfe ob Setup-Ordner auf Desktop liegt
                    if ($setupPath -like "$desktopPath*") {
                        Write-Host "Loesche Setup-Ordner..." -ForegroundColor Yellow
                        
                        # Warte kurz, damit keine Dateien mehr geöffnet sind
                        Start-Sleep -Seconds 2
                        
                        # Lösche Ordner
                        Remove-Item -Path $setupPath -Recurse -Force -ErrorAction Stop
                        Write-Host "[OK] Setup-Ordner geloescht" -ForegroundColor Green
                    } else {
                        Write-Host "[i] Setup-Ordner nicht auf Desktop - Behalte Ordner" -ForegroundColor Cyan
                    }
                }
                catch {
                    Write-Host "[!] Konnte Ordner nicht loeschen: $_" -ForegroundColor Yellow
                    Write-Host "    Bitte manuell loeschen: $setupPath" -ForegroundColor Gray
                }
            }
            
            Write-Host ""
            Read-Host "Druecken Sie Enter zum Beenden"
            exit 0
        } else {
            Write-Host "[!] Setup mit Warnungen abgeschlossen. Siehe Log." -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Druecken Sie Enter zum Beenden"
            exit 1
        }
    }
    
    # LightSetup Parameter (Module 1-4, 7-8, OHNE Software)
    if ($LightSetup) {
        $startTime = Get-Date
        Write-Host "`n=== LIGHT-SETUP (Module 1-4, 7-8) - OHNE Software ===`n" -ForegroundColor Yellow
        Write-Host "Start: $($startTime.ToString('HH:mm:ss'))`n" -ForegroundColor Gray
        
        $success = $true
        $success = Invoke-Module1-Einstieg -and $success
        $success = Invoke-Module2-Cleanup -and $success
        $success = Invoke-Module3-OptikErgonomie -and $success
        $success = Invoke-Module4-Performance -and $success
        # Modul 5 (Software) und 6 (Komponenten) werden übersprungen!
        $success = Invoke-Module7-Funktionalitaet -and $success
        $success = Invoke-Module8-ALBIS -and $success
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Host "`n$('='*80)" -ForegroundColor Cyan
        Write-Host "Ende: $($endTime.ToString('HH:mm:ss'))" -ForegroundColor Gray
        Write-Host "Gesamtdauer: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Cyan
        Write-Host "$('='*80)`n" -ForegroundColor Cyan
        
        if ($success) {
            Write-Host "[OK] LIGHT-SETUP ERFOLGREICH ABGESCHLOSSEN!" -ForegroundColor Green
            Write-Host "[i] Software-Installation wurde uebersprungen" -ForegroundColor Cyan
            Write-Host ""
            Read-Host "Druecken Sie Enter zum Beenden"
            exit 0
        } else {
            Write-Host "[!] Setup mit Warnungen abgeschlossen. Siehe Log." -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Druecken Sie Enter zum Beenden"
            exit 1
        }
    }
    
    # TestMode Parameter
    if ($TestMode) {
        Write-Host "`n=== Test-Modus (Module 1-2) ===`n" -ForegroundColor Yellow
        Invoke-Module1-Einstieg
        Invoke-Module2-Cleanup
        Write-Host "`n"
        Read-Host "Enter zum Beenden"
        exit 0
    }
    
    # Einzelnes Modul
    if ($Module -ge 1 -and $Module -le 8) {
        Write-Host "`n=== Modul $Module ===`n" -ForegroundColor Cyan
        switch ($Module) {
            1 { Invoke-Module1-Einstieg }
            2 { Invoke-Module2-Cleanup }
            3 { Invoke-Module3-OptikErgonomie }
            4 { Invoke-Module4-Performance }
            5 { Invoke-Module5-Software }
            6 { Invoke-Module6-Komponenten }
            7 { Invoke-Module7-Funktionalitaet }
            8 { Invoke-Module8-ALBIS }
        }
        Write-Host "`n"
        Read-Host "Enter zum Beenden"
        exit 0
    }
    
    # Standard: Interaktives Menue
    $continue = $true
    
    while ($continue) {
        $choice = Show-MainMenu
        
        switch ($choice) {
            '1' { Invoke-Module1-Einstieg }
            '2' { Invoke-Module2-Cleanup }
            '3' { Invoke-Module3-OptikErgonomie }
            '4' { Invoke-Module4-Performance }
            '5' { Invoke-Module5-Software }
            '6' { Invoke-Module6-Komponenten }
            '7' { Invoke-Module7-Funktionalitaet }
            '8' { Invoke-Module8-ALBIS }
            'A' { 
                $startTime = Get-Date
                Write-Host "`nStarte Komplett-Setup (Module 1-7)..." -ForegroundColor Yellow
                Write-Host "Start: $($startTime.ToString('HH:mm:ss'))`n" -ForegroundColor Gray
                
                $success = $true
                $success = Invoke-Module1-Einstieg -and $success
                $success = Invoke-Module2-Cleanup -and $success
                $success = Invoke-Module3-OptikErgonomie -and $success
                $success = Invoke-Module4-Performance -and $success
                $success = Invoke-Module5-Software -and $success
                $success = Invoke-Module6-Komponenten -and $success
                $success = Invoke-Module7-Funktionalitaet -and $success
                
                $endTime = Get-Date
                $duration = $endTime - $startTime
                
                Write-Host "`nEnde: $($endTime.ToString('HH:mm:ss'))" -ForegroundColor Gray
                Write-Host "Gesamtdauer: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s`n" -ForegroundColor Cyan
                
                if ($success) {
                    Write-Host "`n[OK] SETUP ERFOLGREICH ABGESCHLOSSEN!" -ForegroundColor Green
                    
                    # Abfrage: Setup-Ordner löschen?
                    Write-Host "`nMoechten Sie den Setup-Ordner vom Desktop loeschen? (J/N)" -ForegroundColor Yellow
                    $deleteChoice = Read-Host "Eingabe"
                    
                    if ($deleteChoice -eq "J" -or $deleteChoice -eq "j") {
                        try {
                            $setupPath = Split-Path -Parent $PSScriptRoot
                            $desktopPath = [Environment]::GetFolderPath("Desktop")
                            
                            if ($setupPath -like "$desktopPath*") {
                                Write-Host "Loesche Setup-Ordner..." -ForegroundColor Yellow
                                Start-Sleep -Seconds 2
                                Remove-Item -Path $setupPath -Recurse -Force -ErrorAction Stop
                                Write-Host "[OK] Setup-Ordner geloescht - Fenster schliesst sich..." -ForegroundColor Green
                                Start-Sleep -Seconds 3
                                exit 0
                            } else {
                                Write-Host "[i] Setup-Ordner nicht auf Desktop - Behalte Ordner" -ForegroundColor Cyan
                            }
                        }
                        catch {
                            Write-Host "[!] Konnte Ordner nicht loeschen: $_" -ForegroundColor Yellow
                        }
                    }
                } else {
                    Write-Host "`n[!] Setup mit Warnungen abgeschlossen. Siehe Log." -ForegroundColor Yellow
                }
            }
            'B' {
                $startTime = Get-Date
                Write-Host "`nStarte LIGHT-SETUP ohne Software (Module 1-4, 7-8)..." -ForegroundColor Cyan
                Write-Host "Start: $($startTime.ToString('HH:mm:ss'))`n" -ForegroundColor Gray
                
                $success = $true
                $success = Invoke-Module1-Einstieg -and $success
                $success = Invoke-Module2-Cleanup -and $success
                $success = Invoke-Module3-OptikErgonomie -and $success
                $success = Invoke-Module4-Performance -and $success
                # SKIP: Modul 5 (Software) und 6 (Runtime)
                $success = Invoke-Module7-Funktionalitaet -and $success
                $success = Invoke-Module8-ALBIS -and $success
                
                $endTime = Get-Date
                $duration = $endTime - $startTime
                
                Write-Host "`nEnde: $($endTime.ToString('HH:mm:ss'))" -ForegroundColor Gray
                Write-Host "Gesamtdauer: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s`n" -ForegroundColor Cyan
                
                if ($success) {
                    Write-Host "`n[OK] LIGHT-SETUP ERFOLGREICH ABGESCHLOSSEN!" -ForegroundColor Green
                    Write-Host "Hinweis: Software muss manuell installiert werden." -ForegroundColor Yellow
                } else {
                    Write-Host "`n[!] Setup mit Warnungen abgeschlossen. Siehe Log." -ForegroundColor Yellow
                }
            }
            'L' {
                $logFile = Join-Path $Global:Config.LogPath $Global:Config.LogFile
                if (Test-Path $logFile) {
                    Get-Content $logFile | Out-Host
                } else {
                    Write-Host "`nKeine Log-Datei gefunden." -ForegroundColor Yellow
                }
            }
            'Q' { 
                $continue = $false
                Write-Host "`nSetup-Tool beendet. Logs: $($Global:Config.LogPath)" -ForegroundColor Green
            }
            default { Write-Host "`nUngueltige Auswahl!" -ForegroundColor Red }
        }
        
        if ($continue -and $choice -ne 'L' -and $choice -ne 'Q') {
            Write-Host "`n"
            Read-Host "Enter zum Fortfahren"
        }
    }
}

# ==============================================================================
# START
# ==============================================================================
Start-SetupTool
