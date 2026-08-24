# Design: Batch 5 — SAMPLER überarbeiten

**Datum:** 2026-05-28
**Scope:** L-Unterpunkte mit Uhrzeit, Unbekannt-Toggle, Schwangerschaft-Feld

---

## 1. Letztes Mahl — Uhrzeit + Unbekannt

### Models.swift — SAMPLERBefund

Nach `var letztesMahl = ""` (aktuell Zeile 505):
```swift
var letztesMahlZeit: Date = Date()
var letztesMahlUnbekannt: Bool = false
```

Rückwärtskompatibel: `Bool = false` und `Date = Date()` als Defaults.

### SAMPLERView.swift — L-Section

Die aktuelle einzelne TextField-Zeile wird erweitert:
```swift
Toggle("Unbekannt", isOn: $befund.letztesMahlUnbekannt)
if !befund.letztesMahlUnbekannt {
    ZeitFeld(label: "Uhrzeit", datum: $befund.letztesMahlZeit)
}
TextField("z.B. Brot und Kaffee", text: $befund.letztesMahl)
```

Wenn `letztesMahlUnbekannt == true` wird das `ZeitFeld` ausgeblendet (nicht disabled — sauberere UX).

### PDFGenerator.swift — L-Zeile

```swift
("L – Letztes Essen", letztesMahlText),
```

Computed:
```swift
let letztesMahlText: String = {
    if p.sampler.letztesMahlUnbekannt {
        return "Unbekannt"
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    let zeit = formatter.string(from: p.sampler.letztesMahlZeit)
    let was = p.sampler.letztesMahl.isEmpty ? "–" : p.sampler.letztesMahl
    return "\(was) · \(zeit) Uhr"
}()
```

---

## 2. Schwangerschaft

### Models.swift — SAMPLERBefund

Nach `var risikofaktoren = ""`:
```swift
var schwangerschaft: Bool = false
var schwangerschaftSSW: Int = 0
```

`schwangerschaftSSW == 0` bedeutet SSW unbekannt/nicht angegeben.

### SAMPLERView.swift — neue Section nach R

```swift
Section {
    Toggle("Schwangerschaft bekannt", isOn: $befund.schwangerschaft)
    if befund.schwangerschaft {
        Stepper(befund.schwangerschaftSSW == 0 ? "SSW unbekannt"
                                               : "SSW \(befund.schwangerschaftSSW)",
                value: $befund.schwangerschaftSSW, in: 0...42)
    }
} header: { Label("Schwangerschaft", systemImage: "figure.and.child.holdinghands") }
```

### PDFGenerator.swift — Schwangerschaft-Zeile

Direkt nach der R-Zeile in `samplerAllRows`, nur wenn relevant:
```swift
("Schwangerschaft", schwangerschaftText),
```

Computed:
```swift
let schwangerschaftText: String = {
    guard p.sampler.schwangerschaft else { return "Nein" }
    return p.sampler.schwangerschaftSSW == 0 ? "Ja – SSW unbekannt"
                                             : "Ja – SSW \(p.sampler.schwangerschaftSSW)"
}()
```

Die Schwangerschaft-Zeile wird immer angezeigt (feste SAMPLER-Tabelle, kein konditionaler Auswuchs).

---

## 3. Tests

- `samplerBefundHatLetztesMahlFelder()` — `SAMPLERBefund().letztesMahlUnbekannt == false`
- `samplerBefundHatSchwangerschaft()` — `SAMPLERBefund().schwangerschaft == false`, `.schwangerschaftSSW == 0`

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Models/Models.swift` | `letztesMahlZeit`, `letztesMahlUnbekannt`, `schwangerschaft`, `schwangerschaftSSW` in `SAMPLERBefund` |
| `PatProt/Views/SAMPLERView.swift` | L-Section erweitert; Schwangerschaft-Section hinzugefügt |
| `PatProt/Services/PDFGenerator.swift` | L-Zeile mit Zeit; Schwangerschaft-Zeile |
| `PatProtTests/PatProtTests.swift` | 2 neue Tests |
