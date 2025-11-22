# ==============================================================================
# MODUL 7: FUNKTIONALITAET
# ==============================================================================

function Invoke-Module7-Funktionalitaet {
    Start-ModuleExecution "7. FUNKTIONALITAET"
    $errors = 0
    
    try {
        if ($Global:Config.BackupRegistry) {
            Backup-Registry "Modul7-Funktionalitaet"
        }
        
        # ======================================================================
        # INTELLIGENTE ZWISCHENABLAGE
        # ======================================================================
        Write-SetupLog "Aktiviere intelligente Zwischenablage..." -Level INFO
        try {
            $clipboardPath = "HKCU:\Software\Microsoft\Clipboard"
            if (-not (Test-Path $clipboardPath)) {
                New-Item -Path $clipboardPath -Force | Out-Null
            }
            Set-ItemProperty -Path $clipboardPath -Name "EnableClipboardHistory" -Value 1 -Type DWord -Force
            Write-SetupLog "  [OK] Zwischenablage-Verlauf aktiviert" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Zwischenablage: $($_.Exception.Message)" -Level ERROR
            $errors++
        }
        
        # ======================================================================
        # UAC DEAKTIVIEREN
        # ======================================================================
        Write-SetupLog "Deaktiviere UAC..." -Level INFO
        try {
            $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            Set-ItemProperty -Path $uacPath -Name "EnableLUA" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force
            Write-SetupLog "  [OK] UAC deaktiviert (Neustart erforderlich!)" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] UAC: $($_.Exception.Message)" -Level ERROR
            $errors++
        }
        
        # ======================================================================
        # STANDARDDRUCKER-VERWALTUNG
        # ======================================================================
        Write-SetupLog "Standarddrucker-Verwaltung..." -Level INFO
        try {
            $printerPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows"
            Set-ItemProperty -Path $printerPath -Name "LegacyDefaultPrinterMode" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-SetupLog "  [OK] Benutzer kann Standarddrucker selbst verwalten" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Standarddrucker: $($_.Exception.Message)" -Level WARNING
        }
        
        # ======================================================================
        # NUMMERNBLOCK AKTIVIEREN
        # ======================================================================
        Write-SetupLog "Aktiviere Nummernblock beim Start..." -Level INFO
        try {
            $numLockPath = "HKCU:\Control Panel\Keyboard"
            Set-ItemProperty -Path $numLockPath -Name "InitialKeyboardIndicators" -Value "2" -Force
            Write-SetupLog "  [OK] Nummernblock wird beim Start aktiviert" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Nummernblock: $($_.Exception.Message)" -Level WARNING
        }
        
        # ======================================================================
        # LAUFWERKSBUCHSTABEN (USB) NACH HINTEN
        # ======================================================================
        Write-SetupLog "Laufwerksbuchstaben-Verwaltung..." -Level INFO
        Write-SetupLog "  [i] Automatische USB-Laufwerkszuweisung (Z,Y,X...)" -Level INFO
        Write-SetupLog "  [i] Erfordert manuelle Konfiguration oder Skript" -Level INFO
        Write-SetupLog "  Hinweis: Neue USB-Laufwerke erhalten naechsten freien Buchstaben" -Level INFO
        
        # ======================================================================
        # STANDARD-APPS (DUMMY)
        # ======================================================================
        Write-SetupLog "Standard-Apps..." -Level INFO
        Write-SetupLog "  [i] Standard-Browser: Firefox (manuell setzen)" -Level INFO
        Write-SetupLog "  [i] Standard-PDF: Acrobat Reader (manuell setzen)" -Level INFO
        Write-SetupLog "  Hinweis: Windows 11 erfordert manuelle Auswahl in Einstellungen" -Level INFO
        
    }
    catch {
        Write-SetupLog "Kritischer Fehler in Modul 7: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "7. FUNKTIONALITAET" -ErrorCount $errors
    return ($errors -eq 0)
}
