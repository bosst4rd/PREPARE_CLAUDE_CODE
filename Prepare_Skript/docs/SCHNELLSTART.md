# 🚀 SCHNELLSTART - Windows 11 Setup Tool

## In 3 Schritten zum fertigen System

### Schritt 1: Vorbereitung (2 Minuten)

1. **Alle Dateien** auf den Windows 11 PC kopieren
2. **PowerShell als Administrator** öffnen:
   - Windows-Taste drücken
   - "PowerShell" tippen
   - Rechtsklick → "Als Administrator ausführen"

### Schritt 2: System-Check (optional, 1 Minute)

```powershell
cd "Pfad\zu\den\Dateien"
.\Test-System.ps1
```

Das Skript prüft ob alles bereit ist!

### Schritt 3: Setup ausführen (5-10 Minuten)

```powershell
# Execution Policy anpassen (falls nötig)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Setup starten
.\Win11-Setup-Complete.ps1
```

Im Menü wählen:
- **Für Test**: Option [T] (nur Module 1-2)
- **Für komplettes Setup**: Option [A] (alle Module)

---

## Was wird gemacht?

### ✅ Cleanup
- Widgets weg
- Copilot weg
- OneDrive deaktiviert
- Suche weg
- Desktop sauber

### ✅ Optik
- Taskleiste links
- Dateierweiterungen sichtbar
- Keine Gruppierung
- Lockscreen weg

### ✅ Performance
- Höchstleistung aktiv
- Autostart bereinigt
- Schnellstart/Hibernate aus
- Netzwerk optimiert

---

## ⚠️ Wichtig!

- **Explorer wird neu gestartet** nach Modul 2 & 3
- **Logs werden erstellt** in `C:\CGM\Logs\`
- **Registry-Backups** in `C:\CGM\Registry-Backups\`
- **Alles ist reversibel!**

---

## 🔧 Troubleshooting Express

**Problem:** Skript startet nicht
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

**Problem:** Zugriff verweigert
→ PowerShell als **Administrator** starten!

**Problem:** Explorer friert ein
→ Task-Manager → "Windows-Explorer" beenden → Neu starten

---

## 📊 Empfohlene Reihenfolge

**Erste Verwendung:**
1. Menü [1] - Initialisierung
2. Menü [2] - Cleanup (mit Explorer-Neustart)
3. Menü [3] - Optik (mit Explorer-Neustart)
4. Menü [4] - Performance

**Danach:**
- Einfach Menü [A] für alles auf einmal

---

## 📁 Datei-Übersicht

| Datei | Zweck |
|-------|-------|
| `Win11-Setup-Complete.ps1` | **HAUPTDATEI** - Alles in einem |
| `Test-System.ps1` | System-Check vor Setup |
| `README.md` | Ausführliche Doku |
| `Module2-Cleanup.ps1` | Einzelmodul (optional) |
| `Module3-OptikErgonomie.ps1` | Einzelmodul (optional) |
| `Module4-Performance.ps1` | Einzelmodul (optional) |

**Tipp:** Nutze `Win11-Setup-Complete.ps1` - dort ist alles drin!

---

## ✨ Nach dem Setup

System-Neustart durchführen für beste Ergebnisse:
```powershell
Restart-Computer
```

**Fertig!** 🎉

Dein Windows 11 ist jetzt nach Unternehmens-Standard konfiguriert.

---

**Support:** Siehe `README.md` für Details und Troubleshooting
