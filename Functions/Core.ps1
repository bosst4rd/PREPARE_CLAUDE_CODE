# Core.ps1 - Core GUI Functions
# Part of PowerShell GUI Tool - Zero Structure

#region XAML Loading Functions

function New-WPFDialog {
    <#
    .SYNOPSIS
        Converts XAML markup into interactive WPF controls
    .DESCRIPTION
        Takes XAML content and creates a WPF window or control object
    .PARAMETER XamlContent
        The XAML markup as string
    .EXAMPLE
        $window = New-WPFDialog -XamlContent $xaml
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$XamlContent
    )

    try {
        Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

        # Remove XML attributes that PowerShell doesn't like
        $XamlContent = $XamlContent -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'

        # Load XAML
        [xml]$xaml = $XamlContent
        $reader = New-Object System.Xml.XmlNodeReader $xaml
        $window = [Windows.Markup.XamlReader]::Load($reader)

        # Return the window object
        return $window
    }
    catch {
        Write-Error "Failed to load XAML: $_"
        return $null
    }
}

function Get-XamlObject {
    <#
    .SYNOPSIS
        Retrieves named controls from a WPF window
    .DESCRIPTION
        Searches the visual tree for controls with x:Name attributes
    .PARAMETER Window
        The WPF window object
    .PARAMETER Name
        The name of the control to find
    .EXAMPLE
        $button = Get-XamlObject -Window $window -Name "ProcessButton"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Window]$Window,

        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    try {
        return $Window.FindName($Name)
    }
    catch {
        Write-Warning "Control '$Name' not found in window"
        return $null
    }
}

#endregion

#region Activity Log Functions

function Write-Activity {
    <#
    .SYNOPSIS
        Writes colorized messages to the activity log
    .DESCRIPTION
        Adds timestamped, color-coded log entries to the RichTextBox activity log
    .PARAMETER RichTextBox
        The RichTextBox control for logging
    .PARAMETER Message
        The message to log
    .PARAMETER Level
        The log level (Info, Success, Warning, Error)
    .EXAMPLE
        Write-Activity -RichTextBox $log -Message "Processing complete" -Level Success
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Controls.RichTextBox]$RichTextBox,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )

    try {
        $timestamp = Get-Date -Format "HH:mm:ss"

        # Define colors based on level
        $color = switch ($Level) {
            'Info'    { 'Black' }
            'Success' { 'Green' }
            'Warning' { 'Orange' }
            'Error'   { 'Red' }
            'Debug'   { 'Gray' }
        }

        # Create the paragraph
        $paragraph = New-Object System.Windows.Documents.Paragraph

        # Add timestamp
        $timeRun = New-Object System.Windows.Documents.Run
        $timeRun.Text = "[$timestamp] "
        $timeRun.Foreground = "Gray"
        $paragraph.Inlines.Add($timeRun)

        # Add level indicator
        $levelRun = New-Object System.Windows.Documents.Run
        $levelRun.Text = "[$Level] "
        $levelRun.Foreground = $color
        $levelRun.FontWeight = "Bold"
        $paragraph.Inlines.Add($levelRun)

        # Add message
        $messageRun = New-Object System.Windows.Documents.Run
        $messageRun.Text = $Message
        $messageRun.Foreground = $color
        $paragraph.Inlines.Add($messageRun)

        # Add to document
        $RichTextBox.Document.Blocks.Add($paragraph)

        # Auto-scroll to bottom
        $RichTextBox.ScrollToEnd()
    }
    catch {
        Write-Warning "Failed to write to activity log: $_"
    }
}

function Clear-ActivityLog {
    <#
    .SYNOPSIS
        Clears the activity log
    .DESCRIPTION
        Removes all entries from the RichTextBox activity log
    .PARAMETER RichTextBox
        The RichTextBox control for logging
    .EXAMPLE
        Clear-ActivityLog -RichTextBox $log
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Controls.RichTextBox]$RichTextBox
    )

    try {
        $RichTextBox.Document.Blocks.Clear()
    }
    catch {
        Write-Warning "Failed to clear activity log: $_"
    }
}

#endregion

#region Status Bar Functions

function Write-StatusBar {
    <#
    .SYNOPSIS
        Updates the status bar with a message
    .DESCRIPTION
        Sets the text and optional progress bar state in the status bar
    .PARAMETER Label
        The Label control for the status text
    .PARAMETER Message
        The status message to display
    .PARAMETER ProgressBar
        Optional ProgressBar control
    .PARAMETER ShowProgress
        Whether to show the progress bar
    .PARAMETER ProgressValue
        The progress value (0-100)
    .EXAMPLE
        Write-StatusBar -Label $statusLabel -Message "Processing..." -ShowProgress $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Controls.Label]$Label,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [System.Windows.Controls.ProgressBar]$ProgressBar,

        [Parameter(Mandatory=$false)]
        [bool]$ShowProgress = $false,

        [Parameter(Mandatory=$false)]
        [int]$ProgressValue = 0
    )

    try {
        $Label.Content = $Message

        if ($ProgressBar) {
            if ($ShowProgress) {
                $ProgressBar.Visibility = 'Visible'
                $ProgressBar.Value = $ProgressValue
            } else {
                $ProgressBar.Visibility = 'Collapsed'
            }
        }

        # Force UI update
        $Label.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Render, [action]{})
    }
    catch {
        Write-Warning "Failed to update status bar: $_"
    }
}

#endregion

#region Async Execution

function Invoke-Async {
    <#
    .SYNOPSIS
        Executes a script block asynchronously
    .DESCRIPTION
        Runs PowerShell code in a background runspace to prevent UI freezing
    .PARAMETER ScriptBlock
        The code to execute asynchronously
    .PARAMETER ArgumentList
        Arguments to pass to the script block
    .EXAMPLE
        Invoke-Async -ScriptBlock { Start-Sleep -Seconds 5 } -ArgumentList @()
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory=$false)]
        [object[]]$ArgumentList = @()
    )

    try {
        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.ApartmentState = "STA"
        $runspace.ThreadOptions = "ReuseThread"
        $runspace.Open()

        $powershell = [powershell]::Create()
        $powershell.Runspace = $runspace
        $powershell.AddScript($ScriptBlock).AddArgument($ArgumentList) | Out-Null

        $handle = $powershell.BeginInvoke()

        return @{
            PowerShell = $powershell
            Handle = $handle
            Runspace = $runspace
        }
    }
    catch {
        Write-Error "Failed to execute async operation: $_"
        return $null
    }
}

#endregion

#region Dialog Functions

function Show-MessageDialog {
    <#
    .SYNOPSIS
        Displays a modern message dialog
    .DESCRIPTION
        Shows a Windows 11 styled message box
    .PARAMETER Title
        The dialog title
    .PARAMETER Message
        The message to display
    .PARAMETER Type
        The message type (Info, Warning, Error, Question)
    .EXAMPLE
        Show-MessageDialog -Title "Success" -Message "Operation completed" -Type Info
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Question')]
        [string]$Type = 'Info'
    )

    try {
        Add-Type -AssemblyName PresentationFramework

        $icon = switch ($Type) {
            'Info'     { [System.Windows.MessageBoxImage]::Information }
            'Warning'  { [System.Windows.MessageBoxImage]::Warning }
            'Error'    { [System.Windows.MessageBoxImage]::Error }
            'Question' { [System.Windows.MessageBoxImage]::Question }
        }

        $result = [System.Windows.MessageBox]::Show($Message, $Title, 'OK', $icon)
        return $result
    }
    catch {
        Write-Error "Failed to show message dialog: $_"
    }
}

function Get-FolderDialog {
    <#
    .SYNOPSIS
        Opens a folder browser dialog
    .DESCRIPTION
        Displays a folder selection dialog and returns the selected path
    .PARAMETER Description
        The description to show in the dialog
    .EXAMPLE
        $folder = Get-FolderDialog -Description "Select working directory"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Description = "Select a folder"
    )

    try {
        Add-Type -AssemblyName System.Windows.Forms

        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = $Description
        $folderBrowser.ShowNewFolderButton = $true

        if ($folderBrowser.ShowDialog() -eq 'OK') {
            return $folderBrowser.SelectedPath
        }
        return $null
    }
    catch {
        Write-Error "Failed to show folder dialog: $_"
        return $null
    }
}

#endregion
