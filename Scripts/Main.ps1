#Requires -Version 5.1
<#
.SYNOPSIS
    PowerShell GUI Tool - Main Entry Point
.DESCRIPTION
    A robust, modular PowerShell GUI application based on Zero Structure
    Architecture: Modular design with separation of concerns
.NOTES
    Version: 1.0.0
    Author: Auto-Generated
    Created: $(Get-Date -Format "yyyy-MM-dd")
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Module Imports

# Get script directory (Scripts folder)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
# Get project root directory (parent of Scripts)
$projectRoot = Split-Path -Parent $scriptPath

# Import modules
. (Join-Path $projectRoot "Config\Settings.ps1")
. (Join-Path $projectRoot "Functions\Core.ps1")
. (Join-Path $projectRoot "Functions\Helpers.ps1")

#endregion

#region Initialization

# Initialize configuration
Write-Host "Initializing application..." -ForegroundColor Cyan
if (-not (Initialize-AppConfiguration)) {
    Write-Host "Failed to initialize application configuration!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$config = Get-AppConfig
Write-Host "Configuration loaded: $($config.AppName) v$($config.AppVersion)" -ForegroundColor Green

#endregion

#region Load GUI

try {
    # Load required assemblies
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

    # Load XAML files
    $xamlPath = Join-Path $projectRoot "GUI\MainWindow.xaml"
    $templatesPath = Join-Path $projectRoot "GUI\ControlTemplates.xaml"

    if (-not (Test-Path -Path $xamlPath)) {
        throw "XAML file not found: $xamlPath"
    }
    if (-not (Test-Path -Path $templatesPath)) {
        throw "Templates file not found: $templatesPath"
    }

    Write-Host "Loading GUI from: $xamlPath" -ForegroundColor Cyan

    # Load XAML directly without any modifications
    $xamlContent = [System.IO.File]::ReadAllText($xamlPath)

    # Create window
    $window = New-WPFDialog -XamlContent $xamlContent
    if (-not $window) {
        throw "Failed to create WPF window"
    }

    Write-Host "GUI loaded successfully" -ForegroundColor Green

    #region Get UI Controls

    # Main controls
    $startButton = Get-XamlObject -Window $window -Name "StartButton"

    # Optional software checkboxes
    $officeCheckBox = Get-XamlObject -Window $window -Name "OfficeCheckBox"
    $acrobatCheckBox = Get-XamlObject -Window $window -Name "AcrobatCheckBox"
    $albisCheckBox = Get-XamlObject -Window $window -Name "ALBISCheckBox"

    # Option checkboxes
    $verboseLoggingCheckBox = Get-XamlObject -Window $window -Name "VerboseLoggingCheckBox"
    $createBackupCheckBox = Get-XamlObject -Window $window -Name "CreateBackupCheckBox"

    # Activity log and status
    $activityLog = Get-XamlObject -Window $window -Name "ActivityLog"
    $clearLogButton = Get-XamlObject -Window $window -Name "ClearLogButton"
    $statusLabel = Get-XamlObject -Window $window -Name "StatusLabel"
    $statusProgressBar = Get-XamlObject -Window $window -Name "StatusProgressBar"

    # Initialize with default values
    $verboseLoggingCheckBox.IsChecked = $config.EnableVerboseLogging
    $createBackupCheckBox.IsChecked = $config.EnableAutoBackup

    #endregion

    #region Event Handlers

    # Start Button Click
    $startButton.Add_Click({
        try {
            # Get selected optional software
            $selectedSoftware = @()
            if ($officeCheckBox.IsChecked) { $selectedSoftware += "Microsoft Office" }
            if ($acrobatCheckBox.IsChecked) { $selectedSoftware += "Adobe Acrobat" }
            if ($albisCheckBox.IsChecked) { $selectedSoftware += "ALBIS" }

            # Get options
            $verboseLogging = $verboseLoggingCheckBox.IsChecked
            $createBackup = $createBackupCheckBox.IsChecked

            # Start processing
            Write-Activity -RichTextBox $activityLog -Message "═══════════════════════════════════════" -Level Info
            Write-Activity -RichTextBox $activityLog -Message "Starte Vorbereitung..." -Level Info

            if ($selectedSoftware.Count -gt 0) {
                Write-Activity -RichTextBox $activityLog -Message "Optionale Software: $($selectedSoftware -join ', ')" -Level Info
            } else {
                Write-Activity -RichTextBox $activityLog -Message "Keine optionale Software ausgewaehlt" -Level Info
            }

            Write-Activity -RichTextBox $activityLog -Message "Detaillierte Protokollierung: $verboseLogging" -Level Debug
            Write-Activity -RichTextBox $activityLog -Message "Backup erstellen: $createBackup" -Level Debug

            Write-StatusBar -Label $statusLabel -Message "Vorbereitung laeuft..." -ProgressBar $statusProgressBar -ShowProgress $true

            # Disable start button during processing
            $startButton.IsEnabled = $false

            # ═══════════════════════════════════════
            # HAUPTMODUL (wird immer ausgefuehrt)
            # ═══════════════════════════════════════

            Write-Activity -RichTextBox $activityLog -Message "--- HAUPTMODUL: Cleanup/Ergonomie ---" -Level Info
            # TODO: Widgets aus, Copilot entfernen, OneDrive deaktivieren, Pins loeschen, etc.
            Start-Sleep -Milliseconds 300
            [System.Windows.Forms.Application]::DoEvents()

            Write-Activity -RichTextBox $activityLog -Message "--- HAUPTMODUL: Energie/Performance ---" -Level Info
            # TODO: Autostart bereinigen, Hoechstleistung, Hibernate aus, etc.
            Start-Sleep -Milliseconds 300
            [System.Windows.Forms.Application]::DoEvents()

            Write-Activity -RichTextBox $activityLog -Message "--- HAUPTMODUL: Standard-Software ---" -Level Info
            # TODO: C:\CGM Ordner, Chocolatey, 7-Zip, Firefox, Chrome, Fernwartung
            Start-Sleep -Milliseconds 300
            [System.Windows.Forms.Application]::DoEvents()

            Write-Activity -RichTextBox $activityLog -Message "--- HAUPTMODUL: Komponenten ---" -Level Info
            # TODO: Java, .NET Runtime, VC Redist
            Start-Sleep -Milliseconds 300
            [System.Windows.Forms.Application]::DoEvents()

            # ═══════════════════════════════════════
            # OPTIONALE MODULE
            # ═══════════════════════════════════════

            if ($officeCheckBox.IsChecked) {
                Write-Activity -RichTextBox $activityLog -Message "--- OPTIONAL: Microsoft Office installieren ---" -Level Info
                # TODO: choco install office365business
                Start-Sleep -Milliseconds 500
                [System.Windows.Forms.Application]::DoEvents()
            }

            if ($acrobatCheckBox.IsChecked) {
                Write-Activity -RichTextBox $activityLog -Message "--- OPTIONAL: Adobe Acrobat installieren ---" -Level Info
                # TODO: choco install adobereader
                Start-Sleep -Milliseconds 500
                [System.Windows.Forms.Application]::DoEvents()
            }

            if ($albisCheckBox.IsChecked) {
                Write-Activity -RichTextBox $activityLog -Message "--- OPTIONAL: ALBIS vorbereiten ---" -Level Info
                Write-Activity -RichTextBox $activityLog -Message "  - EPSON LQ-400 Treiber" -Level Info
                Write-Activity -RichTextBox $activityLog -Message "  - C:\GDT Ordner erstellen" -Level Info
                Write-Activity -RichTextBox $activityLog -Message "  - C:\CGM\ALBISWIN Ordner erstellen" -Level Info
                # TODO: ALBIS Modul ausfuehren
                Start-Sleep -Milliseconds 500
                [System.Windows.Forms.Application]::DoEvents()
            }

            # Completion
            Write-Activity -RichTextBox $activityLog -Message "═══════════════════════════════════════" -Level Info
            Write-Activity -RichTextBox $activityLog -Message "Vorbereitung erfolgreich abgeschlossen!" -Level Success
            Write-Activity -RichTextBox $activityLog -Message "═══════════════════════════════════════" -Level Info

            Write-StatusBar -Label $statusLabel -Message "Vorbereitung abgeschlossen" -ProgressBar $statusProgressBar -ShowProgress $false

            # Re-enable start button
            $startButton.IsEnabled = $true

            Show-MessageDialog -Title "Erfolg" -Message "Die Vorbereitung wurde erfolgreich abgeschlossen!" -Type Info
        }
        catch {
            Write-Activity -RichTextBox $activityLog -Message "FEHLER: $_" -Level Error
            Write-Activity -RichTextBox $activityLog -Message "═══════════════════════════════════════" -Level Info
            Write-StatusBar -Label $statusLabel -Message "Fehler aufgetreten" -ProgressBar $statusProgressBar -ShowProgress $false
            Write-ErrorLog -ErrorRecord $_ -LogPath (Join-Path $config.LogDirectory "error.log")

            # Re-enable start button
            $startButton.IsEnabled = $true

            Show-MessageDialog -Title "Fehler" -Message "Bei der Vorbereitung ist ein Fehler aufgetreten:`n`n$_" -Type Error
        }
    })

    # Clear Log Button Click
    $clearLogButton.Add_Click({
        Clear-ActivityLog -RichTextBox $activityLog
        Write-Activity -RichTextBox $activityLog -Message "Protokoll gelöscht" -Level Info
    })

    # Window Loaded Event
    $window.Add_Loaded({
        Write-Activity -RichTextBox $activityLog -Message "Application gestartet - $($config.AppName) v$($config.AppVersion)" -Level Success
        Write-Activity -RichTextBox $activityLog -Message "Bereit für Operationen" -Level Info
        Write-StatusBar -Label $statusLabel -Message "Bereit"
    })

    # Window Closing Event
    $window.Add_Closing({
        Write-Activity -RichTextBox $activityLog -Message "Application wird geschlossen..." -Level Info
    })

    #endregion

    # Show window
    Write-Host "Showing GUI window..." -ForegroundColor Cyan
    $window.ShowDialog() | Out-Null

    Write-Host "Application closed normally" -ForegroundColor Green
}
catch {
    Write-Host "FATAL ERROR: $_" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red

    # Try to show error dialog
    try {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show(
            "Ein schwerwiegender Fehler ist aufgetreten:`n`n$($_.Exception.Message)`n`nDetails:`n$($_.ScriptStackTrace)",
            "Kritischer Fehler",
            'OK',
            'Error'
        )
    }
    catch {
        # Fallback to console
        Write-Host "Could not show error dialog" -ForegroundColor Red
    }

    Read-Host "Press Enter to exit"
    exit 1
}

#endregion
