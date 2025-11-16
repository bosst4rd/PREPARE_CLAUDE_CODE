# ==============================================================================
# MODUL 5: SOFTWARE und DATEN - Vollstaendig
# ==============================================================================

function Install-Chocolatey {
    Write-SetupLog "Installiere Chocolatey Package Manager..." -Level INFO
    try {
        # Pruefe ob bereits installiert
        $chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoInstalled) {
            Write-SetupLog "  [OK] Chocolatey bereits installiert" -Level SUCCESS
            return $true
        }
        
        # Installiere Chocolatey
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Pruefe Installation
        $chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoInstalled) {
            Write-SetupLog "  [OK] Chocolatey erfolgreich installiert" -Level SUCCESS
            return $true
        } else {
            Write-SetupLog "  [X] Chocolatey Installation fehlgeschlagen" -Level ERROR
            return $false
        }
    }
    catch {
        Write-SetupLog "  [X] Chocolatey Installation Fehler: $_" -Level ERROR
        return $false
    }
}

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
        if (Install-Chocolatey) {
            # Software-Pakete installieren
            Write-SetupLog "`nInstalliere Software-Pakete..." -Level INFO
            
            $packages = @(
                @{Name="7zip"; DisplayName="7-Zip"},
                @{Name="adobereader"; DisplayName="Adobe Acrobat Reader"},
                @{Name="googlechrome"; DisplayName="Google Chrome"},
                @{Name="firefox"; DisplayName="Mozilla Firefox"},
                @{Name="teamviewer"; DisplayName="TeamViewer QuickSupport"}
            )
            
            $installedCount = 0
            foreach ($pkg in $packages) {
                Write-SetupLog "  Installiere $($pkg.DisplayName)..." -Level INFO
                try {
                    $output = & choco install $pkg.Name -y --no-progress --limit-output 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-SetupLog "    [OK] $($pkg.DisplayName) installiert" -Level SUCCESS
                        $installedCount++
                    } else {
                        Write-SetupLog "    [X] $($pkg.DisplayName) Fehler" -Level WARNING
                    }
                }
                catch {
                    Write-SetupLog "    [X] $($pkg.DisplayName): $_" -Level WARNING
                }
            }
            Write-SetupLog "  [OK] Software-Installation abgeschlossen ($installedCount/$($packages.Count) Pakete)" -Level SUCCESS
        } else {
            Write-SetupLog "  [X] Software-Installation uebersprungen (Chocolatey fehlt)" -Level ERROR
            $errors++
        }
        
        # Fernwartungs-Verknuepfungen erstellen
        Write-SetupLog "`nErstelle Fernwartungs-Verknuepfungen..." -Level INFO
        try {
            $desktop = [Environment]::GetFolderPath('Desktop')
            $shell = New-Object -ComObject WScript.Shell
            
            # PC Visit Support
            $shortcut = $shell.CreateShortcut("$desktop\PC Visit Support.url")
            $shortcut.TargetPath = "https://www.expletus.de/fernwartung"
            $shortcut.Save()
            Write-SetupLog "  [OK] PC Visit Support Verknuepfung erstellt" -Level SUCCESS
            
            # CGM Support
            $shortcut = $shell.CreateShortcut("$desktop\CGM Remote Support.url")
            $shortcut.TargetPath = "https://www.cgm.com/deu_de/daten/downloads/group-it/cgm-remote-support-windows.html"
            $shortcut.Save()
            Write-SetupLog "  [OK] CGM Support Verknuepfung erstellt" -Level SUCCESS
            
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        }
        catch {
            Write-SetupLog "  [X] Verknuepfungen: $_" -Level WARNING
        }
        
        # TeamViewer QuickSupport Desktop-Verknuepfung
        Write-SetupLog "`nErstelle TeamViewer QuickSupport Verknuepfung..." -Level INFO
        try {
            $tvPath = "C:\Program Files\TeamViewer\TeamViewer.exe"
            if (Test-Path $tvPath) {
                $desktop = [Environment]::GetFolderPath('Desktop')
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut("$desktop\TeamViewer QuickSupport.lnk")
                $shortcut.TargetPath = $tvPath
                $shortcut.Arguments = "/quicksupport"
                $shortcut.Save()
                Write-SetupLog "  [OK] TeamViewer QuickSupport Verknuepfung erstellt" -Level SUCCESS
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
            } else {
                Write-SetupLog "  [i] TeamViewer noch nicht installiert" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] TeamViewer Verknuepfung: $_" -Level WARNING
        }
        
    }
    catch {
        Write-SetupLog "Kritischer Fehler in Modul 5: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "5. SOFTWARE" -ErrorCount $errors
    return ($errors -eq 0)
}
