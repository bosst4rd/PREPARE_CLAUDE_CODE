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

# Get script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Import modules
. (Join-Path $scriptPath "Config\Settings.ps1")
. (Join-Path $scriptPath "Functions\Core.ps1")
. (Join-Path $scriptPath "Functions\Helpers.ps1")

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

    # Load XAML
    $xamlPath = Join-Path $scriptPath "GUI\MainWindow.xaml"
    if (-not (Test-Path -Path $xamlPath)) {
        throw "XAML file not found: $xamlPath"
    }

    Write-Host "Loading GUI from: $xamlPath" -ForegroundColor Cyan
    $xamlContent = Get-Content -Path $xamlPath -Raw

    # Create window
    $window = New-WPFDialog -XamlContent $xamlContent
    if (-not $window) {
        throw "Failed to create WPF window"
    }

    Write-Host "GUI loaded successfully" -ForegroundColor Green

    #region Get UI Controls

    # Input controls
    $inputTextBox = Get-XamlObject -Window $window -Name "InputTextBox"
    $optionComboBox = Get-XamlObject -Window $window -Name "OptionComboBox"

    # Button controls
    $processButton = Get-XamlObject -Window $window -Name "ProcessButton"
    $action1Button = Get-XamlObject -Window $window -Name "Action1Button"
    $action2Button = Get-XamlObject -Window $window -Name "Action2Button"
    $action3Button = Get-XamlObject -Window $window -Name "Action3Button"
    $clearButton = Get-XamlObject -Window $window -Name "ClearButton"

    # Checkbox controls
    $option1CheckBox = Get-XamlObject -Window $window -Name "Option1CheckBox"
    $option2CheckBox = Get-XamlObject -Window $window -Name "Option2CheckBox"
    $option3CheckBox = Get-XamlObject -Window $window -Name "Option3CheckBox"

    # Configuration controls
    $workDirTextBox = Get-XamlObject -Window $window -Name "WorkDirTextBox"
    $logFileTextBox = Get-XamlObject -Window $window -Name "LogFileTextBox"
    $timeoutTextBox = Get-XamlObject -Window $window -Name "TimeoutTextBox"
    $browseButton = Get-XamlObject -Window $window -Name "BrowseButton"
    $saveConfigButton = Get-XamlObject -Window $window -Name "SaveConfigButton"
    $loadConfigButton = Get-XamlObject -Window $window -Name "LoadConfigButton"

    # Activity log and status
    $activityLog = Get-XamlObject -Window $window -Name "ActivityLog"
    $clearLogButton = Get-XamlObject -Window $window -Name "ClearLogButton"
    $statusLabel = Get-XamlObject -Window $window -Name "StatusLabel"
    $statusProgressBar = Get-XamlObject -Window $window -Name "StatusProgressBar"

    # Initialize configuration fields
    $workDirTextBox.Text = $config.WorkingDirectory
    $logFileTextBox.Text = $config.LogFileName
    $timeoutTextBox.Text = $config.DefaultTimeout

    # Sync checkboxes with config
    $option1CheckBox.IsChecked = $config.EnableVerboseLogging
    $option2CheckBox.IsChecked = $config.EnableAutoProcessing
    $option3CheckBox.IsChecked = $config.EnableAutoBackup

    #endregion

    #region Event Handlers

    # Process Button Click
    $processButton.Add_Click({
        try {
            $input = $inputTextBox.Text
            $option = $optionComboBox.SelectedItem.Content

            if (-not (Test-InputNotEmpty -Input $input)) {
                Write-Activity -RichTextBox $activityLog -Message "Eingabe ist leer!" -Level Warning
                Show-MessageDialog -Title "Warnung" -Message "Bitte geben Sie einen Wert ein." -Type Warning
                return
            }

            Write-Activity -RichTextBox $activityLog -Message "Verarbeite Eingabe: '$input' mit Option: '$option'" -Level Info
            Write-StatusBar -Label $statusLabel -Message "Verarbeitung läuft..." -ProgressBar $statusProgressBar -ShowProgress $true

            # Simulate processing
            Start-Sleep -Milliseconds 500

            Write-Activity -RichTextBox $activityLog -Message "Verarbeitung erfolgreich abgeschlossen!" -Level Success
            Write-StatusBar -Label $statusLabel -Message "Bereit" -ProgressBar $statusProgressBar -ShowProgress $false

            Show-MessageDialog -Title "Erfolg" -Message "Verarbeitung abgeschlossen!" -Type Info
        }
        catch {
            Write-Activity -RichTextBox $activityLog -Message "Fehler bei Verarbeitung: $_" -Level Error
            Write-StatusBar -Label $statusLabel -Message "Fehler aufgetreten" -ProgressBar $statusProgressBar -ShowProgress $false
            Write-ErrorLog -ErrorRecord $_ -LogPath (Join-Path $config.LogDirectory "error.log")
        }
    })

    # Action 1 Button Click
    $action1Button.Add_Click({
        Write-Activity -RichTextBox $activityLog -Message "Aktion 1 ausgeführt" -Level Info
        Write-StatusBar -Label $statusLabel -Message "Aktion 1 abgeschlossen"
    })

    # Action 2 Button Click
    $action2Button.Add_Click({
        Write-Activity -RichTextBox $activityLog -Message "Aktion 2 ausgeführt" -Level Info
        Write-StatusBar -Label $statusLabel -Message "Aktion 2 abgeschlossen"
    })

    # Action 3 Button Click
    $action3Button.Add_Click({
        Write-Activity -RichTextBox $activityLog -Message "Aktion 3 ausgeführt" -Level Debug
        Write-StatusBar -Label $statusLabel -Message "Aktion 3 abgeschlossen"
    })

    # Clear Button Click
    $clearButton.Add_Click({
        $inputTextBox.Text = ""
        $optionComboBox.SelectedIndex = 0
        Write-Activity -RichTextBox $activityLog -Message "Eingabefelder zurückgesetzt" -Level Info
        Write-StatusBar -Label $statusLabel -Message "Zurückgesetzt"
    })

    # Browse Button Click
    $browseButton.Add_Click({
        $folder = Get-FolderDialog -Description "Arbeitsverzeichnis auswählen"
        if ($folder) {
            $workDirTextBox.Text = $folder
            Write-Activity -RichTextBox $activityLog -Message "Arbeitsverzeichnis ausgewählt: $folder" -Level Info
        }
    })

    # Save Config Button Click
    $saveConfigButton.Add_Click({
        try {
            # Update config from UI
            $config.WorkingDirectory = $workDirTextBox.Text
            $config.LogFileName = $logFileTextBox.Text

            if (Test-NumericInput -Input $timeoutTextBox.Text) {
                $config.DefaultTimeout = [int]$timeoutTextBox.Text
            }

            $config.EnableVerboseLogging = $option1CheckBox.IsChecked
            $config.EnableAutoProcessing = $option2CheckBox.IsChecked
            $config.EnableAutoBackup = $option3CheckBox.IsChecked

            # Export configuration
            if (Export-AppConfig) {
                Write-Activity -RichTextBox $activityLog -Message "Konfiguration gespeichert" -Level Success
                Show-MessageDialog -Title "Erfolg" -Message "Konfiguration wurde gespeichert." -Type Info
            }
        }
        catch {
            Write-Activity -RichTextBox $activityLog -Message "Fehler beim Speichern: $_" -Level Error
            Write-ErrorLog -ErrorRecord $_ -LogPath (Join-Path $config.LogDirectory "error.log")
        }
    })

    # Load Config Button Click
    $loadConfigButton.Add_Click({
        try {
            if (Import-AppConfig) {
                # Update UI from config
                $workDirTextBox.Text = $config.WorkingDirectory
                $logFileTextBox.Text = $config.LogFileName
                $timeoutTextBox.Text = $config.DefaultTimeout

                $option1CheckBox.IsChecked = $config.EnableVerboseLogging
                $option2CheckBox.IsChecked = $config.EnableAutoProcessing
                $option3CheckBox.IsChecked = $config.EnableAutoBackup

                Write-Activity -RichTextBox $activityLog -Message "Konfiguration geladen" -Level Success
                Show-MessageDialog -Title "Erfolg" -Message "Konfiguration wurde geladen." -Type Info
            }
        }
        catch {
            Write-Activity -RichTextBox $activityLog -Message "Fehler beim Laden: $_" -Level Error
            Write-ErrorLog -ErrorRecord $_ -LogPath (Join-Path $config.LogDirectory "error.log")
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
