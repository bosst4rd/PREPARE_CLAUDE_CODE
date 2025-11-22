# Changelog

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [1.0.0] - 2025-11-15

### Hinzugefügt

#### Architektur
- Zero-Struktur Implementierung mit modularer Architektur
- Klare Trennung: GUI / Functions / Config
- Vollständig dokumentierte Codebase

#### GUI-Komponenten
- `ControlTemplates.xaml`: Windows 11 styled WPF Controls
  - ModernButton (Primär & Sekundär)
  - ModernTextBox mit Fokus-Effekten
  - ModernLabel und HeaderLabel
  - ModernComboBox, CheckBox, ProgressBar
  - ModernTabControl mit TabItems
  - ModernListBox
- `MainWindow.xaml`: Hauptfenster mit 4-Bereich-Layout
  - Header mit App-Titel
  - Tab-basierter Content-Bereich
  - Activity Log mit RichTextBox
  - Status Bar mit Progress-Anzeige
- `App.xaml`: Application-Ressourcen-Konfiguration

#### Funktionen (Core.ps1)
- **XAML Loading**
  - `New-WPFDialog`: XAML zu WPF konvertieren
  - `Get-XamlObject`: Named Controls abrufen
- **Activity Logging**
  - `Write-Activity`: Farbcodierte Log-Einträge (Info/Success/Warning/Error/Debug)
  - `Clear-ActivityLog`: Protokoll zurücksetzen
- **Status Management**
  - `Write-StatusBar`: Status und Progress aktualisieren
- **Asynchrone Ausführung**
  - `Invoke-Async`: Background Runspace Execution
- **Dialoge**
  - `Show-MessageDialog`: Moderne Message Boxes
  - `Get-FolderDialog`: Ordner-Auswahl

#### Hilfsfunktionen (Helpers.ps1)
- **Validierung**
  - `Test-InputNotEmpty`: Leere Eingaben prüfen
  - `Test-PathValid`: Pfad-Validierung
  - `Test-NumericInput`: Numerische Eingaben prüfen
- **Datei-Operationen**
  - `Save-ToFile`: Sicheres Schreiben mit Backup-Option
  - `Read-FromFile`: Sicheres Lesen mit Error Handling
- **Konfiguration**
  - `Get-ConfigValue`: Config-Werte mit Default-Fallback
  - `Set-ConfigValue`: Config-Werte setzen
- **String Utilities**
  - `Format-Timestamp`: Timestamp-Formatierung
  - `ConvertTo-SafeFilename`: Sichere Dateinamen generieren
- **Prozess-Management**
  - `Start-ProcessSafe`: Externe Prozesse sicher starten
- **Error Handling**
  - `Write-ErrorLog`: Strukturierte Fehlerprotokollierung

#### Konfiguration (Settings.ps1)
- `Initialize-AppConfiguration`: App-Initialisierung mit Directory-Setup
- `Get-AppConfig`: Zugriff auf Konfiguration
- `Export-AppConfig`: JSON-Export der Konfiguration
- `Import-AppConfig`: JSON-Import der Konfiguration
- Umfassende Standard-Konfiguration mit 20+ Einstellungen

#### Main Application (Main.ps1)
- Vollständiger Application Lifecycle
- Modul-Import-System
- XAML-Loading mit Error Handling
- Event Handler für alle UI-Elemente:
  - Process Button: Eingabeverarbeitung
  - Action Buttons: Beispiel-Aktionen
  - Clear Button: Formular zurücksetzen
  - Browse Button: Ordner-Auswahl
  - Save/Load Config: Konfigurationsverwaltung
  - Clear Log: Protokoll löschen
- Window Lifecycle Events (Loaded/Closing)
- Umfassende Fehlerbehandlung

#### Dokumentation
- **README.md**: Vollständige Projekt-Dokumentation
  - Übersicht und Features
  - Projektstruktur-Diagramm
  - Architektur-Erklärung (Zero-Struktur)
  - Komponenten-Dokumentation
  - Anpassungs-Guide
  - Best Practices
  - Troubleshooting
- **QUICKSTART.md**: Schnelleinstieg in 3 Schritten
- **CHANGELOG.md**: Versionshistorie (diese Datei)

#### Projekt-Setup
- `.gitignore`: Git-Ignores für Logs, Config, Data
- Verzeichnisstruktur mit Placeholders
- Support für Data, Logs, Modules Ordner

### Features im Detail

#### Tab 1: Hauptfunktionen
- Eingabefeld mit Verarbeitung
- Option-Dropdown (3 Optionen)
- 4 Action Buttons (3 Aktionen + Clear)
- 3 Konfigurier bare Checkboxes:
  - Verbose Logging
  - Automatische Verarbeitung
  - Backup erstellen

#### Tab 2: Konfiguration
- Arbeitsverzeichnis-Auswahl mit Browser
- Log-Datei-Konfiguration
- Timeout-Einstellung (numerisch validiert)
- Speichern/Laden von Konfigurationen

#### Tab 3: Info
- Versions-Information
- Tool-Beschreibung
- Architektur-Information

#### Activity Log
- Echtzeit-Protokollierung
- Farbcodierung nach Level
- Timestamp für jeden Eintrag
- Auto-Scroll zum neuesten Eintrag
- Clear-Funktion

#### Status Bar
- Status-Text-Anzeige
- Progress Bar (ein-/ausblendbar)
- Accent-farbiger Hintergrund

### Technische Details
- **PowerShell Version**: 5.1+
- **Framework**: .NET Framework 4.5+
- **UI**: WPF (Windows Presentation Foundation)
- **Architektur**: MVVM-ähnlich mit Code-Behind
- **Error Handling**: Try-Catch mit strukturiertem Logging
- **Threading**: STA Apartment mit Runspace Support

### Qualität
- Vollständig kommentierter Code
- XML-Dokumentation für alle Funktionen
- Konsistentes Naming (PascalCase für Funktionen)
- Error Handling auf allen Ebenen
- Input-Validierung
- Safe File Operations mit Backup-Support

---

## [Unreleased]

### Geplant
- Dark Mode Toggle
- Mehrsprachigkeit (DE/EN)
- Export-Funktionen für Activity Log
- Drag & Drop Support
- Custom Theme-Editor
- Plugin-System für Module
- Unit Tests
- CI/CD Pipeline

---

**Hinweis**: Versionsnummern folgen dem Schema MAJOR.MINOR.PATCH
- **MAJOR**: Inkompatible API-Änderungen
- **MINOR**: Neue Funktionalität (abwärtskompatibel)
- **PATCH**: Bugfixes (abwärtskompatibel)
