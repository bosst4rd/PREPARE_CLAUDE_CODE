# ==============================================================================
# CORE MODULES - Hauptmodule fuer Windows 11 Setup
# Basierend auf Win11-Setup.ps1 von eXpletus IT-Systemhaus
# ==============================================================================

# Modul-interne Konfiguration (wird bei Bedarf erstellt)
function Get-ModuleConfig {
    return @{
        LogPath = "C:\CGM\Logs"
        LogFile = "Win11-Setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
        CGMFolder = "C:\CGM"
        BackupRegistry = $true
        Version = "1.3"
    }
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

    $cfg = Get-ModuleConfig
    if (-not (Test-Path $cfg.LogPath)) {
        New-Item -Path $cfg.LogPath -ItemType Directory -Force | Out-Null
    }
    $logFile = Join-Path $cfg.LogPath $cfg.LogFile
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    # Keine Rueckgabe - verhindert Pipeline-Stoerung
}

function Start-ModuleExecution {
    param([string]$ModuleName)
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

function Backup-Registry {
    param([string]$BackupName)

    try {
        $cfg = Get-ModuleConfig
        $backupPath = Join-Path $cfg.CGMFolder "Registry-Backups"
        if (-not (Test-Path $backupPath)) {
            New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        }

        $fileName = "Registry-Backup-$BackupName-$(Get-Date -Format 'yyyyMMdd-HHmmss').reg"
        $filePath = Join-Path $backupPath $fileName

        & cmd /c "reg export HKCU `"$filePath`" /y >nul 2>&1"
        return $true
    }
    catch {
        return $false
    }
}

# ==============================================================================
# MODUL 1: EINSTIEG - Admin-Pruefung und Initialisierung
# ==============================================================================
function Invoke-Module1-Einstieg {
    Start-ModuleExecution "1. EINSTIEG - Admin-Pruefung und Initialisierung"
    $errors = 0
    $results = @()
    $cfg = Get-ModuleConfig

    try {
        # Admin-Check
        if (-not (Test-AdminRights)) {
            $results += "[ERROR] Keine Administrator-Rechte"
            $errors++
        } else {
            $results += "[OK] Administrator-Rechte bestaetigt"
        }

        # CGM-Ordner erstellen
        if (-not (Test-Path $cfg.CGMFolder)) {
            New-Item -Path $cfg.CGMFolder -ItemType Directory -Force | Out-Null
            $results += "[OK] Ordner erstellt: $($cfg.CGMFolder)"
        } else {
            $results += "[OK] Ordner existiert: $($cfg.CGMFolder)"
        }

        # Log-Ordner erstellen
        if (-not (Test-Path $cfg.LogPath)) {
            New-Item -Path $cfg.LogPath -ItemType Directory -Force | Out-Null
            $results += "[OK] Log-Ordner erstellt: $($cfg.LogPath)"
        }

        # Registry-Backup
        if ($cfg.BackupRegistry) {
            $backupResult = Backup-Registry "Initial"
            if ($backupResult) {
                $results += "[OK] Registry-Backup erstellt"
            }
        }

        # System-Info
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $results += "[INFO] System: $($os.Caption) Build $($os.BuildNumber)"
        }
        $results += "[INFO] Computer: $env:COMPUTERNAME | User: $env:USERNAME"
    }
    catch {
        $results += "[ERROR] Fehler: $_"
        $errors++
    }

    Complete-ModuleExecution "1. EINSTIEG" -ErrorCount $errors
    return @{
        Success = ($errors -eq 0)
        Results = $results
        Errors = $errors
    }
}

# ==============================================================================
# MODUL 2: CLEANUP - Widgets, Pins, Desktop
# ==============================================================================
function Invoke-Module2-Cleanup {
    Start-ModuleExecution "2. CLEANUP - Widgets, Pins, Desktop"
    $errors = 0
    $results = @()
    $cfg = Get-ModuleConfig

    try {
        if ($cfg.BackupRegistry) {
            $null = Backup-Registry "Modul2-Cleanup"
        }

        # ======================================================================
        # WIDGETS ENTFERNEN (mehrere Methoden)
        # ======================================================================
        try {
            $changedCount = 0

            # Methode 1: User Registry
            $widgetsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $widgetsPath)) {
                New-Item -Path $widgetsPath -Force | Out-Null
            }
            Set-ItemProperty -Path $widgetsPath -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $changedCount++

            # Methode 2: Gruppenrichtlinie
            try {
                $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
                if (-not (Test-Path $policyPath)) {
                    New-Item -Path $policyPath -Force | Out-Null
                }
                Set-ItemProperty -Path $policyPath -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force
                $changedCount++
            } catch {}

            # Methode 3: Feeds/Wetter deaktivieren
            try {
                $feedsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
                if (-not (Test-Path $feedsPath)) {
                    New-Item -Path $feedsPath -Force | Out-Null
                }
                Set-ItemProperty -Path $feedsPath -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $feedsPath -Name "IsFeedsAvailable" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $changedCount++
            } catch {}

            # Task View Button entfernen
            Set-ItemProperty -Path $widgetsPath -Name "ShowTaskViewButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $changedCount++

            $results += "[OK] Widgets/News/Task View deaktiviert ($changedCount Aenderungen)"
        }
        catch {
            $results += "[WARNING] Widgets: $_"
        }

        # ======================================================================
        # COPILOT ENTFERNEN
        # ======================================================================
        try {
            $copilotPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Set-ItemProperty -Path $copilotPath -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            $copilotPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
            if (-not (Test-Path $copilotPolicyPath)) {
                New-Item -Path $copilotPolicyPath -Force | Out-Null
            }
            Set-ItemProperty -Path $copilotPolicyPath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
            $results += "[OK] Copilot deaktiviert"
        }
        catch {
            $results += "[WARNING] Copilot: $_"
        }

        # ======================================================================
        # ONEDRIVE DEINSTALLIEREN
        # ======================================================================
        try {
            # Aus Autostart entfernen
            $runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            Remove-ItemProperty -Path $runPath -Name "OneDrive" -ErrorAction SilentlyContinue

            # OneDrive Prozess beenden
            Get-Process -Name OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1

            # OneDrive deinstallieren
            $oneDriveSetup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
            if (-not (Test-Path $oneDriveSetup)) {
                $oneDriveSetup = "$env:SystemRoot\System32\OneDriveSetup.exe"
            }

            if (Test-Path $oneDriveSetup) {
                Start-Process -FilePath $oneDriveSetup -ArgumentList "/uninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                $results += "[OK] OneDrive deinstalliert"
            } else {
                $results += "[OK] OneDrive Autostart deaktiviert"
            }

            # OneDrive-Ordner entfernen
            $oneDriveFolder = "$env:USERPROFILE\OneDrive"
            if (Test-Path $oneDriveFolder) {
                Remove-Item -Path $oneDriveFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            $results += "[WARNING] OneDrive: $_"
        }

        # ======================================================================
        # SUCHE ENTFERNEN
        # ======================================================================
        try {
            $searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
            if (-not (Test-Path $searchPath)) {
                New-Item -Path $searchPath -Force | Out-Null
            }
            Set-ItemProperty -Path $searchPath -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -Force
            $results += "[OK] Suche deaktiviert"
        }
        catch {
            $results += "[WARNING] Suche: $_"
        }

        # ======================================================================
        # TEAMS/CHAT ENTFERNEN
        # ======================================================================
        try {
            # Chat Icon aus Taskbar
            $chatPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Set-ItemProperty -Path $chatPath -Name "TaskbarMn" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            # Teams Auto-Start deaktivieren
            $teamsStartupPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            Remove-ItemProperty -Path $teamsStartupPath -Name "com.squirrel.Teams.Teams" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $teamsStartupPath -Name "Microsoft Teams" -ErrorAction SilentlyContinue

            # Teams UWP App deinstallieren
            try {
                $teamsApp = Get-AppxPackage -Name "*Teams*" -ErrorAction SilentlyContinue
                if ($teamsApp) {
                    $teamsApp | Remove-AppxPackage -ErrorAction SilentlyContinue
                }
            } catch {}

            $results += "[OK] Teams/Chat entfernt"
        }
        catch {
            $results += "[WARNING] Teams: $_"
        }

        # ======================================================================
        # DESKTOP BEREINIGEN
        # ======================================================================
        try {
            $desktop = [Environment]::GetFolderPath('Desktop')
            $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
            $shortcutsToRemove = @(
                'Microsoft Edge.lnk',
                'Microsoft Store.lnk',
                'Outlook.lnk',
                'Mail.lnk',
                'Google Chrome.lnk',
                'Firefox.lnk',
                'Teams.lnk',
                'OneDrive.lnk',
                'Benutzer.lnk',
                'Geraete.lnk'
            )
            $removedCount = 0

            foreach ($shortcut in $shortcutsToRemove) {
                $path = Join-Path $desktop $shortcut
                if (Test-Path $path) {
                    Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
                    $removedCount++
                }
                $publicPath = Join-Path $publicDesktop $shortcut
                if (Test-Path $publicPath) {
                    Remove-Item -Path $publicPath -Force -ErrorAction SilentlyContinue
                    $removedCount++
                }
            }
            $results += "[OK] Desktop bereinigt ($removedCount Verknuepfungen entfernt)"
        }
        catch {
            $results += "[WARNING] Desktop: $_"
        }

        # ======================================================================
        # DESKTOP-ICONS AUSBLENDEN
        # ======================================================================
        try {
            $hideIconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
            if (-not (Test-Path $hideIconsPath)) {
                New-Item -Path $hideIconsPath -Force | Out-Null
            }
            # Papierkorb ausblenden
            Set-ItemProperty -Path $hideIconsPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 1 -Type DWord -Force
            # Netzwerk ausblenden
            Set-ItemProperty -Path $hideIconsPath -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 1 -Type DWord -Force
            # Benutzerordner ausblenden
            Set-ItemProperty -Path $hideIconsPath -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 1 -Type DWord -Force
            # Systemsteuerung ausblenden
            Set-ItemProperty -Path $hideIconsPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            $results += "[OK] Desktop-Icons ausgeblendet"
        }
        catch {
            $results += "[WARNING] Desktop-Icons: $_"
        }

        # ======================================================================
        # DRUCKER ENTFERNEN
        # ======================================================================
        try {
            $fax = Get-Printer -Name "Fax" -ErrorAction SilentlyContinue
            if ($fax) {
                Remove-Printer -Name "Fax" -ErrorAction SilentlyContinue
                $results += "[OK] Fax-Drucker entfernt"
            }

            $xps = Get-Printer -Name "Microsoft XPS Document Writer" -ErrorAction SilentlyContinue
            if ($xps) {
                Remove-Printer -Name "Microsoft XPS Document Writer" -ErrorAction SilentlyContinue
                $results += "[OK] XPS-Drucker entfernt"
            }
        }
        catch {
            $results += "[WARNING] Drucker: $_"
        }
    }
    catch {
        $results += "[ERROR] Kritischer Fehler: $_"
        $errors++
    }

    Complete-ModuleExecution "2. CLEANUP" -ErrorCount $errors
    return @{
        Success = ($errors -eq 0)
        Results = $results
        Errors = $errors
    }
}

# ==============================================================================
# MODUL 3: OPTIK und ERGONOMIE
# ==============================================================================
function Invoke-Module3-OptikErgonomie {
    Start-ModuleExecution "3. OPTIK und ERGONOMIE"
    $errors = 0
    $results = @()
    $cfg = Get-ModuleConfig

    try {
        if ($cfg.BackupRegistry) {
            $null = Backup-Registry "Modul3-Optik"
        }

        # ======================================================================
        # TASKLEISTE KONFIGURIEREN
        # ======================================================================
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
            $results += "[OK] Taskleiste linksbuendig, nicht gruppiert"
        }
        catch {
            $results += "[WARNING] Taskleiste: $_"
        }

        # ======================================================================
        # EXPLORER KONFIGURIEREN
        # ======================================================================
        try {
            $explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            # Dateierweiterungen einblenden
            Set-ItemProperty -Path $explorerPath -Name "HideFileExt" -Value 0 -Type DWord -Force
            # Ausgeblendete Dateien anzeigen
            Set-ItemProperty -Path $explorerPath -Name "Hidden" -Value 1 -Type DWord -Force
            # Vollstaendigen Pfad anzeigen
            Set-ItemProperty -Path $explorerPath -Name "FullPathAddress" -Value 1 -Type DWord -Force
            $results += "[OK] Explorer: Erweiterungen, versteckte Dateien, vollstaendiger Pfad"
        }
        catch {
            $results += "[WARNING] Explorer: $_"
        }

        # ======================================================================
        # BILDSCHIRMSCHONER DEAKTIVIEREN
        # ======================================================================
        try {
            $screensaverPath = "HKCU:\Control Panel\Desktop"
            Set-ItemProperty -Path $screensaverPath -Name "ScreenSaveActive" -Value "0" -Force
            Set-ItemProperty -Path $screensaverPath -Name "ScreenSaveTimeOut" -Value "0" -Force
            $results += "[OK] Bildschirmschoner deaktiviert"
        }
        catch {
            $results += "[WARNING] Bildschirmschoner: $_"
        }

        # ======================================================================
        # LOCKSCREEN KONFIGURIEREN
        # ======================================================================
        try {
            $cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Set-ItemProperty -Path $cdmPath -Name "RotatingLockScreenEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdmPath -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338387Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $results += "[OK] Lockscreen-Werbung deaktiviert"
        }
        catch {
            $results += "[WARNING] Lockscreen: $_"
        }

        # ======================================================================
        # DESKTOP-SYMBOLE (Dieser PC anzeigen, sortiert)
        # ======================================================================
        try {
            # Desktop-Icons VIEW aktivieren
            $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Set-ItemProperty -Path $advancedPath -Name "HideIcons" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            $desktopIconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
            if (-not (Test-Path $desktopIconsPath)) {
                New-Item -Path $desktopIconsPath -Force | Out-Null
            }

            # Sequentielles Einblenden fuer korrekte Sortierung
            # Schritt 1: ALLE Icons ausblenden
            Set-ItemProperty -Path $desktopIconsPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 1 -Type DWord -Force  # Dieser PC
            Set-ItemProperty -Path $desktopIconsPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 1 -Type DWord -Force  # Papierkorb
            Start-Sleep -Milliseconds 200

            # Schritt 2: Dieser PC einblenden (oben)
            Set-ItemProperty -Path $desktopIconsPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -Type DWord -Force
            Start-Sleep -Milliseconds 100

            # Schritt 3: Papierkorb einblenden (unten)
            Set-ItemProperty -Path $desktopIconsPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 0 -Type DWord -Force

            # Desktop-Icon Anordnung: Am Raster, KEIN Auto-Arrange
            $desktopBagPath = "HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop"
            if (-not (Test-Path $desktopBagPath)) {
                New-Item -Path $desktopBagPath -Force | Out-Null
            }
            Set-ItemProperty -Path $desktopBagPath -Name "IconSize" -Value 48 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $desktopBagPath -Name "FFlags" -Value 1075839488 -Type DWord -Force -ErrorAction SilentlyContinue

            # AutoArrange deaktivieren
            Set-ItemProperty -Path $advancedPath -Name "AutoArrange" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            $results += "[OK] Desktop-Symbole: Dieser PC + Papierkorb (sortiert, am Raster)"
        }
        catch {
            $results += "[WARNING] Desktop-Symbole: $_"
        }

        # ======================================================================
        # HINTERGRUND: SCHWARZ (EINFARBIG)
        # ======================================================================
        try {
            $wallpaperPath = "HKCU:\Control Panel\Desktop"
            # Einfarbiger Hintergrund (keine Tapete)
            Set-ItemProperty -Path $wallpaperPath -Name "WallPaper" -Value "" -Force
            # Schwarze Hintergrundfarbe (RGB: 0 0 0)
            $colorsPath = "HKCU:\Control Panel\Colors"
            Set-ItemProperty -Path $colorsPath -Name "Background" -Value "0 0 0" -Force
            # Desktop Refresh
            Add-Type -TypeDefinition @"
                using System.Runtime.InteropServices;
                public class Wallpaper {
                    [DllImport("user32.dll", CharSet = CharSet.Auto)]
                    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
                }
"@ -ErrorAction SilentlyContinue
            [Wallpaper]::SystemParametersInfo(0x0014, 0, "", 0x0001 -bor 0x0002) | Out-Null
            $results += "[OK] Hintergrund: Schwarz (einfarbig)"
        }
        catch {
            $results += "[WARNING] Hintergrund: $_"
        }

        # ======================================================================
        # TRANSPARENZ DEAKTIVIEREN
        # ======================================================================
        try {
            $personalizePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
            Set-ItemProperty -Path $personalizePath -Name "EnableTransparency" -Value 0 -Type DWord -Force
            $results += "[OK] Transparenz deaktiviert"
        }
        catch {
            $results += "[WARNING] Transparenz: $_"
        }

        # ======================================================================
        # ANIMATIONEN REDUZIEREN
        # ======================================================================
        try {
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary -Force
            $results += "[OK] Visuelle Effekte reduziert"
        }
        catch {
            $results += "[WARNING] Animationen: $_"
        }

        # ======================================================================
        # ARBEITSGRUPPE: EXPLETUS
        # ======================================================================
        try {
            $currentWorkgroup = (Get-WmiObject Win32_ComputerSystem).Workgroup
            if ($currentWorkgroup -ne "EXPLETUS") {
                $computer = Get-WmiObject Win32_ComputerSystem
                $null = $computer.JoinDomainOrWorkgroup("EXPLETUS", $null, $null, $null, 1)
                $results += "[OK] Arbeitsgruppe: EXPLETUS (Neustart erforderlich)"
            } else {
                $results += "[OK] Arbeitsgruppe bereits EXPLETUS"
            }
        }
        catch {
            $results += "[WARNING] Arbeitsgruppe: $_"
        }
    }
    catch {
        $results += "[ERROR] Kritischer Fehler: $_"
        $errors++
    }

    Complete-ModuleExecution "3. OPTIK und ERGONOMIE" -ErrorCount $errors
    return @{
        Success = ($errors -eq 0)
        Results = $results
        Errors = $errors
    }
}

# ==============================================================================
# MODUL 4: ENERGIE und PERFORMANCE
# ==============================================================================
function Invoke-Module4-EnergiePerformance {
    Start-ModuleExecution "4. ENERGIE und PERFORMANCE"
    $errors = 0
    $results = @()
    $cfg = Get-ModuleConfig

    try {
        if ($cfg.BackupRegistry) {
            $null = Backup-Registry "Modul4-Energie"
        }

        # ======================================================================
        # AUTOSTART BEREINIGEN
        # ======================================================================
        try {
            $programsToRemove = @('OneDrive', 'Teams', 'Skype', 'Copilot')
            $removedCount = 0

            $hkcuRun = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            $items = Get-ItemProperty -Path $hkcuRun -ErrorAction SilentlyContinue
            if ($items) {
                foreach ($program in $programsToRemove) {
                    $items.PSObject.Properties | Where-Object { $_.Name -like "*$program*" } | ForEach-Object {
                        Remove-ItemProperty -Path $hkcuRun -Name $_.Name -ErrorAction SilentlyContinue
                        $removedCount++
                    }
                }
            }

            # OneDrive Sync deaktivieren
            $onedrivePath = "HKCU:\Software\Microsoft\OneDrive"
            if (Test-Path $onedrivePath) {
                Set-ItemProperty -Path $onedrivePath -Name "DisableFileSyncNGSC" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            }

            $results += "[OK] Autostart bereinigt ($removedCount Programme)"
        }
        catch {
            $results += "[WARNING] Autostart: $_"
        }

        # ======================================================================
        # ENERGIEOPTIONEN
        # ======================================================================
        try {
            # Hoechstleistung aktivieren
            $highPerf = powercfg /list | Select-String "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
            if ($highPerf) {
                powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
                $results += "[OK] Energieplan: Hoechstleistung aktiviert"
            } else {
                powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
                $results += "[OK] Energieplan: Ausbalanciert (Hoechstleistung nicht verfuegbar)"
            }

            # Alle Timeouts auf 0
            powercfg /change monitor-timeout-ac 0
            powercfg /change monitor-timeout-dc 0
            powercfg /change disk-timeout-ac 0
            powercfg /change standby-timeout-ac 0
            powercfg /change standby-timeout-dc 0
            powercfg /change hibernate-timeout-ac 0
            $results += "[OK] Alle Timeouts auf 0 (nie ausschalten)"
        }
        catch {
            $results += "[WARNING] Energieplan: $_"
        }

        # ======================================================================
        # SCHNELLSTART UND HIBERNATE DEAKTIVIEREN
        # ======================================================================
        try {
            $powerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
            Set-ItemProperty -Path $powerPath -Name "HiberbootEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            powercfg /hibernate off 2>$null
            $results += "[OK] Schnellstart und Ruhezustand deaktiviert"
        }
        catch {
            $results += "[WARNING] Hibernate: $_"
        }

        # ======================================================================
        # UAC MINIMIEREN
        # ======================================================================
        try {
            $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            Set-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $uacPath -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $uacPath -Name "EnableLUA" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            $results += "[OK] UAC: Nie benachrichtigen"
        }
        catch {
            $results += "[WARNING] UAC: $_"
        }

        # ======================================================================
        # STANDARDDRUCKER-VERWALTUNG DEAKTIVIEREN
        # ======================================================================
        try {
            $printerPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows"
            if (-not (Test-Path $printerPath)) {
                New-Item -Path $printerPath -Force | Out-Null
            }
            Set-ItemProperty -Path $printerPath -Name "LegacyDefaultPrinterMode" -Value 1 -Type DWord -Force
            $results += "[OK] Standarddrucker: Benutzer verwaltet (nicht Windows)"
        }
        catch {
            $results += "[WARNING] Standarddrucker: $_"
        }

        # ======================================================================
        # USB SELECTIVE SUSPEND DEAKTIVIEREN
        # ======================================================================
        try {
            $activePlan = (powercfg /getactivescheme).Split()[3]
            & powercfg /setacvalueindex $activePlan 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
            & powercfg /setdcvalueindex $activePlan 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
            & powercfg /setactive $activePlan
            $results += "[OK] USB Selective Suspend deaktiviert"
        }
        catch {
            $results += "[WARNING] USB Suspend: $_"
        }

        # ======================================================================
        # NETZWERKADAPTER OPTIMIEREN
        # ======================================================================
        try {
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
            $optimizedCount = 0
            foreach ($adapter in $adapters) {
                $instanceId = $adapter.InterfaceGuid
                $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
                $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue

                foreach ($key in $subKeys) {
                    $guid = Get-ItemProperty -Path $key.PSPath -Name "NetCfgInstanceId" -ErrorAction SilentlyContinue
                    if ($guid.NetCfgInstanceId -eq $instanceId) {
                        Set-ItemProperty -Path $key.PSPath -Name "PnPCapabilities" -Value 24 -Type DWord -ErrorAction SilentlyContinue
                        $optimizedCount++
                        break
                    }
                }
            }
            $results += "[OK] Netzwerkadapter optimiert ($optimizedCount Adapter)"
        }
        catch {
            $results += "[WARNING] Netzwerkadapter: $_"
        }

        # ======================================================================
        # ZWISCHENABLAGE-HISTORIE
        # ======================================================================
        try {
            $clipboardPath = "HKCU:\Software\Microsoft\Clipboard"
            if (-not (Test-Path $clipboardPath)) {
                New-Item -Path $clipboardPath -Force | Out-Null
            }
            Set-ItemProperty -Path $clipboardPath -Name "EnableClipboardHistory" -Value 1 -Type DWord -Force
            $results += "[OK] Zwischenablage-Historie aktiviert"
        }
        catch {
            $results += "[WARNING] Zwischenablage: $_"
        }

        # ======================================================================
        # NUMLOCK BEIM START
        # ======================================================================
        try {
            $numLockPath = "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard"
            Set-ItemProperty -Path $numLockPath -Name "InitialKeyboardIndicators" -Value "2" -Force -ErrorAction SilentlyContinue
            $results += "[OK] NumLock beim Start aktiviert"
        }
        catch {
            $results += "[WARNING] NumLock: $_"
        }

        # ======================================================================
        # TELEMETRIE MINIMIEREN
        # ======================================================================
        try {
            $telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            if (-not (Test-Path $telemetryPath)) {
                New-Item -Path $telemetryPath -Force | Out-Null
            }
            Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $results += "[OK] Telemetrie minimiert"
        }
        catch {
            $results += "[WARNING] Telemetrie: $_"
        }

        # ======================================================================
        # CORTANA DEAKTIVIEREN
        # ======================================================================
        try {
            $cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if (-not (Test-Path $cortanaPath)) {
                New-Item -Path $cortanaPath -Force | Out-Null
            }
            Set-ItemProperty -Path $cortanaPath -Name "AllowCortana" -Value 0 -Type DWord -Force
            $results += "[OK] Cortana deaktiviert"
        }
        catch {
            $results += "[WARNING] Cortana: $_"
        }

        # ======================================================================
        # GAME BAR DEAKTIVIEREN
        # ======================================================================
        try {
            $gamePath = "HKCU:\Software\Microsoft\GameBar"
            if (-not (Test-Path $gamePath)) {
                New-Item -Path $gamePath -Force | Out-Null
            }
            Set-ItemProperty -Path $gamePath -Name "AutoGameModeEnabled" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $results += "[OK] Game Bar/DVR deaktiviert"
        }
        catch {
            $results += "[WARNING] Game Bar: $_"
        }
    }
    catch {
        $results += "[ERROR] Kritischer Fehler: $_"
        $errors++
    }

    Complete-ModuleExecution "4. ENERGIE und PERFORMANCE" -ErrorCount $errors
    return @{
        Success = ($errors -eq 0)
        Results = $results
        Errors = $errors
    }
}

# Funktionen sind durch dot-sourcing verfuegbar
