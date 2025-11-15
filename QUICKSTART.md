# Quick Start Guide

## 🚀 Schnellstart in 3 Schritten

### Schritt 1: Voraussetzungen prüfen

Öffnen Sie PowerShell und prüfen Sie die Version:

```powershell
$PSVersionTable.PSVersion
```

Sie benötigen **mindestens Version 5.1**.

### Schritt 2: Ausführungsrichtlinie setzen

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Schritt 3: Application starten

**Option 1: Mit Batch-Datei (einfach)**
```batch
cd PREPARE_CLAUDE_CODE
Start.bat
```

**Option 2: Mit PowerShell**
```powershell
cd PREPARE_CLAUDE_CODE
.\Scripts\Main.ps1
```

## 📝 Erste Schritte nach dem Start

### 1. **Hauptfunktionen testen**

1. Geben Sie Text in das Eingabefeld ein
2. Wählen Sie eine Option aus dem Dropdown
3. Klicken Sie auf "Verarbeiten"
4. Beobachten Sie das Aktivitätsprotokoll

### 2. **Konfiguration anpassen**

1. Wechseln Sie zum Tab "Konfiguration"
2. Ändern Sie das Arbeitsverzeichnis
3. Passen Sie den Timeout-Wert an
4. Klicken Sie auf "Speichern"

### 3. **Optionen aktivieren**

Aktivieren Sie die Checkboxen:
- **Verbose Logging**: Detaillierte Protokollierung
- **Automatische Verarbeitung**: Auto-Processing
- **Backup erstellen**: Automatische Backups

## 🎯 Wichtige UI-Elemente

| Element | Beschreibung |
|---------|-------------|
| **Eingabefeld** | Haupteingabe für Textverarbeitung |
| **Option Dropdown** | Auswahl zwischen verschiedenen Verarbeitungsmodi |
| **Aktion Buttons** | Führen vordefinierte Aktionen aus |
| **Aktivitätsprotokoll** | Zeigt alle Operationen in Echtzeit |
| **Statusleiste** | Aktueller Status der Anwendung |

## 🔍 Troubleshooting

### Problem: "Die Datei kann nicht geladen werden"

**Ursache:** Execution Policy blockiert das Skript

**Lösung:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\Scripts\Main.ps1
```

### Problem: "XAML file not found"

**Ursache:** Falsches Arbeitsverzeichnis

**Lösung:**
```powershell
cd PREPARE_CLAUDE_CODE  # Zum Projektverzeichnis wechseln
.\Scripts\Main.ps1
```

### Problem: GUI zeigt Fehler beim Start

**Ursache:** Fehlende .NET Framework Components

**Lösung:** Installieren Sie .NET Framework 4.5 oder höher

## 📚 Nächste Schritte

1. Lesen Sie das vollständige [README.md](README.md)
2. Erkunden Sie die Beispiel-Funktionen
3. Passen Sie das Tool an Ihre Bedürfnisse an
4. Fügen Sie eigene Funktionen hinzu

## 💡 Tipps

- **Protokoll löschen**: Klicken Sie auf "Protokoll löschen" für eine saubere Ansicht
- **Konfiguration sichern**: Exportieren Sie Ihre Einstellungen mit "Speichern"
- **Tabs nutzen**: Organisieren Sie verschiedene Funktionen in separaten Tabs
- **Status beobachten**: Die Statusleiste zeigt den aktuellen Zustand

## 🎨 Personalisierung

Möchten Sie das Aussehen anpassen? Bearbeiten Sie:
- `GUI/ControlTemplates.xaml` für Farben und Styles
- `GUI/MainWindow.xaml` für Layout und Struktur

---

Viel Erfolg mit Ihrem PowerShell GUI Tool! 🎉
