# Design: Batch 7 — UI/UX & Komplexe Features

**Datum:** 2026-05-28
**Scope:** iPad Startseite (AppStorage), PRIOR in MANV (Sichtungskategorie), Maschinelle Beatmung, Medikamenten-Rechner

> **Hinweise:**
> - **BP-Dys-Automatik** ist bereits implementiert: `rrWarn`/`rrBg` in `CirculationView` zeigen Hypotonie/Hypertonie-Warnungen per `vitalWarnText`. Kein Handlungsbedarf.
> - **Pflichtfelder-Badge** ist bereits implementiert: `iPhoneMenuView` und `iPadMainView` haben identische Badge-Berechnungen (konfigurationBadge, patientBadge, notfallBadge, befundeBadge, diagnoseBadge, verlaufBadge, moduleBadge, bilderBadge). Kein Handlungsbedarf.

---

## 1. iPad Startseite — AppStorage

### iPadMainView.swift

`iPadMainView.startScreen` zeigt aktuell hardcodierte Strings. Der iPhone-`StartView` nutzt `@AppStorage("einheitenname")` und `@AppStorage("startseiteUntertitel")`. Angleichen:

In `iPadMainView`, zwei neue `@AppStorage`-Properties hinzufügen:
```swift
@AppStorage("einheitenname") private var einheitenname: String = "First Responder Geesthacht"
@AppStorage("startseiteUntertitel") private var startseiteUntertitel: String = "Einsatzprotokollierung First Responder"
```

Im `startScreen`-Body ersetzen:
```swift
// vorher:
Text("RD Protokoll").font(.largeTitle).fontWeight(.bold)
Text("Einsatzprotokollierung Rettungsdienst").font(.subheadline).foregroundColor(.secondary)

// nachher:
Text(einheitenname.isEmpty ? "First Responder Geesthacht" : einheitenname)
    .font(.largeTitle).fontWeight(.bold).multilineTextAlignment(.center)
Text(startseiteUntertitel.isEmpty ? "Einsatzprotokollierung First Responder" : startseiteUntertitel)
    .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
```

---

## 2. PRIOR in MANV — Eigene Sichtungskategorie

### Models.swift — NotfallgeschehenBefund

Nach `var manvNachforderung: String = ""`:
```swift
var manvEigeneSK: String = ""
```

Rückwärtskompatibel (String = ""). Die Sichtungskategorien sind: "SK I", "SK II", "SK III", "SK IV", "T".

### NotfallgeschehenView.swift — DynamischeErweiterungView

Wenn `befund.manv == true`, neue Section nach dem Besonderheiten-Block:
```swift
Section {
    Picker("Eigene Sichtungskategorie", selection: $befund.manvEigeneSK) {
        Text("–").tag("")
        Text("SK I – Rot (sofort)").tag("SK I")
        Text("SK II – Gelb (aufgeschoben)").tag("SK II")
        Text("SK III – Grün (leicht verletzt)").tag("SK III")
        Text("SK IV – Blau (ohne Überlebenschance)").tag("SK IV")
        Text("T – Schwarz (verstorben)").tag("T")
    }
    .pickerStyle(.menu)
} header: { Label("Eigene Sichtungskategorie", systemImage: "tag.fill") }
```

Nur sichtbar wenn `befund.manv == true` (bestehende `if befund.manv`-Bedingung).

### PDFGenerator.swift — MANV-Zeile

In `drawPage1`, die MANV-Zeile (um Zeile 403) um die eigene SK ergänzen:
```swift
let manvSKText = ng.manvEigeneSK.isEmpty ? "" : " · \(ng.manvEigeneSK)"
// Dann in das MANV-Feldlabel integrieren:
"MANV\(ng.ersteEintreffendeKraft ? " · 1. Eintreffend" : "") · \(ng.anzahlBeteiligte) Bet.\(manvSKText)"
```

---

## 3. Maschinelle Beatmung

### Models.swift — MassnahmenBefund

Nach `var maskenbeatmungUnmoeglich: Bool = false`:
```swift
var maschinelleBeatmung:    Bool = false
var tidalvolumen:           String = ""   // ml
var peep:                   String = ""   // cmH2O
var fio2:                   String = ""   // %
var beatmungsfrequenzMasch: String = ""   // /min
```

String-Felder (wie andere Messwerte in MassnahmenBefund) für NumpadSheet-Kompatibilität.

### MassnahmenView.swift

Nach `CheckboxRow("Maskenbeatmung (BVM)", isOn: $befund.maskenbeatmung)`:
```swift
if befund.maskenbeatmung {
    CheckboxRow("Maschinelle Beatmung", isOn: $befund.maschinelleBeatmung)
    if befund.maschinelleBeatmung {
        NumpadRow(label: "Tidalvolumen (ml)",  wert: $befund.tidalvolumen,    einheit: "ml",    mode: .integer)
        NumpadRow(label: "PEEP (cmH₂O)",       wert: $befund.peep,            einheit: "cmH₂O", mode: .integer)
        NumpadRow(label: "FiO₂ (%)",           wert: $befund.fio2,            einheit: "%",     mode: .integer)
        NumpadRow(label: "AF Gerät (/min)",    wert: $befund.beatmungsfrequenzMasch, einheit: "/min", mode: .integer)
    }
}
```

> **Hinweis:** Zur `NumpadRow`-Implementierung zuerst prüfen, wie andere Numpad-Felder in `MassnahmenView.swift` strukturiert sind (z.B. die `sauerstoffLitMin`-Zeile). Dort wird inline `HStack + .onTapGesture + .sheet(NumpadSheet)` verwendet — dasselbe Muster anwenden, nicht ein nicht-existierendes `NumpadRow`-Component verwenden.

### PDFGenerator.swift — Maßnahmen-Sektion

In der Maßnahmen-Sektion (`drawPage2`), nach dem Maskenbeatmung-Eintrag, wenn `p.massnahmen.maschinelleBeatmung == true`:
```swift
if p.massnahmen.maschinelleBeatmung {
    let teile = [
        p.massnahmen.tidalvolumen.isEmpty ? nil : "TV \(p.massnahmen.tidalvolumen)ml",
        p.massnahmen.peep.isEmpty ? nil : "PEEP \(p.massnahmen.peep)cmH₂O",
        p.massnahmen.fio2.isEmpty ? nil : "FiO₂ \(p.massnahmen.fio2)%",
        p.massnahmen.beatmungsfrequenzMasch.isEmpty ? nil : "AF \(p.massnahmen.beatmungsfrequenzMasch)/min",
    ].compactMap { $0 }.joined(separator: " · ")
    // Als Feld rendern: Label "Maschinelle Beatmung", Wert = teile (oder "–")
}
```

---

## 4. Medikamenten-Rechner

### Implementierung: Neuer `MedikamentenRechnerSheet` in MedikamenteView.swift

Ein stateful Sheet ohne Modell-Speicherung — reine UI-Hilfe.

**Daten:**
```swift
private struct RechnerMed {
    let name: String
    let dosisProKg: Double?      // mg/kg (nil wenn Festdosis)
    let festDosis: Double?        // mg (nil wenn gewichtsbasiert)
    let einheit: String
    let route: String
    let max: Double?              // maximale Dosis in mg (optional)
}

private let rechnerMedikamente: [RechnerMed] = [
    RechnerMed(name: "Adrenalin (Anaphylaxie)", dosisProKg: 0.01,  festDosis: nil,   einheit: "mg", route: "i.m.", max: 0.5),
    RechnerMed(name: "Glucose 40%",              dosisProKg: nil,    festDosis: 20.0,  einheit: "g",  route: "i.v.", max: nil),
    RechnerMed(name: "ASS (ACS)",                dosisProKg: nil,    festDosis: 250.0, einheit: "mg", route: "p.o.", max: nil),
    RechnerMed(name: "Nitro (Spray)",            dosisProKg: nil,    festDosis: 0.4,   einheit: "mg", route: "s.l.", max: nil),
    RechnerMed(name: "Midazolam (Krampf)",       dosisProKg: 0.1,   festDosis: nil,   einheit: "mg", route: "nasal", max: 10.0),
]
```

**View:**
- `@State private var gewicht: String` — prefilled aus `protokoll.patientDaten.gewicht` (Gramm? kg? — Modell hat `Double?` in kg)
- `@State private var auswahl: Int = 0` — Index in rechnerMedikamente
- Zeige: berechnete Dosis, Route, ggf. "max. X mg"
- Kein Speichern — der Sanitäter überträgt das Ergebnis manuell in den Medikamenten-Eintrag

**Zugangspunkt:** Toolbar-Button "Rechner" in MedikamenteView. MedikamenteView erhält `@EnvironmentObject private var protokoll: EinsatzProtokoll` für Gewichtszugriff.

---

## 5. Tests

```swift
@Test func notfallgeschehenHatManvEigeneSK() {
    let n = NotfallgeschehenBefund()
    #expect(n.manvEigeneSK == "")
}

@Test func massnahmenHatMaschinelleBeatmungFelder() {
    let m = MassnahmenBefund()
    #expect(m.maschinelleBeatmung == false)
    #expect(m.tidalvolumen == "")
    #expect(m.peep == "")
}
```

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Models/Models.swift` | `manvEigeneSK` in `NotfallgeschehenBefund`; `maschinelleBeatmung` + Beatmungsfelder in `MassnahmenBefund` |
| `PatProt/Views/iPadMainView.swift` | AppStorage für Startseite |
| `PatProt/Views/NotfallgeschehenView.swift` | SK-Picker in DynamischeErweiterungView |
| `PatProt/Views/MassnahmenView.swift` | Maschinelle-Beatmung-UI |
| `PatProt/Views/MedikamenteView.swift` | MedikamentenRechnerSheet + Toolbar-Button |
| `PatProt/Services/PDFGenerator.swift` | MANV SK in MANV-Zeile; Maschinelle Beatmung in Maßnahmen |
| `PatProtTests/PatProtTests.swift` | 2 neue Tests |
