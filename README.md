# PowerShell GUI Tool

Ein robustes, modulares PowerShell GUI-Tool basierend auf der **Zero-Struktur** und inspiriert vom [PoSH-GUI-Template](https://github.com/nct911/PoSH-GUI-Template).

## 📋 Übersicht

Dieses Tool bietet eine moderne Windows 11-ähnliche WPF-Benutzeroberfläche für PowerShell-Automatisierungen mit einer klaren, erweiterbaren Architektur.

### ✨ Features

- **Windows 11 Styled UI**: Moderne, ansprechende Benutzeroberfläche
- **Zero-Struktur**: Modulare, saubere Architektur mit Trennung der Zuständigkeiten
- **Robustes Error Handling**: Umfassende Fehlerbehandlung und Logging
- **Konfigurierbar**: Flexibles Konfigurationssystem mit Import/Export
- **Asynchrone Operationen**: Nicht-blockierende UI durch Background-Processing
- **Activity Logging**: Farbcodiertes Echtzeit-Aktivitätsprotokoll
- **Erweiterbar**: Einfach neue Funktionen hinzufügen

## 📁 Projektstruktur

```
PREPARE_CLAUDE_CODE/
├── README.md                   # Diese Datei
├── Start.bat                   # Windows Launcher
│
├── Scripts/                    # 📜 PowerShell-Skripte
│   └── Main.ps1               # Haupteinstiegspunkt
│
├── GUI/                        # UI-Schicht (XAML)
│   ├── App.xaml               # Application-Ressourcen
│   ├── MainWindow.xaml        # Hauptfenster-Layout
│   └── ControlTemplates.xaml  # Windows 11 Styled Controls
│
├── Functions/                  # Business-Logik-Schicht
│   ├── Core.ps1              # Kern-GUI-Funktionen
│   └── Helpers.ps1           # Hilfs- und Utility-Funktionen
│
├── Config/                     # Konfigurationsschicht
│   └── Settings.ps1          # App-Konfiguration und Management
│
├── Modules/                    # Zusätzliche Module (optional)
│
├── Data/                       # Datenspeicher
│
└── Logs/                       # Log-Dateien
    ├── app.log               # Hauptanwendungs-Log
    └── error.log             # Fehlerprotokoll
```

## 🚀 Schnellstart

### Voraussetzungen

- Windows 10/11
- PowerShell 5.1 oder höher
- .NET Framework 4.5+

### Installation

1. Repository klonen oder herunterladen
2. In das Verzeichnis navigieren
3. PowerShell als Administrator öffnen (empfohlen)
4. Ausführungsrichtlinie setzen (falls erforderlich):

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Starten

**Option 1: Batch-Datei (empfohlen)**
```batch
Start.bat
```

**Option 2: PowerShell direkt**
```powershell
.\Scripts\Main.ps1
```

## 🏗️ Architektur - Zero-Struktur

Die Zero-Struktur basiert auf folgenden Prinzipien:

### 1. **Modular Design**
Klare Trennung der Zuständigkeiten in logische Module:
- **GUI**: Presentation Layer (XAML)
- **Functions**: Business Logic Layer
- **Config**: Configuration Layer

### 2. **Clean Architecture**
Jede Schicht hat eine definierte Verantwortung:
- UI-Logik in XAML
- Geschäftslogik in PowerShell-Funktionen
- Konfiguration separat verwaltet

### 3. **Extensibility**
Einfaches Hinzufügen neuer Features:
- Neue Tabs in MainWindow.xaml
- Neue Funktionen in Functions/
- Neue Module in Modules/

### 4. **Minimal Dependencies**
Self-contained mit Windows-nativen Technologien:
- WPF (Windows Presentation Foundation)
- PowerShell
- Keine externen Dependencies erforderlich

### 5. **Robust Error Handling**
Mehrschichtiges Fehlerbehandlungssystem:
- Try-Catch-Blöcke überall
- Error Logging
- User-friendly Fehlermeldungen

## 📚 Komponenten-Dokumentation

### GUI-Komponenten

#### **ControlTemplates.xaml**
Definiert Windows 11 styled Controls:
- `ModernButton`: Primärer Button-Stil
- `SecondaryButton`: Sekundärer Button-Stil
- `ModernTextBox`: Eingabefeld-Stil
- `ModernLabel`: Label-Stil
- `ModernComboBox`: Dropdown-Stil
- `ModernTabControl/TabItem`: Tab-Navigation

#### **MainWindow.xaml**
Hauptfenster-Layout mit 4 Bereichen:
1. **Header**: Titel und Navigation
2. **Content**: Tab-basierter Hauptinhalt
3. **Activity Log**: Echtzeitprotokoll
4. **Status Bar**: Status und Fortschrittsanzeige

### PowerShell-Funktionen

#### **Core.ps1**

##### GUI-Funktionen
- `New-WPFDialog`: XAML zu WPF-Objekt konvertieren
- `Get-XamlObject`: Named Controls abrufen

##### Logging-Funktionen
- `Write-Activity`: Farbcodierte Log-Einträge
- `Clear-ActivityLog`: Protokoll löschen

##### Status-Funktionen
- `Write-StatusBar`: Statusleiste aktualisieren

##### Async-Funktionen
- `Invoke-Async`: Nicht-blockierende Operationen

##### Dialog-Funktionen
- `Show-MessageDialog`: Moderne Nachrichtenboxen
- `Get-FolderDialog`: Ordner-Auswahl-Dialog

#### **Helpers.ps1**

##### Validierung
- `Test-InputNotEmpty`: Leere Eingaben prüfen
- `Test-PathValid`: Pfade validieren
- `Test-NumericInput`: Numerische Eingaben prüfen

##### Datei-Operationen
- `Save-ToFile`: Sicheres Schreiben
- `Read-FromFile`: Sicheres Lesen

##### Konfiguration
- `Get-ConfigValue`: Konfigurationswerte abrufen
- `Set-ConfigValue`: Konfigurationswerte setzen

##### String-Utilities
- `Format-Timestamp`: Timestamps formatieren
- `ConvertTo-SafeFilename`: Sichere Dateinamen

##### Prozess-Management
- `Start-ProcessSafe`: Sichere Prozess-Ausführung

##### Error Handling
- `Write-ErrorLog`: Fehlerprotokollierung

#### **Settings.ps1**

- `Initialize-AppConfiguration`: App initialisieren
- `Get-AppConfig`: Konfiguration abrufen
- `Export-AppConfig`: Konfiguration exportieren (JSON)
- `Import-AppConfig`: Konfiguration importieren

## 🔧 Anpassung

### Neue Funktionen hinzufügen

#### 1. GUI erweitern (MainWindow.xaml)

```xml
<Button Name="MyNewButton"
        Content="Neue Funktion"
        Style="{StaticResource ModernButton}"/>
```

#### 2. Control in Main.ps1 abrufen

```powershell
$myNewButton = Get-XamlObject -Window $window -Name "MyNewButton"
```

#### 3. Event Handler hinzufügen

```powershell
$myNewButton.Add_Click({
    Write-Activity -RichTextBox $activityLog -Message "Neue Funktion ausgeführt" -Level Info
    # Ihre Logik hier
})
```

### Neue Module hinzufügen

1. Erstellen Sie eine neue .ps1-Datei in `Modules/`
2. Importieren Sie sie in `Main.ps1`:

```powershell
. (Join-Path $scriptPath "Modules\MeinModul.ps1")
```

### Konfiguration anpassen

Bearbeiten Sie `Config/Settings.ps1`:

```powershell
$script:AppConfig = @{
    MeineEinstellung = "Wert"
    # ...
}
```

## 🎨 UI-Anpassung

### Theme ändern

Farben in `GUI/ControlTemplates.xaml` anpassen:

```xml
<Color x:Key="AccentColor">#0078D4</Color>  <!-- Primärfarbe -->
<Color x:Key="BackgroundColor">#F3F3F3</Color>  <!-- Hintergrund -->
```

### Dark Mode

Ändern Sie die Farbwerte auf dunklere Töne:

```xml
<Color x:Key="BackgroundColor">#202020</Color>
<Color x:Key="SurfaceColor">#2D2D2D</Color>
<Color x:Key="TextColor">#FFFFFF</Color>
```

## 📝 Best Practices

### Fehlerbehandlung

Alle Funktionen sollten Try-Catch verwenden:

```powershell
try {
    # Ihre Logik
    Write-Activity -RichTextBox $activityLog -Message "Erfolgreich" -Level Success
}
catch {
    Write-Activity -RichTextBox $activityLog -Message "Fehler: $_" -Level Error
    Write-ErrorLog -ErrorRecord $_ -LogPath $errorLogPath
}
```

### Logging

Verwenden Sie verschiedene Log-Level:

```powershell
Write-Activity -RichTextBox $activityLog -Message "Info" -Level Info
Write-Activity -RichTextBox $activityLog -Message "Erfolg" -Level Success
Write-Activity -RichTextBox $activityLog -Message "Warnung" -Level Warning
Write-Activity -RichTextBox $activityLog -Message "Fehler" -Level Error
Write-Activity -RichTextBox $activityLog -Message "Debug" -Level Debug
```

### UI-Updates

Status während langer Operationen aktualisieren:

```powershell
Write-StatusBar -Label $statusLabel -Message "Verarbeitung..." -ProgressBar $statusProgressBar -ShowProgress $true

# Ihre Operation

Write-StatusBar -Label $statusLabel -Message "Fertig" -ShowProgress $false
```

## 🐛 Fehlerbehebung

### Problem: Execution Policy verhindert Ausführung

**Lösung:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problem: XAML lädt nicht

**Lösung:**
- Prüfen Sie, ob alle XAML-Dateien im GUI-Ordner vorhanden sind
- Validieren Sie die XAML-Syntax
- Überprüfen Sie Dateipfade in Main.ps1

### Problem: Controls nicht gefunden

**Lösung:**
- Stellen Sie sicher, dass `x:Name` in XAML definiert ist
- Überprüfen Sie Groß-/Kleinschreibung
- Verwenden Sie `Get-XamlObject` korrekt

## 📖 Weitere Ressourcen

- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [WPF Documentation](https://docs.microsoft.com/en-us/dotnet/desktop/wpf/)
- [PoSH-GUI-Template](https://github.com/nct911/PoSH-GUI-Template)

## 📄 Lizenz

Dieses Projekt steht zur freien Verwendung zur Verfügung.

## 🤝 Beitragen

Verbesserungsvorschläge und Pull Requests sind willkommen!

## ⚡ Nächste Schritte

1. **Anpassen**: Passen Sie das Tool an Ihre Bedürfnisse an
2. **Erweitern**: Fügen Sie neue Funktionen hinzu
3. **Testen**: Testen Sie ausgiebig
4. **Deployen**: Verteilen Sie an Ihre Benutzer

---

**Version:** 1.0.0
**Erstellt mit:** PowerShell & WPF
**Architektur:** Zero-Struktur
