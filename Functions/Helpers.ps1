# Helpers.ps1 - Helper Utility Functions
# Part of PowerShell GUI Tool - Zero Structure

#region Validation Functions

function Test-InputNotEmpty {
    <#
    .SYNOPSIS
        Validates that input is not empty
    .DESCRIPTION
        Checks if a string is null, empty, or whitespace
    .PARAMETER Input
        The input string to validate
    .EXAMPLE
        if (Test-InputNotEmpty -Input $text) { ... }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Input
    )

    return -not [string]::IsNullOrWhiteSpace($Input)
}

function Test-PathValid {
    <#
    .SYNOPSIS
        Validates that a path exists
    .DESCRIPTION
        Checks if a file or folder path exists
    .PARAMETER Path
        The path to validate
    .EXAMPLE
        if (Test-PathValid -Path $folder) { ... }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    return Test-Path -Path $Path -PathType Any
}

function Test-NumericInput {
    <#
    .SYNOPSIS
        Validates that input is numeric
    .DESCRIPTION
        Checks if a string can be converted to a number
    .PARAMETER Input
        The input string to validate
    .EXAMPLE
        if (Test-NumericInput -Input $text) { ... }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Input
    )

    $number = 0
    return [int]::TryParse($Input, [ref]$number)
}

#endregion

#region File Operations

function Save-ToFile {
    <#
    .SYNOPSIS
        Saves content to a file safely
    .DESCRIPTION
        Writes content to a file with error handling and optional backup
    .PARAMETER Path
        The file path to write to
    .PARAMETER Content
        The content to write
    .PARAMETER CreateBackup
        Whether to create a backup of existing file
    .EXAMPLE
        Save-ToFile -Path "output.txt" -Content $data -CreateBackup $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$false)]
        [bool]$CreateBackup = $false
    )

    try {
        # Create backup if requested and file exists
        if ($CreateBackup -and (Test-Path -Path $Path)) {
            $backupPath = "$Path.bak"
            Copy-Item -Path $Path -Destination $backupPath -Force
        }

        # Write content
        $Content | Out-File -FilePath $Path -Encoding UTF8 -Force

        return $true
    }
    catch {
        Write-Error "Failed to save file: $_"
        return $false
    }
}

function Read-FromFile {
    <#
    .SYNOPSIS
        Reads content from a file safely
    .DESCRIPTION
        Reads file content with error handling
    .PARAMETER Path
        The file path to read from
    .EXAMPLE
        $content = Read-FromFile -Path "input.txt"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        if (-not (Test-Path -Path $Path)) {
            Write-Warning "File not found: $Path"
            return $null
        }

        return Get-Content -Path $Path -Raw -Encoding UTF8
    }
    catch {
        Write-Error "Failed to read file: $_"
        return $null
    }
}

#endregion

#region Configuration Management

function Get-ConfigValue {
    <#
    .SYNOPSIS
        Retrieves a configuration value from hashtable
    .DESCRIPTION
        Gets a value from config hashtable with default fallback
    .PARAMETER Config
        The configuration hashtable
    .PARAMETER Key
        The configuration key
    .PARAMETER Default
        The default value if key not found
    .EXAMPLE
        $value = Get-ConfigValue -Config $config -Key "Timeout" -Default 30
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,

        [Parameter(Mandatory=$true)]
        [string]$Key,

        [Parameter(Mandatory=$false)]
        [object]$Default = $null
    )

    if ($Config.ContainsKey($Key)) {
        return $Config[$Key]
    }
    return $Default
}

function Set-ConfigValue {
    <#
    .SYNOPSIS
        Sets a configuration value in hashtable
    .DESCRIPTION
        Adds or updates a value in the config hashtable
    .PARAMETER Config
        The configuration hashtable
    .PARAMETER Key
        The configuration key
    .PARAMETER Value
        The value to set
    .EXAMPLE
        Set-ConfigValue -Config $config -Key "Timeout" -Value 60
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,

        [Parameter(Mandatory=$true)]
        [string]$Key,

        [Parameter(Mandatory=$true)]
        [object]$Value
    )

    $Config[$Key] = $Value
}

#endregion

#region String Utilities

function Format-Timestamp {
    <#
    .SYNOPSIS
        Formats a timestamp string
    .DESCRIPTION
        Returns a formatted timestamp for logging
    .PARAMETER Format
        The format string (default: yyyy-MM-dd HH:mm:ss)
    .EXAMPLE
        $time = Format-Timestamp
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Format = "yyyy-MM-dd HH:mm:ss"
    )

    return Get-Date -Format $Format
}

function ConvertTo-SafeFilename {
    <#
    .SYNOPSIS
        Converts a string to a safe filename
    .DESCRIPTION
        Removes invalid characters from a filename
    .PARAMETER Input
        The input string
    .EXAMPLE
        $filename = ConvertTo-SafeFilename -Input "My File: Version 1.0"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Input
    )

    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $pattern = "[$([regex]::Escape($invalidChars -join ''))]"

    return $Input -replace $pattern, '_'
}

#endregion

#region Process Management

function Start-ProcessSafe {
    <#
    .SYNOPSIS
        Starts a process with error handling
    .DESCRIPTION
        Launches an external process safely with output capture
    .PARAMETER FilePath
        The executable path
    .PARAMETER ArgumentList
        The arguments to pass
    .PARAMETER WorkingDirectory
        The working directory
    .EXAMPLE
        $result = Start-ProcessSafe -FilePath "cmd.exe" -ArgumentList "/c dir"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$false)]
        [string[]]$ArgumentList = @(),

        [Parameter(Mandatory=$false)]
        [string]$WorkingDirectory = (Get-Location).Path
    )

    try {
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $FilePath
        $processInfo.Arguments = $ArgumentList -join ' '
        $processInfo.WorkingDirectory = $WorkingDirectory
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo

        $process.Start() | Out-Null
        $output = $process.StandardOutput.ReadToEnd()
        $error = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        return @{
            ExitCode = $process.ExitCode
            Output = $output
            Error = $error
        }
    }
    catch {
        Write-Error "Failed to start process: $_"
        return @{
            ExitCode = -1
            Output = ""
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region Error Handling

function Write-ErrorLog {
    <#
    .SYNOPSIS
        Writes error information to a log file
    .DESCRIPTION
        Logs error details with timestamp to a file
    .PARAMETER ErrorRecord
        The error record to log
    .PARAMETER LogPath
        The path to the log file
    .EXAMPLE
        Write-ErrorLog -ErrorRecord $_ -LogPath "errors.log"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory=$false)]
        [string]$LogPath = "error.log"
    )

    try {
        $timestamp = Format-Timestamp
        $logEntry = @"
[$timestamp] ERROR
Message: $($ErrorRecord.Exception.Message)
Location: $($ErrorRecord.InvocationInfo.ScriptName):$($ErrorRecord.InvocationInfo.ScriptLineNumber)
Command: $($ErrorRecord.InvocationInfo.Line.Trim())
Stack Trace: $($ErrorRecord.ScriptStackTrace)
---
"@

        Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
    }
    catch {
        Write-Warning "Failed to write error log: $_"
    }
}

#endregion
