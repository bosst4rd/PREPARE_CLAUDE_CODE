# Settings.ps1 - Configuration Settings
# Part of PowerShell GUI Tool - Zero Structure

# Application Configuration
$script:AppConfig = @{
    # Application Info
    AppName = "PowerShell GUI Tool"
    AppVersion = "1.0.0"
    AppDescription = "Ein robustes, modulares Tool basierend auf der Zero-Struktur"

    # Paths
    WorkingDirectory = $PSScriptRoot
    LogDirectory = Join-Path $PSScriptRoot "Logs"
    ConfigDirectory = Join-Path $PSScriptRoot "Config"
    DataDirectory = Join-Path $PSScriptRoot "Data"

    # Logging
    EnableLogging = $true
    LogLevel = "Info"  # Debug, Info, Warning, Error
    LogFileName = "app.log"
    MaxLogSizeKB = 1024  # 1MB
    LogRetentionDays = 7

    # Timeouts
    DefaultTimeout = 30
    ProcessTimeout = 60
    NetworkTimeout = 30

    # UI Settings
    WindowWidth = 1000
    WindowHeight = 700
    ThemeMode = "Light"  # Light, Dark
    Language = "DE"  # DE, EN

    # Feature Flags
    EnableVerboseLogging = $false
    EnableAutoProcessing = $false
    EnableAutoBackup = $true

    # Advanced Options
    MaxConcurrentTasks = 4
    BufferSize = 8192
    EnableErrorReporting = $true
}

function Initialize-AppConfiguration {
    <#
    .SYNOPSIS
        Initializes the application configuration
    .DESCRIPTION
        Sets up directories and validates configuration
    .EXAMPLE
        Initialize-AppConfiguration
    #>
    [CmdletBinding()]
    param()

    try {
        # Create directories if they don't exist
        $directories = @(
            $script:AppConfig.LogDirectory,
            $script:AppConfig.ConfigDirectory,
            $script:AppConfig.DataDirectory
        )

        foreach ($dir in $directories) {
            if (-not (Test-Path -Path $dir)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
            }
        }

        # Initialize log file
        $logPath = Join-Path $script:AppConfig.LogDirectory $script:AppConfig.LogFileName
        if (-not (Test-Path -Path $logPath)) {
            "# Application Log - Started $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $logPath -Encoding UTF8
        }

        return $true
    }
    catch {
        Write-Error "Failed to initialize configuration: $_"
        return $false
    }
}

function Get-AppConfig {
    <#
    .SYNOPSIS
        Gets the application configuration
    .DESCRIPTION
        Returns the current app configuration hashtable
    .EXAMPLE
        $config = Get-AppConfig
    #>
    [CmdletBinding()]
    param()

    return $script:AppConfig
}

function Export-AppConfig {
    <#
    .SYNOPSIS
        Exports configuration to a file
    .DESCRIPTION
        Saves the current configuration to a JSON file
    .PARAMETER Path
        The file path to export to
    .EXAMPLE
        Export-AppConfig -Path "config.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = (Join-Path $script:AppConfig.ConfigDirectory "config.json")
    )

    try {
        $script:AppConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        return $true
    }
    catch {
        Write-Error "Failed to export configuration: $_"
        return $false
    }
}

function Import-AppConfig {
    <#
    .SYNOPSIS
        Imports configuration from a file
    .DESCRIPTION
        Loads configuration from a JSON file
    .PARAMETER Path
        The file path to import from
    .EXAMPLE
        Import-AppConfig -Path "config.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = (Join-Path $script:AppConfig.ConfigDirectory "config.json")
    )

    try {
        if (-not (Test-Path -Path $Path)) {
            Write-Warning "Configuration file not found: $Path"
            return $false
        }

        $importedConfig = Get-Content -Path $Path -Raw | ConvertFrom-Json

        # Update config with imported values
        foreach ($key in $importedConfig.PSObject.Properties.Name) {
            $script:AppConfig[$key] = $importedConfig.$key
        }

        return $true
    }
    catch {
        Write-Error "Failed to import configuration: $_"
        return $false
    }
}
