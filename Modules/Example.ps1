# Example.ps1 - Example Module
# Demonstrates how to create custom modules for the PowerShell GUI Tool

<#
.SYNOPSIS
    Example module showing how to extend the PowerShell GUI Tool
.DESCRIPTION
    This module provides example functions that can be used in your custom implementations.
    Copy this file and modify it to create your own modules.
.NOTES
    Version: 1.0.0
    Author: Example
#>

#region Example Functions

function Get-SystemInformation {
    <#
    .SYNOPSIS
        Retrieves basic system information
    .DESCRIPTION
        Collects computer name, OS version, and PowerShell version
    .EXAMPLE
        $sysInfo = Get-SystemInformation
    #>
    [CmdletBinding()]
    param()

    try {
        $info = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            OSVersion = [System.Environment]::OSVersion.VersionString
            PSVersion = $PSVersionTable.PSVersion.ToString()
            CurrentDirectory = Get-Location
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        return $info
    }
    catch {
        Write-Error "Failed to get system information: $_"
        return $null
    }
}

function Test-NetworkConnectivity {
    <#
    .SYNOPSIS
        Tests network connectivity to a host
    .DESCRIPTION
        Performs a ping test to check if a host is reachable
    .PARAMETER HostName
        The hostname or IP address to test
    .PARAMETER Count
        Number of ping attempts
    .EXAMPLE
        Test-NetworkConnectivity -HostName "google.com" -Count 4
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$HostName,

        [Parameter(Mandatory=$false)]
        [int]$Count = 1
    )

    try {
        $result = Test-Connection -ComputerName $HostName -Count $Count -Quiet
        return $result
    }
    catch {
        Write-Error "Network connectivity test failed: $_"
        return $false
    }
}

function Get-DirectorySize {
    <#
    .SYNOPSIS
        Calculates the size of a directory
    .DESCRIPTION
        Recursively calculates the total size of all files in a directory
    .PARAMETER Path
        The directory path to analyze
    .EXAMPLE
        $size = Get-DirectorySize -Path "C:\Windows"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        if (-not (Test-Path -Path $Path -PathType Container)) {
            throw "Path is not a valid directory: $Path"
        }

        $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum

        $result = [PSCustomObject]@{
            Path = $Path
            TotalSizeBytes = $totalSize
            TotalSizeKB = [math]::Round($totalSize / 1KB, 2)
            TotalSizeMB = [math]::Round($totalSize / 1MB, 2)
            TotalSizeGB = [math]::Round($totalSize / 1GB, 2)
            FileCount = $files.Count
        }

        return $result
    }
    catch {
        Write-Error "Failed to calculate directory size: $_"
        return $null
    }
}

function ConvertTo-JsonFormatted {
    <#
    .SYNOPSIS
        Converts object to formatted JSON
    .DESCRIPTION
        Converts a PowerShell object to pretty-printed JSON
    .PARAMETER InputObject
        The object to convert
    .PARAMETER Depth
        The depth of recursion
    .EXAMPLE
        $obj | ConvertTo-JsonFormatted -Depth 5
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [object]$InputObject,

        [Parameter(Mandatory=$false)]
        [int]$Depth = 10
    )

    try {
        return $InputObject | ConvertTo-Json -Depth $Depth
    }
    catch {
        Write-Error "JSON conversion failed: $_"
        return $null
    }
}

function Invoke-CommandWithRetry {
    <#
    .SYNOPSIS
        Executes a command with retry logic
    .DESCRIPTION
        Attempts to execute a script block multiple times on failure
    .PARAMETER ScriptBlock
        The command to execute
    .PARAMETER MaxRetries
        Maximum number of retry attempts
    .PARAMETER RetryDelaySeconds
        Delay between retries in seconds
    .EXAMPLE
        Invoke-CommandWithRetry -ScriptBlock { Get-WebContent } -MaxRetries 3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory=$false)]
        [int]$RetryDelaySeconds = 2
    )

    $attempt = 1
    $success = $false

    while ($attempt -le $MaxRetries -and -not $success) {
        try {
            Write-Verbose "Attempt $attempt of $MaxRetries"
            $result = & $ScriptBlock
            $success = $true
            return $result
        }
        catch {
            Write-Warning "Attempt $attempt failed: $_"

            if ($attempt -lt $MaxRetries) {
                Write-Verbose "Waiting $RetryDelaySeconds seconds before retry..."
                Start-Sleep -Seconds $RetryDelaySeconds
            }

            $attempt++
        }
    }

    if (-not $success) {
        throw "Command failed after $MaxRetries attempts"
    }
}

#endregion

#region Integration Example

<#
How to use this module in Main.ps1:

1. Import the module:
   . (Join-Path $scriptPath "Modules\Example.ps1")

2. Add a button to your XAML:
   <Button Name="SysInfoButton" Content="System Info" Style="{StaticResource ModernButton}"/>

3. Get the control:
   $sysInfoButton = Get-XamlObject -Window $window -Name "SysInfoButton"

4. Add event handler:
   $sysInfoButton.Add_Click({
       try {
           Write-Activity -RichTextBox $activityLog -Message "Retrieving system information..." -Level Info

           $sysInfo = Get-SystemInformation

           $message = @"
Computer: $($sysInfo.ComputerName)
User: $($sysInfo.UserName)
OS: $($sysInfo.OSVersion)
PowerShell: $($sysInfo.PSVersion)
"@

           Write-Activity -RichTextBox $activityLog -Message $message -Level Success
           Show-MessageDialog -Title "System Information" -Message $message -Type Info
       }
       catch {
           Write-Activity -RichTextBox $activityLog -Message "Error: $_" -Level Error
       }
   })
#>

#endregion

# Export functions (optional - comment out if not using as a module)
# Export-ModuleMember -Function Get-SystemInformation, Test-NetworkConnectivity, Get-DirectorySize, ConvertTo-JsonFormatted, Invoke-CommandWithRetry
