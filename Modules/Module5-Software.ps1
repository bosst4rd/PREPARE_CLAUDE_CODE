# ==============================================================================
# MODUL 5: SOFTWARE und DATEN
# ==============================================================================

function Invoke-Module5-SoftwareDaten {
    Start-ModuleExecution "5. SOFTWARE und DATEN"
    $errors = 0
    
    try {
        if ($Global:Config.BackupRegistry) {
            Backup-Registry "Modul5-Software"
        }
        
        # ======================================================================
        # CGM ORDNER ANLEGEN (bereits in Modul 1, hier nochmal zur Sicherheit)
        # ======================================================================
        Write-SetupLog "Pruefe CGM-Ordnerstruktur..." -Level INFO
        try {
            $cgmFolders = @(
                "C:\CGM",
                "C:\CGM\Logs",
                "C:\CGM\Registry-Backups",
                "C:\CGM\Fernwartung",
                "C:\CGM\Software"
            )
            
            $createdCount = 0
            foreach ($folder in $cgmFolders) {
                if (-not (Test-Path $folder)) {
                    New-Item -Path $folder -ItemType Directory -Force | Out-Null
                    $createdCount++
                }
            }
            Write-SetupLog "  [OK] CGM-Ordnerstruktur geprueft ($createdCount neue Ordner)" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] CGM-Ordner: $($_.Exception.Message)" -Level ERROR
            $errors++
        }
        
        # ======================================================================
        # FERNWARTUNG - VERKNUEPFUNGEN
        # ======================================================================
        Write-SetupLog "Erstelle Fernwartungs-Verknuepfungen..." -Level INFO
        try {
            $desktop = [Environment]::GetFolderPath('Desktop')
            $createdLinks = 0
            
            # TeamViewer QuickSupport (Platzhalter - URL anpassen)
            $tvLink = Join-Path $desktop "TeamViewer QuickSupport.url"
            if (-not (Test-Path $tvLink)) {
                $tvContent = @"
[InternetShortcut]
URL=https://get.teamviewer.com/quicksupport
"@
                Set-Content -Path $tvLink -Value $tvContent
                $createdLinks++
            }
            
            # CGM Support (Platzhalter - URL anpassen)
            $cgmLink = Join-Path $desktop "CGM Support.url"
            if (-not (Test-Path $cgmLink)) {
                $cgmContent = @"
[InternetShortcut]
URL=https://www.cgm.com/deu_de/service-support.html
"@
                Set-Content -Path $cgmLink -Value $cgmContent
                $createdLinks++
            }
            
            Write-SetupLog "  [OK] Fernwartungs-Links erstellt ($createdLinks Verknuepfungen)" -Level SUCCESS
        }
        catch {
            Write-SetupLog "  [X] Fernwartung: $($_.Exception.Message)" -Level WARNING
        }
        
        # ======================================================================
        # CHOCOLATEY INSTALLATION
        # ======================================================================
        Write-SetupLog "Pruefe Chocolatey..." -Level INFO
        try {
            $chocoInstalled = $null -ne (Get-Command choco -ErrorAction SilentlyContinue)
            
            if (-not $chocoInstalled) {
                Write-SetupLog "  [i] Chocolatey nicht gefunden, Installation wird uebersprungen" -Level INFO
                Write-SetupLog "  Hinweis: Chocolatey muss manuell installiert werden fuer Software-Pakete" -Level INFO
            } else {
                Write-SetupLog "  [OK] Chocolatey bereits installiert" -Level SUCCESS
            }
        }
        catch {
            Write-SetupLog "  [X] Chocolatey-Pruefung: $($_.Exception.Message)" -Level WARNING
        }
        
        # ======================================================================
        # SOFTWARE-PAKETE (DUMMY - Chocolatey erforderlich)
        # ======================================================================
        Write-SetupLog "Software-Pakete..." -Level INFO
        Write-SetupLog "  [i] Software-Installation erfordert Chocolatey" -Level INFO
        Write-SetupLog "  Geplante Pakete:" -Level INFO
        Write-SetupLog "    - 7zip" -Level INFO
        Write-SetupLog "    - Firefox" -Level INFO
        Write-SetupLog "    - Chrome" -Level INFO
        Write-SetupLog "    - Adobe Acrobat Reader" -Level INFO
        Write-SetupLog "    - LAN Messenger" -Level INFO
        Write-SetupLog "  [i] Manuelle Installation erforderlich oder Chocolatey verwenden" -Level INFO
        
    }
    catch {
        Write-SetupLog "Kritischer Fehler in Modul 5: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "5. SOFTWARE und DATEN" -ErrorCount $errors
    return ($errors -eq 0)
}
