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

        # Widgets entfernen
        try {
            $widgetsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $widgetsPath)) {
                New-Item -Path $widgetsPath -Force | Out-Null
            }
            Set-ItemProperty -Path $widgetsPath -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            # Task View Button entfernen
            Set-ItemProperty -Path $widgetsPath -Name "ShowTaskViewButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            $results += "[OK] Widgets/Task View deaktiviert"
        }
        catch {
            $results += "[WARNING] Widgets: $_"
        }

        # Copilot entfernen
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

        # OneDrive deaktivieren (Sync aus)
        try {
            $runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            Remove-ItemProperty -Path $runPath -Name "OneDrive" -ErrorAction SilentlyContinue
            $results += "[OK] OneDrive Autostart deaktiviert"
        }
        catch {
            $results += "[WARNING] OneDrive: $_"
        }

        # Suche entfernen
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

        # Desktop bereinigen - Verknuepfungen
        try {
            $desktop = [Environment]::GetFolderPath('Desktop')
            $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
            $shortcutsToRemove = @(
                'Microsoft Edge.lnk',
                'Microsoft Store.lnk',
                'Outlook.lnk',
                'Google Chrome.lnk',
                'Firefox.lnk',
                'Teams.lnk',
                'OneDrive.lnk'
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

        # Desktop-Icons ausblenden (Papierkorb, Dieser PC, etc.)
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
            $results += "[OK] Desktop-Icons ausgeblendet (Papierkorb, Netzwerk, Benutzer)"
        }
        catch {
            $results += "[WARNING] Desktop-Icons: $_"
        }

        # Chat/Teams Icon aus Taskleiste entfernen
        try {
            $chatPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Set-ItemProperty -Path $chatPath -Name "TaskbarMn" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $results += "[OK] Chat/Teams aus Taskleiste entfernt"
        }
        catch {
            $results += "[WARNING] Chat-Icon: $_"
        }

        # Fax/XPS Drucker entfernen
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

        # Taskleiste linksbuendig
        try {
            $taskbarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Set-ItemProperty -Path $taskbarPath -Name "TaskbarAl" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $taskbarPath -Name "TaskbarGlomLevel" -Value 2 -Type DWord -Force
            $results += "[OK] Taskleiste linksbuendig, nicht gruppiert"
        }
        catch {
            $results += "[WARNING] Taskleiste: $_"
        }

        # Explorer-Einstellungen
        try {
            $explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Set-ItemProperty -Path $explorerPath -Name "HideFileExt" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $explorerPath -Name "Hidden" -Value 1 -Type DWord -Force
            $results += "[OK] Dateierweiterungen sichtbar"
        }
        catch {
            $results += "[WARNING] Explorer: $_"
        }

        # Bildschirmschoner deaktivieren
        try {
            $screensaverPath = "HKCU:\Control Panel\Desktop"
            Set-ItemProperty -Path $screensaverPath -Name "ScreenSaveActive" -Value "0" -Force
            $results += "[OK] Bildschirmschoner deaktiviert"
        }
        catch {
            $results += "[WARNING] Bildschirmschoner: $_"
        }

        # Desktop-Symbol: Dieser PC anzeigen
        try {
            $desktopIconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
            if (-not (Test-Path $desktopIconsPath)) {
                New-Item -Path $desktopIconsPath -Force | Out-Null
            }
            # Dieser PC anzeigen
            Set-ItemProperty -Path $desktopIconsPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -Type DWord -Force
            $results += "[OK] Desktop-Symbol 'Dieser PC' aktiviert"
        }
        catch {
            $results += "[WARNING] Desktop-Symbole: $_"
        }

        # Hintergrund: Einfarbig schwarz setzen
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

        # Transparenz deaktivieren
        try {
            $personalizePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
            Set-ItemProperty -Path $personalizePath -Name "EnableTransparency" -Value 0 -Type DWord -Force
            $results += "[OK] Transparenz deaktiviert"
        }
        catch {
            $results += "[WARNING] Transparenz: $_"
        }

        # Animationen reduzieren (Performance)
        try {
            $visualPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary -Force
            $results += "[OK] Visuelle Effekte reduziert"
        }
        catch {
            $results += "[WARNING] Animationen: $_"
        }

        # Schnellstart deaktivieren
        try {
            $fastBootPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
            Set-ItemProperty -Path $fastBootPath -Name "HiberbootEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $results += "[OK] Schnellstart deaktiviert"
        }
        catch {
            $results += "[WARNING] Schnellstart: $_"
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

        # Hoechstleistung Energieplan
        try {
            $highPerf = powercfg /list | Select-String "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
            if ($highPerf) {
                powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
                $results += "[OK] Energieplan: Hoechstleistung aktiviert"
            } else {
                $results += "[INFO] Hoechstleistung-Plan nicht verfuegbar"
            }
        }
        catch {
            $results += "[WARNING] Energieplan: $_"
        }

        # Hibernate deaktivieren
        try {
            powercfg /hibernate off 2>$null
            $results += "[OK] Ruhezustand deaktiviert"
        }
        catch {
            $results += "[WARNING] Hibernate: $_"
        }

        # Monitor nie ausschalten
        try {
            powercfg /change monitor-timeout-ac 0
            powercfg /change monitor-timeout-dc 0
            powercfg /change standby-timeout-ac 0
            powercfg /change standby-timeout-dc 0
            $results += "[OK] Monitor/Standby: Nie ausschalten"
        }
        catch {
            $results += "[WARNING] Power-Timeout: $_"
        }

        # Zwischenablage-Historie aktivieren
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

        # NumLock beim Start
        try {
            $numLockPath = "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard"
            Set-ItemProperty -Path $numLockPath -Name "InitialKeyboardIndicators" -Value "2" -Force -ErrorAction SilentlyContinue
            $results += "[OK] NumLock beim Start aktiviert"
        }
        catch {
            $results += "[WARNING] NumLock: $_"
        }

        # UAC deaktivieren (auf niedrigste Stufe)
        try {
            $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            Set-ItemProperty -Path $uacPath -Name "EnableLUA" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $results += "[OK] UAC minimiert (Neustart erforderlich)"
        }
        catch {
            $results += "[WARNING] UAC: $_"
        }

        # Windows Update: Nur manuell
        try {
            $wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            if (-not (Test-Path $wuPath)) {
                New-Item -Path $wuPath -Force | Out-Null
            }
            Set-ItemProperty -Path $wuPath -Name "NoAutoUpdate" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $wuPath -Name "AUOptions" -Value 2 -Type DWord -Force
            $results += "[OK] Windows Update: Benachrichtigen vor Download"
        }
        catch {
            $results += "[WARNING] Windows Update: $_"
        }

        # Telemetrie minimieren
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

        # Cortana deaktivieren
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

        # Game Bar deaktivieren
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

        # Sperrbildschirm-Timeout
        try {
            $lockPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            Set-ItemProperty -Path $lockPath -Name "InactivityTimeoutSecs" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $results += "[OK] Sperrbildschirm-Timeout deaktiviert"
        }
        catch {
            $results += "[WARNING] Sperrbildschirm: $_"
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
