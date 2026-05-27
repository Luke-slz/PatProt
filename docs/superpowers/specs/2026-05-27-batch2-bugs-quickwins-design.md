# Design: Batch 2 — Bugs & Quick Wins

**Datum:** 2026-05-27
**Scope:** Archiv-Deduplikation, Übergabe Auto-Fill, Uhrzeit löschen, Notfallgeschehen-Freitext, Gewicht-Verifikation

---

## 1. Archiv-Deduplikation

### Problem
`EinsatzProtokoll.id` ist `let id = UUID()` — konstant, nie überschreibbar. `apply(from:)` restauriert alle Datenfelder aus einem archivierten `ProtokollDaten`, setzt aber `id` nicht. Wenn der Nutzer ein Protokoll aus dem Archiv lädt und erneut speichert, erzeugt `toDaten()` einen `ProtokollDaten`-Snapshot mit der aktuellen In-Memory-UUID (nicht der archivierten), was zu einem Duplikat im Archiv führt.

### Fix

**`Models/Models.swift`**

`EinsatzProtokoll`:
```swift
// vorher:
let id = UUID()

// nachher:
var id = UUID()
```

`apply(from:)` — erste Zeile ergänzen:
```swift
func apply(from d: ProtokollDaten) {
    id = d.id   // NEU
    einsatzOrt = d.einsatzOrt
    // ... Rest unverändert
}
```

### Rückwärtskompatibilität
`ProtokollDaten.id` ist bereits `var id: UUID` — kein Migrationsbedarf. Bestehende Archiveinträge behalten ihre UUID.

---

## 2. Übergabe Auto-Fill aus weitereEinsatzmittel

### Problem
`uebergabeAn` (Freitext in `AbschlussView`: „Rettungsmittel / Kennung") muss manuell befüllt werden, obwohl die übernehmenden Fahrzeuge bereits unter `einsatzOrt.weitereEinsatzmittel` in der Konfiguration eingetragen wurden.

### Fix

**`Views/AbschlussView.swift`**

In der View, die das `uebergabeAn`-Textfeld enthält, `.onAppear` ergänzen:

```swift
.onAppear {
    if protokoll.uebergabeAn.isEmpty,
       !protokoll.einsatzOrt.weitereEinsatzmittel.isEmpty {
        protokoll.uebergabeAn = protokoll.einsatzOrt.weitereEinsatzmittel
            .joined(separator: " / ")
    }
}
```

- Nur wenn `uebergabeAn` noch leer ist (kein Überschreiben manueller Eingaben)
- Feld bleibt editierbar

---

## 3. Uhrzeit löschen

### Problem
`ZeitFeld` (definiert in `EinsatzOrtView.swift`) hat einen „Jetzt"-Button, aber keine Möglichkeit, eine eingetragene Uhrzeit zu löschen (`datum = nil`).

### Fix

**`Views/EinsatzOrtView.swift`** — `ZeitFeld.body`:

Hinter dem „Jetzt"-Button einen × Button ergänzen, der nur angezeigt wird wenn `datum != nil`:

```swift
if datum != nil {
    Button {
        datum = nil
    } label: {
        Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
    }
    .buttonStyle(.plain)
}
```

Reihenfolge im HStack: `Text(label)` · `Spacer()` · Zeitanzeige · „Jetzt" · × (wenn gesetzt)

---

## 4. Notfallgeschehen-Freitext als eigener Punkt

### Problem
`NotfallgeschehenBefund` hat mehrere kontextgebundene Freitextfelder (`unfallhergangFreitext`, `unfallmechanismusFreitext`, `erstbefundVorOrt`, `verlaufsbemerkungen`), aber keinen allgemeinen Freitext für Ergänzungen, die keiner Unterkategorie zuzuordnen sind.

### Datenmodell

**`Models/Models.swift`** — `struct NotfallgeschehenBefund`:

```swift
var notfallFreitext: String = ""
```

Einfügen nach `var verlaufsbemerkungen` (letztes Feld der Struct). Optional mit Default `""` → rückwärtskompatibel.

### View

**`Views/NotfallgeschehenView.swift`** — neue Section am Ende der Form (vor `.navigationTitle`):

```swift
Section {
    TextField("Ergänzungen / Sonstiges", text: $befund.notfallFreitext, axis: .vertical)
        .lineLimit(3...6)
} header: {
    Label("Freitext", systemImage: "text.alignleft")
}
```

### PDF

**`Services/PDFGenerator.swift`** — `drawPage1`, im Notfallgeschehen-Block (nach `verlaufsbemerkungen`, vor ABCDE):

```swift
if !ng.notfallFreitext.isEmpty {
    field("Ergänzungen", ng.notfallFreitext, x:lx, y:y, w:rx-lx, h:11, lw:55)
    y += 11
}
```

---

## 5. Gewicht im PDF — Verifikation

### Status
`PDFGenerator.swift` Zeile 300–301 rendert `patientDaten.gewicht` bereits korrekt:
```swift
let gewStr = p.patientDaten.gewicht.map { String(format: "%.0f kg", $0) } ?? ""
field("Gewicht", gewStr, x:x+fw2, y:y+26, w:fw2, h:12, lw:fw2*0.5)
```

Der ursprüngliche Bug war der fehlende Bestätigen-Button im Numpad-Dezimalmodus — in dieser Session behoben (`NumpadSheet.swift`). **Keine Codeänderung nötig.**

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Models/Models.swift` | `let id` → `var id`, `id = d.id` in `apply(from:)`, `notfallFreitext` zu `NotfallgeschehenBefund` |
| `PatProt/Views/EinsatzOrtView.swift` | × Button in `ZeitFeld` |
| `PatProt/Views/AbschlussView.swift` | `.onAppear` Auto-Fill `uebergabeAn` |
| `PatProt/Views/NotfallgeschehenView.swift` | Section „Freitext" mit `notfallFreitext` |
| `PatProt/Services/PDFGenerator.swift` | `notfallFreitext` in Notfallgeschehen-Block rendern |
