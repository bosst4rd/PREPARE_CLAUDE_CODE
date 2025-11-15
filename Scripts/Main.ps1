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
    $targetPathTextBox = Get-XamlObject -Window $window -Name "TargetPathTextBox"
    $browseFolderButton = Get-XamlObject -Window $window -Name "BrowseFolderButton"
    $startButton = Get-XamlObject -Window $window -Name "StartButton"

    # Option checkboxes
    $verboseLoggingCheckBox = Get-XamlObject -Window $window -Name "VerboseLoggingCheckBox"
    $createBackupCheckBox = Get-XamlObject -Window $window -Name "CreateBackupCheckBox"

    # Activity log and status
    $activityLog = Get-XamlObject -Window $window -Name "ActivityLog"
    $clearLogButton = Get-XamlObject -Window $window -Name "ClearLogButton"
    $statusLabel = Get-XamlObject -Window $window -Name "StatusLabel"
    $statusProgressBar = Get-XamlObject -Window $window -Name "StatusProgressBar"

    # Initialize with default values
    $targetPathTextBox.Text = ""
    $verboseLoggingCheckBox.IsChecked = $config.EnableVerboseLogging
    $createBackupCheckBox.IsChecked = $config.EnableAutoBackup

    #endregion

    #region Event Handlers

    # Browse Folder Button Click
    $browseFolderButton.Add_Click({
        try {
            Write-Activity -RichTextBox $activityLog -Message "Öffne Ordnerauswahl..." -Level Info

            $folder = Get-FolderDialog -Description "Zielordner auswählen"
            if ($folder) {
                $targetPathTextBox.Text = $folder
                Write-Activity -RichTextBox $activityLog -Message "Zielordner ausgewählt: $folder" -Level Success
                Write-StatusBar -Label $statusLabel -Message "Ordner ausgewählt: $folder"
            }
            else {
                Write-Activity -RichTextBox $activityLog -Message "Ordnerauswahl abgebrochen" -Level Info
            }
        }
        catch {
            Write-Activity -RichTextBox $activityLog -Message "Fehler bei Ordnerauswahl: $_" -Level Error
            Write-ErrorLog -ErrorRecord $_ -LogPath (Join-Path $config.LogDirectory "error.log")
        }
    })

    # Start Button Click
    $startButton.Add_Click({
        try {
            # Get target path
            $targetPath = $targetPathTextBox.Text

            # Validate path
            if (-not (Test-InputNotEmpty -Input $targetPath)) {
                Write-Activity -RichTextBox $activityLog -Message "Kein Zielordner ausgewählt!" -Level Warning
                Show-MessageDialog -Title "Warnung" -Message "Bitte wählen Sie einen Zielordner aus." -Type Warning
                return
            }

            if (-not (Test-PathValid -Path $targetPath)) {
                Write-Activity -RichTextBox $activityLog -Message "Ungültiger Pfad: $targetPath" -Level Warning
                Show-MessageDialog -Title "Warnung" -Message "Der ausgewählte Pfad existiert nicht oder ist ungültig." -Type Warning
                return
            }

            # Get options
            $verboseLogging = $verboseLoggingCheckBox.IsChecked
            $createBackup = $createBackupCheckBox.IsChecked

            # Start processing
            Write-Activity -RichTextBox $activityLog -Message "═══════════════════════════════════════" -Level Info
            Write-Activity -RichTextBox $activityLog -Message "Starte Verarbeitung..." -Level Info
            Write-Activity -RichTextBox $activityLog -Message "Zielordner: $targetPath" -Level Info
            Write-Activity -RichTextBox $activityLog -Message "Detaillierte Protokollierung: $verboseLogging" -Level Debug
            Write-Activity -RichTextBox $activityLog -Message "Backup erstellen: $createBackup" -Level Debug

            Write-StatusBar -Label $statusLabel -Message "Verarbeitung läuft..." -ProgressBar $statusProgressBar -ShowProgress $true

            # Disable start button during processing
            $startButton.IsEnabled = $false

            # TODO: Hier kommt Ihre Verarbeitungslogik hin
            # Beispiel: Dateien verarbeiten, Operationen durchführen, etc.

            # Simulate processing
            for ($i = 1; $i -le 5; $i++) {
                Write-Activity -RichTextBox $activityLog -Message "Verarbeite Schritt $i von 5..." -Level Info
                Start-Sleep -Milliseconds 300

                # Force UI update
                [System.Windows.Forms.Application]::DoEvents()
            }

            # Completion
            Write-Activity -RichTextBox $activityLog -Message "Verarbeitung erfolgreich abgeschlossen!" -Level Success
            Write-Activity -RichTextBox $activityLog -Message "═══════════════════════════════════════" -Level Info

            Write-StatusBar -Label $statusLabel -Message "Verarbeitung abgeschlossen" -ProgressBar $statusProgressBar -ShowProgress $false

            # Re-enable start button
            $startButton.IsEnabled = $true

            Show-MessageDialog -Title "Erfolg" -Message "Die Verarbeitung wurde erfolgreich abgeschlossen!" -Type Info
        }
        catch {
            Write-Activity -RichTextBox $activityLog -Message "FEHLER: $_" -Level Error
            Write-Activity -RichTextBox $activityLog -Message "═══════════════════════════════════════" -Level Info
            Write-StatusBar -Label $statusLabel -Message "Fehler aufgetreten" -ProgressBar $statusProgressBar -ShowProgress $false
            Write-ErrorLog -ErrorRecord $_ -LogPath (Join-Path $config.LogDirectory "error.log")

            # Re-enable start button
            $startButton.IsEnabled = $true

            Show-MessageDialog -Title "Fehler" -Message "Bei der Verarbeitung ist ein Fehler aufgetreten:`n`n$_" -Type Error
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
