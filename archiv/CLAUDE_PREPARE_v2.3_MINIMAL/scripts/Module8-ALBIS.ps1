# ==============================================================================
# MODUL 8: ALBIS SPEZIFISCH
# ==============================================================================

function Invoke-Module8-ALBIS {
    Start-ModuleExecution "8. ALBIS SPEZIFISCH"
    $errors = 0
    
    try {
        if ($Global:Config.BackupRegistry) {
            Backup-Registry "Modul8-ALBIS"
        }
        
        # ======================================================================
        # LAUFWERKSBEZEICHNUNGEN
        # ======================================================================
        Write-SetupLog "Laufwerksbezeichnungen..." -Level INFO
        try {
            # C: Laufwerk umbenennen
            $cDrive = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
            if ($cDrive) {
                if ($cDrive.FileSystemLabel -ne "SYSTEM") {
                    Set-Volume -DriveLetter C -NewFileSystemLabel "SYSTEM" -ErrorAction Stop
                    Write-SetupLog "  [OK] C: umbenannt in 'SYSTEM'" -Level SUCCESS
                } else {
                    Write-SetupLog "  [OK] C: bereits als 'SYSTEM' bezeichnet" -Level SUCCESS
                }
            }
        }
        catch {
            Write-SetupLog "  [X] Laufwerksbezeichnung: $($_.Exception.Message)" -Level ERROR
            $errors++
        }
        
        # ======================================================================
        # EPSON LQ-400 DRUCKER
        # ======================================================================
        Write-SetupLog "EPSON LQ-400 Drucker..." -Level INFO
        try {
            $epsonDriver = Get-PrinterDriver -Name "*EPSON*LQ*400*" -ErrorAction SilentlyContinue
            
            if ($epsonDriver) {
                Write-SetupLog "  [OK] EPSON LQ-400 Treiber gefunden" -Level SUCCESS
            } else {
                Write-SetupLog "  [i] EPSON LQ-400 Treiber nicht gefunden" -Level INFO
                Write-SetupLog "  Hinweis: Treiber muss manuell installiert werden" -Level INFO
                Write-SetupLog "  Download: https://www.epson.de/support" -Level INFO
            }
            
            # Drucker hinzufuegen (wenn Treiber vorhanden)
            if ($epsonDriver) {
                $epsonPrinter = Get-Printer -Name "EPSON LQ-400" -ErrorAction SilentlyContinue
                if (-not $epsonPrinter) {
                    Write-SetupLog "  [i] Drucker kann hinzugefuegt werden (Port muss konfiguriert sein)" -Level INFO
                } else {
                    Write-SetupLog "  [OK] EPSON LQ-400 Drucker bereits installiert" -Level SUCCESS
                }
            }
        }
        catch {
            Write-SetupLog "  [X] EPSON Drucker: $($_.Exception.Message)" -Level WARNING
        }
        
        # ======================================================================
        # ALBIS-SPEZIFISCHE KONFIGURATION
        # ======================================================================
        Write-SetupLog "ALBIS-Konfiguration..." -Level INFO
        Write-SetupLog "  [i] ALBIS-spezifische Anpassungen" -Level INFO
        Write-SetupLog "  Hinweis: Weitere Konfiguration nach Bedarf" -Level INFO
        
    }
    catch {
        Write-SetupLog "Kritischer Fehler in Modul 8: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "8. ALBIS SPEZIFISCH" -ErrorCount $errors
    return ($errors -eq 0)
}
