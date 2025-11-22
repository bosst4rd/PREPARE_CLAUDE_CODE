# ==============================================================================
# MODUL 8: ALBIS SPEZIFISCH
# ==============================================================================

function Invoke-Module8-ALBIS {
    Start-ModuleExecution "8. ALBIS SPEZIFISCH"
    $errors = 0
    $results = @()
    $cfg = Get-ModuleConfig

    try {
        if ($cfg.BackupRegistry) {
            Backup-Registry "Modul8-ALBIS"
        }

        # ======================================================================
        # GDT ORDNER
        # ======================================================================
        try {
            if (-not (Test-Path "C:\GDT")) {
                New-Item -Path "C:\GDT" -ItemType Directory -Force | Out-Null
                $results += "[OK] C:\GDT Ordner erstellt"
            } else {
                $results += "[OK] C:\GDT Ordner existiert"
            }
        }
        catch {
            $results += "[WARNING] GDT-Ordner: $($_.Exception.Message)"
        }

        # ======================================================================
        # ALBISWIN ORDNER
        # ======================================================================
        try {
            if (-not (Test-Path "C:\CGM\ALBISWIN")) {
                New-Item -Path "C:\CGM\ALBISWIN" -ItemType Directory -Force | Out-Null
                $results += "[OK] C:\CGM\ALBISWIN Ordner erstellt"
            } else {
                $results += "[OK] C:\CGM\ALBISWIN Ordner existiert"
            }
        }
        catch {
            $results += "[WARNING] ALBISWIN-Ordner: $($_.Exception.Message)"
        }

        # ======================================================================
        # LAUFWERKSBEZEICHNUNGEN
        # ======================================================================
        try {
            # C: Laufwerk umbenennen
            $cDrive = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
            if ($cDrive) {
                if ($cDrive.FileSystemLabel -ne "SYSTEM") {
                    Set-Volume -DriveLetter C -NewFileSystemLabel "SYSTEM" -ErrorAction Stop
                    $results += "[OK] C: umbenannt in 'SYSTEM'"
                } else {
                    $results += "[OK] C: bereits als 'SYSTEM' bezeichnet"
                }
            }
        }
        catch {
            $results += "[WARNING] Laufwerksbezeichnung: $($_.Exception.Message)"
            $errors++
        }

        # ======================================================================
        # EPSON LQ-400 DRUCKER
        # ======================================================================
        try {
            $epsonDriver = Get-PrinterDriver -Name "*EPSON*LQ*400*" -ErrorAction SilentlyContinue

            if ($epsonDriver) {
                $results += "[OK] EPSON LQ-400 Treiber gefunden"

                # Drucker hinzufuegen (wenn Treiber vorhanden)
                $epsonPrinter = Get-Printer -Name "EPSON LQ-400" -ErrorAction SilentlyContinue
                if (-not $epsonPrinter) {
                    $results += "[INFO] Drucker kann hinzugefuegt werden (Port muss konfiguriert sein)"
                } else {
                    $results += "[OK] EPSON LQ-400 Drucker bereits installiert"
                }
            } else {
                $results += "[INFO] EPSON LQ-400 Treiber nicht gefunden"
                $results += "[INFO] Hinweis: Treiber muss manuell installiert werden"
            }
        }
        catch {
            $results += "[WARNING] EPSON Drucker: $($_.Exception.Message)"
        }

        # ======================================================================
        # ALBIS-SPEZIFISCHE KONFIGURATION
        # ======================================================================
        $results += "[INFO] ALBIS-Vorbereitung abgeschlossen"
        $results += "[INFO] Weitere Konfiguration nach ALBIS-Installation"

    }
    catch {
        $results += "[ERROR] Kritischer Fehler: $_"
        $errors++
    }

    Complete-ModuleExecution "8. ALBIS SPEZIFISCH" -ErrorCount $errors
    return @{
        Success = ($errors -eq 0)
        Results = $results
        Errors = $errors
    }
}
