# ==============================================================================
# MODUL 6: KOMPONENTEN
# ==============================================================================

function Invoke-Module6-Komponenten {
    Start-ModuleExecution "6. KOMPONENTEN"
    $errors = 0
    
    try {
        if ($Global:Config.BackupRegistry) {
            Backup-Registry "Modul6-Komponenten"
        }
        
        Write-SetupLog "Pruefe installierte Komponenten..." -Level INFO
        
        # ======================================================================
        # JAVA
        # ======================================================================
        Write-SetupLog "Java..." -Level INFO
        try {
            $javaInstalled = $null -ne (Get-Command java -ErrorAction SilentlyContinue)
            if ($javaInstalled) {
                $javaVersion = & java -version 2>&1 | Select-String "version" | Select-Object -First 1
                Write-SetupLog "  [OK] Java installiert: $javaVersion" -Level SUCCESS
            } else {
                Write-SetupLog "  [i] Java nicht installiert" -Level INFO
                Write-SetupLog "  Download: https://www.java.com/de/download/" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] Java-Pruefung: $($_.Exception.Message)" -Level WARNING
        }
        
        # ======================================================================
        # .NET FRAMEWORK
        # ======================================================================
        Write-SetupLog ".NET Framework..." -Level INFO
        try {
            $dotnetVersions = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
                Get-ItemProperty -Name Version -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty Version
            
            if ($dotnetVersions) {
                $latestVersion = $dotnetVersions | Sort-Object -Descending | Select-Object -First 1
                Write-SetupLog "  [OK] .NET Framework installiert (neueste: $latestVersion)" -Level SUCCESS
            } else {
                Write-SetupLog "  [i] .NET Framework-Status unklar" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] .NET-Pruefung: $($_.Exception.Message)" -Level WARNING
        }
        
        # ======================================================================
        # VISUAL C++ REDISTRIBUTABLES
        # ======================================================================
        Write-SetupLog "Visual C++ Redistributables..." -Level INFO
        try {
            $vcRedist = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                Where-Object { $_.DisplayName -like "*Visual C++*Redistributable*" } |
                Select-Object DisplayName, DisplayVersion
            
            if ($vcRedist) {
                Write-SetupLog "  [OK] VC++ Redistributables gefunden ($($vcRedist.Count) Versionen)" -Level SUCCESS
                foreach ($vc in $vcRedist) {
                    Write-SetupLog "    - $($vc.DisplayName)" -Level INFO
                }
            } else {
                Write-SetupLog "  [i] Keine VC++ Redistributables gefunden" -Level INFO
                Write-SetupLog "  Download: https://aka.ms/vs/17/release/vc_redist.x64.exe" -Level INFO
            }
        }
        catch {
            Write-SetupLog "  [X] VC++ Pruefung: $($_.Exception.Message)" -Level WARNING
        }
        
        # ======================================================================
        # INSTALLATION (DUMMY)
        # ======================================================================
        Write-SetupLog "`n[i] Automatische Installation von Komponenten:" -Level INFO
        Write-SetupLog "  Erfordert Chocolatey oder manuelle Installation" -Level INFO
        Write-SetupLog "  Chocolatey-Befehle:" -Level INFO
        Write-SetupLog "    choco install openjdk" -Level INFO
        Write-SetupLog "    choco install dotnet" -Level INFO
        Write-SetupLog "    choco install vcredist-all" -Level INFO
        
    }
    catch {
        Write-SetupLog "Kritischer Fehler in Modul 6: $_" -Level ERROR
        $errors++
    }
    
    Complete-ModuleExecution "6. KOMPONENTEN" -ErrorCount $errors
    return ($errors -eq 0)
}
