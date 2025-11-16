Radikale Strukturänderung:
- wesentlich weniger Auswahlmöglichkeiten
- Unterscheidung feste/optionale Vorgänge
- Fusion von Modulen, grobere Aufteilung
- bislang war ein Startmodul 1 vorhanden ohne weiteren Sinn, hier wurde Programmlogik mit Menüstruktur verbunden, das ist unangebracht! Auch wenn intern ein "Startmodul.ps1" oder ähnliches verwendet wird
- noch dazu: jeglichen task, der kein feature ist (zb. Explorer Neustart) entferne ich aus dieser Liste, d.h. nicht dass er aus de
- die prüfungen zu beginn
Deine Aufgabe:
- Extrahiere den reinen Prozesscode zu den jeweiligen Tasks und ordne sie nach der neuen Struktur an
- Der Aufbau des Skripts mit den ganzen Aufgaben soll intern modular und klar sein, wie du die tasks zu welchen modulen hinzufügst / neu erstellst überlasse ich dir. im Frontend gibt es nur noch das Hautpmodul ("eXpletus-Standard"),und halt die optionalen Dinge
- das hauptmodul unterteile ich nur hier (nicht im Frontend!!!) in rubriken, der besseren übersicht halber
- 



Start wird silent durchgeführt und nur bei negativen Rückmeldungen / Error gibt es einen Hinweis:
- [ ] Admin-Check
 - [ ] Log-System (C:\CGM\Logs)
 - [ ] Registry-Backup


 ##### **==Hautpmodul *FEST***==


###### - [ ]  Cleanup/Ergonomie/Bloatware  
 - [ ] Widgets aus (Wetter, Desktop-Switch, Suche, News)
 - [ ] Copilot entfernen
 - [ ] OneDrive Sync aus
 - [ ] OneDrive deaktivieren
 - [ ] Pins löschen (MS Store, Outlook, Office, Edge)
 - [ ] Desktop-Verknüpfungen lt. Vorgabe
 - [ ]  Taskleiste links
 - [ ] Geräte entfernen (Fax, XPS)
 - [ ]  C: → "SYSTEM"
###### - [ ]Energie/Performance /Funktionalität
 - [ ] Autostart bereinigen
 - [ ] Höchstleistung Energie-Plan
 - [ ] Hibernate aus
 - [ ] Monitor/Disk nie aus
 - [ ] Netzwerkadapter Energiespar aus
 - [ ] Zwischenablage-Historie an
 - [ ] NumLock on Boot
 - [ ] UAC aus
 - [ ] Laufwerke → X,Y,Z (USB/CD)
 - [ ] C: → "SYSTEM"
 - [ ] Standarddrucker User-Kontrolle

###### - [ ] Software
 - [ ] C:\CGM Ordner
 - [ ] Chocolatey Install:
 - [ ] 7-Zip
 - [ ] Firefox
 - [ ] Chrome
 - [ ] Acrobat 
 - [ ] Lan Messenger
 - [ ] PC Visit RemoteHost
 - [ ] Fernwartung: TeamViewer QS
 - [ ] Fernwartung: PC Visit
 - [ ] Fernwartung: CGM Support
(für alle Fernwartungen Desktop-Verknüpfung mit den bekannten Bezeichnungen anlegen)

###### - [ ]  Komponenten (immer die aktuellste Version) 
 - [ ] Java
 - [ ] .NET Runtime
 - [ ] VC Redist


###### - [ ]  ALBIS
 - [ ] EPSON LQ-400 Treiber (neue Version)
 - [ ] C:\GDT Ordner
 - [ ] C:\CGM\ALBISWIN Ordner
 

 ==SIDEMODUL *OPTIONAL==
 SOFTWARE (per Chocolatey)
 - [ ] Office Home&Business (immer die aktuellste Version)