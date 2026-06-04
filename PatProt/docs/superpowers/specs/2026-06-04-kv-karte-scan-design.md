# KV-Karten-Scan – Design

**Datum:** 2026-06-04  
**Status:** Genehmigt  

## Ziel

Die bestehende Foto-Sektion in `PatientView` (KV-Karte / Versichertenkarte) wird durch einen Karten-Scanner ersetzt. Die Kamera liest die elektronische Gesundheitskarte (eGK) aus; erkannte Daten werden sofort und ohne Bestätigungsschritt in die Patientendaten-Felder übernommen.

## Umfang

**In Scope:**
- Vorname, Nachname, Geburtsdatum, KVNR, Kostenträger (alle 5 Felder)
- Kamera-Scan via `VNDocumentCameraViewController` (VisionKit)
- Direkte Übernahme in `patientDaten` ohne Zwischenschritt
- Kurze Ergebnisanzeige unter dem Button
- Entfernung der bisherigen `MedikamentFotoSektion` aus der KV-Sektion

**Out of Scope:**
- Barcode/NFC-Auslesen (Chip der eGK)
- Speichern eines Kartenfotos
- Rückseitenerfassung (EKVK)

## Architektur

### Neue Dateien

**`Services/KVKarteParser.swift`**  
Reines Parsing – kein UI, keine SwiftUI-Importe. Nimmt `UIImage` entgegen, gibt `ParsedKVDaten` zurück.

```swift
struct ParsedKVDaten {
    var vorname: String = ""
    var nachname: String = ""
    var geburtsDatum: Date? = nil
    var versicherungsNummer: String = ""  // KVNR: 1 Buchstabe + 9 Ziffern
    var kostentraeger: String = ""
}

enum KVKarteParser {
    static func parse(_ image: UIImage) async -> ParsedKVDaten
    static func parse(lines: [String]) -> ParsedKVDaten  // testbarer Einstiegspunkt
}
```

**`Views/KVKarteScanView.swift`**  
Enthält `DocumentCameraWrapper` (UIViewControllerRepresentable für `VNDocumentCameraViewController`) und `KVKarteScanSektion` (SwiftUI-View).

### Geänderte Dateien

**`Views/PatientView.swift`**  
- `MedikamentFotoSektion(fotos: $protokoll.kvFotos)` → `KVKarteScanSektion(patientDaten: $protokoll.patientDaten)`
- Import `VisionKit` entfällt hier (liegt im neuen View)

**`Models/Models.swift`**  
- `kvFotos: [FotoEintrag]` entfernen, sofern nicht im PDF-Generator referenziert (beim Implementieren prüfen)

## Parsing-Strategie

### KVNR
Regex `\b[A-Z][0-9]{9}\b` — das Muster ist auf der eGK einzigartig.  
Beispiel: `A123456789`, `X987654321`

### Geburtsdatum
Regex `\*?\d{2}\.\d{2}\.\d{4}` — führendes `*` (Asterisk) wird abgeschnitten.  
Beispiel: `*12.07.1964` → `12.07.1964`

### Nachname
Zeilen die ausschließlich Großbuchstaben, Leerzeichen, Bindestriche und Umlaute (ÄÖÜ) enthalten und mindestens 2 Zeichen lang sind. Die eGK druckt Nachnamen in VERSALIEN.  
Fallback: Wenn eine Zeile das Format `"NACHNAME, Vorname"` hat, wird am ersten Komma aufgeteilt.

### Vorname
Zeile unmittelbar nach dem erkannten Nachnamen, sofern sie gemischte Schreibweise hat.  
Fallback: Teil rechts des Kommas aus dem Komma-Format.

### Kostenträger
Erste inhaltstragende Zeile, die kein bekanntes Karten-Label ist. Gefilterte Labels:
`"Versichertenkarte"`, `"Gesundheitskarte"`, `"Krankenversicherungskarte"`, `"Europäische Krankenversicherungskarte"`, `"European Health Insurance Card"`, `"Gültig bis"`, `"Valid until"`

## UI-Verhalten

```
┌─ KV-Karte / Versichertenkarte ─────────────────────────────┐
│                                                             │
│  [ Karte scannen ]                                          │
│                                                             │
│  ✓ Gelesen: Mustermann, Erika · *12.07.1964 · A12345…      │
│    (nur nach erfolgreichem Scan sichtbar)                   │
│                                                             │
│  Erkannte Daten werden direkt in die Felder übernommen      │
│  – nur lokal gespeichert (DSGVO).                           │
└─────────────────────────────────────────────────────────────┘
```

**Ablauf:**
1. Tap "Karte scannen" → `VNDocumentCameraViewController` als Sheet
2. Nutzer richtet Kamera auf Karte; Apple-Framework erkennt Rechteck und fotografiert automatisch
3. Sheet schließt → `KVKarteParser.parse(_:)` läuft async
4. Felder in `protokoll.patientDaten` werden direkt überschrieben
5. Statuszeile zeigt erkannte Werte (einzeilig, kompakt)
6. Wenn nichts erkannt: `"Keine Daten erkannt – bitte erneut versuchen"` in `.secondary`-Farbe

**Kein Ladeindikator** — OCR auf einem Kartenfoto dauert <1 Sekunde.

## Fehlerbehandlung

| Situation | Verhalten |
|---|---|
| Nutzer bricht Scanner ab | Nichts passiert, Felder bleiben unverändert |
| OCR liefert leeres Ergebnis | Statuszeile zeigt Hinweis "Keine Daten erkannt" |
| Einzelne Felder nicht erkannt | Erkannte Felder werden übernommen, leere bleiben leer |
| Felder bereits ausgefüllt | Werden überschrieben (kein Konfliktdialog) |

## Datenschutz

- Kein Foto der Karte wird gespeichert — das `UIImage` existiert nur im Arbeitsspeicher während des OCR-Durchlaufs
- Erkannte Daten landen ausschließlich in `protokoll.patientDaten` (lokal, `.completeFileProtection`)
- Hinweistext im Footer bleibt bestehen
