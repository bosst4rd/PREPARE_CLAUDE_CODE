# Windows 11 Setup Tool v1.2
## eXpletus Edition

---

## Schnellstart

1. **ZIP entpacken** in beliebigen Ordner
2. **Rechtsklick auf START.cmd**
3. **"Als Administrator ausfuehren"** waehlen
4. Im Menue navigieren

**Wichtig:** Muss als Administrator ausgefuehrt werden!

---

## Ordnerstruktur

```
Win11-Setup-v1.2/
├── START.cmd                  ← HIER STARTEN (als Admin!)
├── scripts/
│   ├── Win11-Setup.ps1       (Hauptskript)
│   ├── Test-System.ps1       (System-Check)
│   └── Diagnose-Tool.ps1     (Diagnose)
├── images/
│   ├── Hintergrund_*.jpg     (Firmen-Wallpaper)
│   └── Logo_VP.jpg           (VP-Logo)
├── docs/
│   ├── README.md             (Diese Datei)
│   ├── SCHNELLSTART.md       (Quick-Guide)
│   └── PAKET-UEBERSICHT.md   (Alle Infos)
└── backups/
    (wird automatisch befuellt)
```

---

## Was wird gemacht?

### Modul 1: Einstieg und Initialisierung
- Admin-Pruefung
- Ordner-Erstellung (C:\CGM)
- Registry-Backups
- System-Informationen

### Modul 2: Cleanup
- Widgets entfernen (Wetter, News)
- Copilot deaktivieren
- OneDrive deaktivieren
- Suche aus Taskleiste entfernen
- Desktop bereinigen
- Unerwuenschte Drucker entfernen

### Modul 3: Optik und Ergonomie
- Taskleiste linksbuen dig
- Dateierweiterungen einblenden
- Fenster nie gruppieren
- Lockscreen deaktivieren
- Bildschirmschoner deaktivieren

### Modul 4: Performance
- Hoechstleistung aktivieren
- Autostart bereinigen
- Schnellstart/Hibernate deaktivieren
- Netzwerkadapter optimieren
- Energiesparmodus aus

---

## Menue-Optionen

Im Hauptmenue von START.cmd stehen folgende Optionen zur Verfuegung:

- **[1]** Komplett-Setup - Alle Module 1-4 automatisch
- **[2]** Einzelne Module - Gezielt einzelne Module ausfuehren
- **[3]** Test-Modus - Nur Module 1-2 zum Testen
- **[T]** System-Check - Pruefung vor dem Setup
- **[D]** Diagnose - Ueberpruefung nach dem Setup
- **[L]** Log-Dateien - Logs anzeigen/oeffnen
- **[H]** Hilfe - Dokumentation anzeigen
- **[Q]** Beenden

---

## Logs und Backups

Alle Aenderungen werden protokolliert und gesichert:

**Logs:**
- Pfad: `C:\CGM\Logs\`
- Format: `Win11-Setup-YYYYMMDD-HHMMSS.log`

**Registry-Backups:**
- Pfad: `C:\CGM\Registry-Backups\`
- Format: `Registry-Backup-*.reg`
- Wiederherstellung: Doppelklick auf .reg Datei

---

## Firmen-Wallpaper

Im Ordner `images/` befinden sich die eXpletus Hintergruende:

- **Hintergrund_eXpletus_16-9_2021.jpg** - Fuer Widescreen
- **Hintergrund_eXpletus_4-3_2021.jpg** - Fuer 4:3 Monitore
- **Logo_VP.jpg** - VP-Logo

Diese koennen manuell als Hintergrund gesetzt werden.

---

## Troubleshooting

**Problem:** "Datei nicht gefunden"
- Loesung: Alle Dateien im Ordner belassen!

**Problem:** "Zugriff verweigert"
- Loesung: Als Administrator starten!

**Problem:** "Skript kann nicht ausgefuehrt werden"
- Loesung: START.cmd nutzen (nicht direkt .ps1)

**Problem:** Aenderungen nicht sichtbar
- Loesung: Explorer neu starten oder System-Neustart

---

## Support

**eXpletus - IT-Systemhaus**

- **Web:** www.eXpletus.de
- **EMail:** Support@eXpletus.de
- **Tel.:** [0391] 561 66 31
- **Fax:** [0391] 561 63 82
- **WhatsApp:** 0391 561 66 31
- **Facebook:** fb.eXpletus.de

---

## Version

**v1.2** - eXpletus Edition
- Professionelle Ordnerstruktur
- Einzelne START.cmd mit integriertem Menue
- Firmen-Branding
- Verbesserte Fehlerbehandlung
- Module 1-4 vollstaendig implementiert

---

**Letzte Aktualisierung:** November 2024
