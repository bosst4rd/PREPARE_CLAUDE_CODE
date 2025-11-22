# Windows 11 OOTB Setup Tool

## Übersicht

Dieses Tool passt einen Windows 11 "Out of the Box" (OOTB) Computer automatisch an eure Unternehmens-Vorlage an.

## Features

### ✅ Modul 1: Einstieg & Initialisierung
- Admin-Rechte Prüfung
- Erstellung der Ordnerstruktur (C:\CGM)
- Automatisches Registry-Backup
- System-Informationen erfassen

### ✅ Modul 2: Cleanup
- **Widgets entfernen**: Wetter, News, etc.
- **Desktop switchen** aus Taskleiste entfernen
- **Suche** deaktivieren
- **Neuigkeiten und Interessen** entfernen
- **Copilot** komplett deaktivieren
- **OneDrive** deaktivieren
- **Standard-Pins** entfernen (Edge, MS Store, Outlook, Office, Teams)
- **Desktop bereinigen**: Edge, Benutzer, Geräte-Verknüpfungen entfernen
- **Geräte entfernen**: Fax-Drucker, XPS Writer

### ✅ Modul 3: Optik & Ergonomie
- **Taskleiste linksbündig** setzen
- **Bildschirmschoner** deaktivieren
- **Profilbild** zurücksetzen
- **Dateierweiterungen** einblenden
- **Lockscreen** deaktivieren (nolockscreen)
- **Aktive Anwendungen nie gruppieren** (Taskleiste)
- **Vollständige Pfade** anzeigen
- **Versteckte Dateien** anzeigen

### ✅ Modul 4: Performance & Energieeinstellungen
- **Autostart säubern** (OneDrive, Teams, etc.)
- **Energieoptionen**:
  - Höchstleistung aktivieren
  - Monitor-Timeout: Nie
  - Festplatten-Timeout: Nie
  - Standby: Nie
- **Schnellstart/Hibernate** deaktivieren
- **Energie sparen** aus Menü ausblenden
- **Netzwerkadapter** Energiesparmodus deaktivieren
- **USB Selective Suspend** deaktivieren
- **Prozessor** auf 100% Leistung

## Installation & Nutzung

### Voraussetzungen
- Windows 11 (frische Installation oder bestehend)
- Administrator-Rechte
- PowerShell 5.1 oder höher

### Schnellstart

1. **PowerShell als Administrator öffnen**:
   - Rechtsklick auf Start-Button
   - "Terminal (Administrator)" oder "Windows PowerShell (Administrator)"

2. **Execution Policy temporär anpassen** (falls nötig):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
   ```

3. **Skript ausführen**:
   ```powershell
   # Vollversion mit allen Modulen
   .\Win11-Setup-Complete.ps1
   ```

4. **Menü nutzen**:
   - Einzelne Module testen (empfohlen!)
   - Oder direkt [A] für komplettes Setup

### Empfohlene Vorgehensweise

**Erste Verwendung - Schritt für Schritt:**

1. Starte mit **Modul 1** (Initialisierung)
   - Prüft System und erstellt Struktur
   - Erstellt erstes Backup

2. Teste **Modul 2** (Cleanup) separat
   - Macht die meisten sichtbaren Änderungen
   - Explorer-Neustart erforderlich
   - Teste ob alles funktioniert

3. Dann **Modul 3** (Optik)
   - Weitere Explorer-Änderungen
   - Explorer-Neustart erforderlich

4. Abschließend **Modul 4** (Performance)
   - Energieeinstellungen
   - Keine weiteren Neustarts nötig

**Nach erfolgreichem Test:**
- Nutze Option [A] für automatisches Durchlaufen aller Module

## Dateistruktur

```
C:\CGM\
├── Logs\
│   └── Win11-Setup-YYYYMMDD-HHMMSS.log
└── Registry-Backups\
    ├── Registry-Backup-Initial-YYYYMMDD-HHMMSS.reg
    ├── Registry-Backup-Modul2-YYYYMMDD-HHMMSS.reg
    └── ...
```

## Logging

Alle Aktionen werden detailliert geloggt:
- Pfad: `C:\CGM\Logs\`
- Format: `Win11-Setup-YYYYMMDD-HHMMSS.log`
- Ansicht im Tool: Menüpunkt [L]

## Registry-Backups

Vor kritischen Änderungen werden automatisch Backups erstellt:
- Pfad: `C:\CGM\Registry-Backups\`
- Format: .reg Datei (wiederherstellbar mit Doppelklick)

### Backup wiederherstellen

1. Navigiere zu `C:\CGM\Registry-Backups\`
2. Doppelklick auf gewünschtes Backup
3. Bestätige den Import
4. Neustart/Explorer-Neustart durchführen

## Troubleshooting

### Problem: "Skript kann nicht ausgeführt werden"

**Lösung:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

### Problem: "Zugriff verweigert"

**Lösung:** PowerShell als Administrator starten!

### Problem: Explorer startet nicht neu

**Lösung:** Manueller Neustart:
1. Task-Manager öffnen (Strg+Shift+Esc)
2. Prozess "Windows-Explorer" suchen
3. Rechtsklick → "Task beenden"
4. Datei → "Neuer Task" → `explorer.exe`

### Problem: Änderungen nicht sichtbar

**Lösung:**
1. Explorer neu starten (siehe oben)
2. Ggf. kompletten Neustart durchführen
3. Log-Datei prüfen auf Fehler

### Problem: Modul 2 schlägt fehl

**Häufigste Ursache:** Fehlende Berechtigungen oder Apps bereits deinstalliert

**Lösung:** 
- Log-Datei prüfen: `C:\CGM\Logs\`
- Registry-Backup liegt vor, kann wiederhergestellt werden
- Einzelne Schritte manuell nachvollziehen

## Sicherheit

### Was wird NICHT gemacht:
- ✗ Keine Windows-Features deinstalliert (nur deaktiviert)
- ✗ Keine System-Dateien gelöscht
- ✗ Keine unwiderruflichen Änderungen
- ✗ Kein Eingriff in Windows Update

### Was wird gemacht:
- ✓ Registry-Einträge ändern (mit Backup!)
- ✓ Desktop-Verknüpfungen entfernen
- ✓ Drucker entfernen (Fax, XPS)
- ✓ Autostart-Programme deaktivieren
- ✓ Energieeinstellungen anpassen

### Rückgängig machen:
Alle Änderungen können rückgängig gemacht werden:
1. Via Registry-Backup (automatisch erstellt)
2. Via Windows Systemwiederherstellung
3. Oder manuell durch erneutes Aktivieren

## Bekannte Einschränkungen

1. **OneDrive**: Wird deaktiviert, aber nicht deinstalliert
2. **Copilot**: Button verschwindet, App bleibt installiert
3. **Microsoft Store**: Pin wird entfernt, App bleibt nutzbar
4. **Taskbar-Pins**: Reset erfolgt, neue Pins müssen manuell gesetzt werden

## Zukünftige Module (in Planung)

- **Modul 5**: Software & Daten
  - Chocolatey Installation
  - Standard-Software (7zip, Firefox, Acrobat, etc.)
  - Fernwartung (TeamViewer QS, CGM Support)

- **Modul 6**: Komponenten
  - Java Updates
  - .NET Installation
  - VC Redist

- **Modul 7**: Funktionalität
  - UAC deaktivieren
  - Standard-Apps setzen (Browser, PDF)
  - Intelligente Zwischenablage
  - Laufwerksbuchstaben optimieren
  - Nummernblock aktivieren

- **Modul 8**: ALBIS Spezifisch
  - EPSON LQ-400 Drucker
  - Laufwerksbezeichnungen

## Support

Bei Problemen:
1. Log-Datei prüfen: `C:\CGM\Logs\`
2. Registry-Backup wiederherstellen (falls nötig)
3. Einzelne Module testen statt [A]
4. System-Neustart durchführen

## Version

**Aktuell: v1.0**
- Module 1-4 komplett implementiert
- Getestet auf Windows 11 23H2
- Stabiles Logging
- Automatische Backups

## Lizenz & Haftung

Dieses Tool wird "AS IS" bereitgestellt.
- Teste vor Produktiveinsatz!
- Backups werden automatisch erstellt
- Änderungen sind reversibel
- Eigene Verantwortung bei Nutzung

---

**Entwickelt für die Windows 11 Unternehmens-Standardisierung**

Letzte Aktualisierung: November 2024
