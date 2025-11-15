# Modules Ordner

Dieser Ordner enthält Erweiterungsmodule für das PowerShell GUI Tool.

## 📦 Vorhandene Module

### Example.ps1
Beispiel-Modul, das demonstriert wie eigene Module erstellt werden können.

**Enthaltene Funktionen:**
- `Get-SystemInformation` - Sammelt System-Informationen
- `Test-NetworkConnectivity` - Testet Netzwerk-Verbindungen
- `Get-DirectorySize` - Berechnet Ordnergröße
- `ConvertTo-JsonFormatted` - Formatiert JSON-Ausgabe
- `Invoke-CommandWithRetry` - Führt Befehle mit Retry-Logik aus

## 🔧 Eigene Module erstellen

### Schritt 1: Neue Datei erstellen
Erstellen Sie eine neue `.ps1`-Datei in diesem Ordner:
```
Modules/MeinModul.ps1
```

### Schritt 2: Funktionen definieren
```powershell
function Get-MeineInformation {
    <#
    .SYNOPSIS
        Beschreibung der Funktion
    .DESCRIPTION
        Detaillierte Beschreibung
    .EXAMPLE
        Get-MeineInformation
    #>
    [CmdletBinding()]
    param()

    # Ihre Logik hier
    return "Ergebnis"
}
```

### Schritt 3: In Main.ps1 einbinden

Öffnen Sie `Scripts/Main.ps1` und fügen Sie nach den anderen Imports hinzu:

```powershell
# Import modules
. (Join-Path $projectRoot "Config\Settings.ps1")
. (Join-Path $projectRoot "Functions\Core.ps1")
. (Join-Path $projectRoot "Functions\Helpers.ps1")
. (Join-Path $projectRoot "Modules\MeinModul.ps1")  # <-- NEU
```

### Schritt 4: Im Event Handler verwenden

```powershell
$startButton.Add_Click({
    try {
        # Ihre Modul-Funktion aufrufen
        $result = Get-MeineInformation

        Write-Activity -RichTextBox $activityLog -Message "Ergebnis: $result" -Level Info
    }
    catch {
        Write-Activity -RichTextBox $activityLog -Message "Fehler: $_" -Level Error
    }
})
```

## 📝 Best Practices

1. **Naming Convention**: Verwenden Sie `Verb-Noun` für Funktionsnamen
2. **Kommentare**: Nutzen Sie XML-Dokumentation (`<#..#>`)
3. **Error Handling**: Implementieren Sie Try-Catch Blöcke
4. **Parameter Validation**: Verwenden Sie `[Parameter]` Attribute
5. **Return Values**: Geben Sie strukturierte Objekte zurück

## 📚 Beispiel-Integration

Siehe `Example.ps1` für vollständige Beispiele und Integration-Anleitungen.

## ⚠️ Wichtige Hinweise

- **Kein Export-ModuleMember**: Bei Dot-Sourcing nicht verwenden!
- **UTF-8 Encoding**: Speichern Sie Dateien immer als UTF-8
- **Error Logging**: Nutzen Sie `Write-ErrorLog` für Fehler
- **Activity Log**: Verwenden Sie `Write-Activity` für Benutzer-Feedback

## 🎯 Module für das GUI Tool

Wenn Sie Funktionen im GUI Tool verwenden möchten:

```powershell
# Im Start-Button Event Handler
$startButton.Add_Click({
    $targetPath = $targetPathTextBox.Text

    # Ihre Modul-Funktion nutzen
    $info = Get-SystemInformation
    Write-Activity -RichTextBox $activityLog -Message "Computer: $($info.ComputerName)" -Level Info

    # Ordnergröße berechnen
    $size = Get-DirectorySize -Path $targetPath
    Write-Activity -RichTextBox $activityLog -Message "Größe: $($size.TotalSizeMB) MB" -Level Info
})
```

## 📂 Speicherort

```
PREPARE_CLAUDE_CODE/
└── Modules/
    ├── README.md        # Diese Datei
    ├── Example.ps1      # Beispiel-Modul
    └── <Ihr Modul>.ps1  # Ihre eigenen Module
```

---

**Tipp**: Kopieren Sie `Example.ps1` als Vorlage für Ihre eigenen Module!
