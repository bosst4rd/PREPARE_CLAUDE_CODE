# Projekt-Struktur & Architektur

## 📐 Zero-Struktur Architektur

Die **Zero-Struktur** ist eine modulare, saubere Architektur mit klarer Trennung der Zuständigkeiten.

```
┌─────────────────────────────────────────────────────────────┐
│                     PowerShell GUI Tool                      │
│                         Main.ps1                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ bootstraps
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐     ┌──────────────┐
│   GUI Layer  │      │    Logic     │     │    Config    │
│              │      │    Layer     │     │    Layer     │
│  XAML Files  │◄────►│  Functions   │◄───►│  Settings    │
└──────────────┘      └──────────────┘     └──────────────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐     ┌──────────────┐
│ WPF Controls │      │Core Functions│     │ AppConfig    │
│  Templates   │      │   Helpers    │     │ JSON Export  │
│   Styling    │      │   Modules    │     │ JSON Import  │
└──────────────┘      └──────────────┘     └──────────────┘
```

## 📁 Verzeichnis-Struktur

```
PREPARE_CLAUDE_CODE/
│
├── 📄 Main.ps1                      # ⚙️  Application Entry Point
├── 📄 Start.bat                     # 🚀 Windows Launcher
├── 📄 README.md                     # 📖 Haupt-Dokumentation
├── 📄 QUICKSTART.md                 # 🎯 Schnelleinstieg
├── 📄 CHANGELOG.md                  # 📝 Versionshistorie
├── 📄 STRUCTURE.md                  # 📐 Diese Datei
├── 📄 .gitignore                    # 🚫 Git Ignores
├── 📄 .gitattributes                # ⚙️  Git Attributes
│
├── 📁 GUI/                          # 🎨 Presentation Layer
│   ├── App.xaml                    # Application Resources
│   ├── MainWindow.xaml             # Main Window Layout
│   └── ControlTemplates.xaml       # Windows 11 Styled Controls
│
├── 📁 Functions/                    # 🔧 Business Logic Layer
│   ├── Core.ps1                    # Core GUI Functions
│   └── Helpers.ps1                 # Utility Functions
│
├── 📁 Config/                       # ⚙️  Configuration Layer
│   └── Settings.ps1                # App Configuration
│
├── 📁 Modules/                      # 🔌 Extension Modules
│   ├── .gitkeep                    # Directory Placeholder
│   └── Example.ps1                 # Example Module
│
├── 📁 Data/                         # 💾 Data Storage
│   └── .gitkeep                    # Directory Placeholder
│
└── 📁 Logs/                         # 📋 Log Files
    └── .gitkeep                    # Directory Placeholder
```

## 🏗️ Komponenten-Hierarchie

### 1️⃣ GUI Layer (Presentation)

```
GUI/
├── App.xaml
│   └── Loads ControlTemplates.xaml
│
├── ControlTemplates.xaml
│   ├── Color Definitions (AccentColor, BackgroundColor, etc.)
│   ├── Brushes (AccentBrush, SurfaceBrush, etc.)
│   └── Styles
│       ├── ModernButton
│       ├── SecondaryButton
│       ├── ModernTextBox
│       ├── ModernLabel
│       ├── HeaderLabel
│       ├── ModernComboBox
│       ├── ModernCheckBox
│       ├── ModernProgressBar
│       ├── ModernTabControl
│       ├── ModernTabItem
│       └── ModernListBox
│
└── MainWindow.xaml
    ├── Header Section
    │   └── App Title
    │
    ├── Content Section (TabControl)
    │   ├── Tab 1: Hauptfunktionen
    │   │   ├── Input Section
    │   │   ├── Action Buttons
    │   │   └── Options (CheckBoxes)
    │   │
    │   ├── Tab 2: Konfiguration
    │   │   ├── Working Directory
    │   │   ├── Log File
    │   │   ├── Timeout
    │   │   └── Save/Load Buttons
    │   │
    │   └── Tab 3: Info
    │       └── About Information
    │
    ├── Activity Log Section
    │   ├── RichTextBox (Colored Logging)
    │   └── Clear Log Button
    │
    └── Status Bar Section
        ├── Status Label
        └── Progress Bar
```

### 2️⃣ Logic Layer (Functions)

```
Functions/
│
├── Core.ps1
│   ├── XAML Loading
│   │   ├── New-WPFDialog
│   │   └── Get-XamlObject
│   │
│   ├── Activity Logging
│   │   ├── Write-Activity
│   │   └── Clear-ActivityLog
│   │
│   ├── Status Management
│   │   └── Write-StatusBar
│   │
│   ├── Async Execution
│   │   └── Invoke-Async
│   │
│   └── Dialogs
│       ├── Show-MessageDialog
│       └── Get-FolderDialog
│
└── Helpers.ps1
    ├── Validation
    │   ├── Test-InputNotEmpty
    │   ├── Test-PathValid
    │   └── Test-NumericInput
    │
    ├── File Operations
    │   ├── Save-ToFile
    │   └── Read-FromFile
    │
    ├── Configuration
    │   ├── Get-ConfigValue
    │   └── Set-ConfigValue
    │
    ├── String Utilities
    │   ├── Format-Timestamp
    │   └── ConvertTo-SafeFilename
    │
    ├── Process Management
    │   └── Start-ProcessSafe
    │
    └── Error Handling
        └── Write-ErrorLog
```

### 3️⃣ Configuration Layer

```
Config/
│
└── Settings.ps1
    ├── $script:AppConfig (Hashtable)
    │   ├── Application Info
    │   ├── Paths
    │   ├── Logging Settings
    │   ├── Timeouts
    │   ├── UI Settings
    │   ├── Feature Flags
    │   └── Advanced Options
    │
    └── Functions
        ├── Initialize-AppConfiguration
        ├── Get-AppConfig
        ├── Export-AppConfig
        └── Import-AppConfig
```

### 4️⃣ Extension Layer (Modules)

```
Modules/
│
└── Example.ps1
    ├── Get-SystemInformation
    ├── Test-NetworkConnectivity
    ├── Get-DirectorySize
    ├── ConvertTo-JsonFormatted
    ├── Invoke-CommandWithRetry
    └── Integration Examples
```

## 🔄 Datenfluss

### Startup Flow

```
1. Start.bat (optional)
        │
        ▼
2. Main.ps1 - Script Execution
        │
        ├─► Load Config/Settings.ps1
        │       └─► Initialize-AppConfiguration
        │               ├─► Create Directories
        │               └─► Initialize Logs
        │
        ├─► Load Functions/Core.ps1
        │       └─► Export Core Functions
        │
        ├─► Load Functions/Helpers.ps1
        │       └─► Export Helper Functions
        │
        ├─► Load Modules/*.ps1 (optional)
        │
        ├─► Load GUI/MainWindow.xaml
        │       └─► New-WPFDialog
        │               └─► XAML Parser
        │                       └─► Window Object
        │
        ├─► Get UI Controls
        │       └─► Get-XamlObject (for each control)
        │
        ├─► Initialize UI from Config
        │
        ├─► Register Event Handlers
        │       ├─► Button Clicks
        │       ├─► Checkbox Changes
        │       └─► Window Events
        │
        └─► Show Window
                └─► $window.ShowDialog()
```

### User Interaction Flow

```
User Action (Button Click)
        │
        ▼
Event Handler
        │
        ├─► Write-Activity (Log: "Processing...")
        │
        ├─► Write-StatusBar (Status: "Working...")
        │
        ├─► Validate Input
        │   └─► Test-InputNotEmpty / Test-NumericInput
        │
        ├─► Business Logic
        │   ├─► Call Function from Core/Helpers/Modules
        │   └─► Process Data
        │
        ├─► Handle Result
        │   ├─► Success
        │   │   ├─► Write-Activity (Level: Success)
        │   │   └─► Show-MessageDialog
        │   │
        │   └─► Error
        │       ├─► Write-Activity (Level: Error)
        │       ├─► Write-ErrorLog
        │       └─► Show-MessageDialog (Type: Error)
        │
        └─► Write-StatusBar (Status: "Ready")
```

### Configuration Flow

```
Load Configuration
        │
        ├─► Import-AppConfig
        │       └─► Read Config/config.json
        │               └─► Update $script:AppConfig
        │                       └─► Sync to UI Controls
        │
Save Configuration
        │
        └─► Gather from UI Controls
                └─► Update $script:AppConfig
                        └─► Export-AppConfig
                                └─► Write Config/config.json
```

## 🎯 Design Patterns

### 1. Separation of Concerns

- **GUI**: Nur Präsentation (XAML)
- **Logic**: Business-Logik (PowerShell Functions)
- **Config**: Einstellungen (Settings.ps1)

### 2. Modular Architecture

- Jede Komponente ist austauschbar
- Unabhängige Module können hinzugefügt werden
- Keine zirkulären Abhängigkeiten

### 3. Error Handling Strategy

```
Try-Catch on every level
        │
        ├─► User-Friendly Messages (GUI)
        ├─► Activity Log (Real-time)
        └─► Error Log File (Persistent)
```

### 4. Configuration Management

- **Single Source of Truth**: `$script:AppConfig`
- **Import/Export**: JSON-basierte Persistenz
- **Default Values**: Fallback für fehlende Werte

### 5. Event-Driven Architecture

```
UI Events ─► Event Handlers ─► Business Logic ─► UI Updates
```

## 📊 Datenstrukturen

### AppConfig (Hashtable)

```powershell
@{
    # Strings
    AppName = "..."
    AppVersion = "..."

    # Paths
    WorkingDirectory = "..."
    LogDirectory = "..."

    # Booleans
    EnableLogging = $true/$false

    # Numbers
    DefaultTimeout = 30

    # Arrays (optional)
    AllowedExtensions = @(".txt", ".log")
}
```

### System Information Object

```powershell
[PSCustomObject]@{
    ComputerName = "..."
    UserName = "..."
    OSVersion = "..."
    PSVersion = "..."
    CurrentDirectory = "..."
    Timestamp = "..."
}
```

## 🔌 Erweiterungspunkte

### 1. Neue GUI-Elemente

1. Fügen Sie zu `MainWindow.xaml` hinzu
2. Holen Sie Control in `Main.ps1` mit `Get-XamlObject`
3. Registrieren Sie Event Handler

### 2. Neue Funktionen

1. Erstellen Sie Funktion in `Functions/` oder `Modules/`
2. Dokumentieren Sie mit XML-Kommentaren
3. Importieren Sie in `Main.ps1`
4. Rufen Sie in Event Handlers auf

### 3. Neue Konfigurationswerte

1. Fügen Sie zu `$script:AppConfig` in `Settings.ps1` hinzu
2. Nutzen Sie `Get-ConfigValue` / `Set-ConfigValue`
3. Synchronisieren Sie mit UI

### 4. Neue Module

1. Erstellen Sie `.ps1` in `Modules/`
2. Importieren Sie mit `. (Join-Path $scriptPath "Modules\YourModule.ps1")`
3. Nutzen Sie Export-ModuleMember (optional)

## 🛡️ Best Practices

### Code-Struktur

✅ **DO**
- XML-Dokumentation für alle Funktionen
- Try-Catch für Error Handling
- Input-Validierung
- Logging auf allen Ebenen

❌ **DON'T**
- Hardcoded Pfade
- Magic Numbers
- Direkte GUI-Manipulation in Business Logic
- Fehlende Error Handling

### Naming Conventions

- **Functions**: `Verb-Noun` (z.B. `Get-SystemInfo`)
- **Variables**: `$camelCase` (z.B. `$inputText`)
- **Parameters**: PascalCase (z.B. `[string]$FilePath`)
- **Controls**: PascalCase mit Suffix (z.B. `ProcessButton`)

### Error Handling Pattern

```powershell
try {
    # Validation
    if (-not (Test-Input $input)) {
        Write-Activity -Message "..." -Level Warning
        return
    }

    # Processing
    Write-Activity -Message "..." -Level Info

    # Success
    Write-Activity -Message "..." -Level Success
}
catch {
    Write-Activity -Message "Error: $_" -Level Error
    Write-ErrorLog -ErrorRecord $_ -LogPath $errorLog
}
```

---

**Hinweis**: Diese Struktur ermöglicht maximale Flexibilität bei gleichzeitiger Wahrung der Codequalität und Wartbarkeit.
