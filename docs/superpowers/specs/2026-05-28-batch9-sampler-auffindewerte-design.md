# Design: Batch 9 — SAMPLER L Erweiterung, SAMPLER Unbekannt, Auffindewerte

**Datum:** 2026-05-28
**Scope:** SAMPLER L (Stuhlgang + Regelblutung), SAMPLER Unbekannt für A/M/P, Auffindewerte

---

## 1. SAMPLER L — Letzter Stuhlgang + Letzte Regelblutung

### Problem
Das L in SAMPLER steht für "Letzte orale Aufnahme" — aber es gibt weitere wichtige "letzte" Ereignisse:
- **Letzter Stuhlgang** (klinisch relevant für abdominelle Symptome)
- **Letzte Regelblutung** (klinisch relevant, besonders bei Schwangerschaftsverdacht)

Aktuell existiert nur "Letzte Mahlzeit" mit Unbekannt/Uhrzeit/Freitext. Die anderen zwei fehlen.

### Fix

**Models.swift — SAMPLERBefund** (nach `letztesMahlUnbekannt`):
```swift
var letzterStuhlgang: String = ""
var letzterStuhlgangZeit: Date? = nil
var letzterStuhlgangUnbekannt: Bool = false
var letzteRegelblutung: String = ""
var letzteRegelblutungZeit: Date? = nil
var letzteRegelblutungUnbekannt: Bool = false
```

**SAMPLERView.swift** — nach der Letzte-Mahlzeit-Section, zwei neue Sections:

```swift
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("L — Letzter Stuhlgang").font(.subheadline.bold())
        Text("Wann zuletzt Stuhlgang").font(.caption).foregroundColor(.secondary)
        Toggle("Unbekannt", isOn: $befund.letzterStuhlgangUnbekannt)
            .onChange(of: befund.letzterStuhlgangUnbekannt) { _, isUnknown in
                if isUnknown { befund.letzterStuhlgangZeit = nil }
            }
        if !befund.letzterStuhlgangUnbekannt {
            ZeitFeld(label: "Uhrzeit", datum: $befund.letzterStuhlgangZeit)
        }
        TextField("Freitext", text: $befund.letzterStuhlgang)
        Text("→ PDF S. 1 · SAMPLER · L").font(.caption2).foregroundColor(.secondary)
    }
}
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("L — Letzte Regelblutung").font(.subheadline.bold())
        Text("Wann letzte Regelblutung").font(.caption).foregroundColor(.secondary)
        Toggle("Unbekannt", isOn: $befund.letzteRegelblutungUnbekannt)
            .onChange(of: befund.letzteRegelblutungUnbekannt) { _, isUnknown in
                if isUnknown { befund.letzteRegelblutungZeit = nil }
            }
        if !befund.letzteRegelblutungUnbekannt {
            ZeitFeld(label: "Uhrzeit", datum: $befund.letzteRegelblutungZeit)
        }
        TextField("Freitext", text: $befund.letzteRegelblutung)
        Text("→ PDF S. 1 · SAMPLER · L").font(.caption2).foregroundColor(.secondary)
    }
}
```

**PDFGenerator.swift** — `samplerAllRows` nach `("L – Letztes Essen", letztesMahlText)` zwei neue Rows:

```swift
let letzterStuhlgangText: String = {
    if p.sampler.letzterStuhlgangUnbekannt { return "Unbekannt" }
    let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
    let was = p.sampler.letzterStuhlgang.isEmpty ? "–" : p.sampler.letzterStuhlgang
    if let zeit = p.sampler.letzterStuhlgangZeit { return "\(was) · \(fmt.string(from: zeit)) Uhr" }
    return was
}()
let letzteRegelblutungText: String = {
    if p.sampler.letzteRegelblutungUnbekannt { return "Unbekannt" }
    let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
    let was = p.sampler.letzteRegelblutung.isEmpty ? "–" : p.sampler.letzteRegelblutung
    if let zeit = p.sampler.letzteRegelblutungZeit { return "\(was) · \(fmt.string(from: zeit)) Uhr" }
    return was
}()
```

Rows: `("L – Letzter Stuhlgang", letzterStuhlgangText)` und `("L – Letzte Regelblutung", letzteRegelblutungText)` nach `("L – Letztes Essen", letztesMahlText)`.

---

## 2. SAMPLER Unbekannt — A, M, P

### Problem
Allergien, Medikamente und Patientenvorgeschichte können häufig "Unbekannt" sein (Patient bewusstlos, keine Angehörigen). Aktuell gibt es keinen strukturierten Weg, das zu dokumentieren — man lässt das Feld leer, was mehrdeutig ist (nicht erfasst vs. tatsächlich unbekannt).

### Fix

**Models.swift — SAMPLERBefund** (neue Bool-Felder):
```swift
var allergienUnbekannt: Bool = false
var medikamenteUnbekannt: Bool = false
var patientenVorgeschichteUnbekannt: Bool = false
```

**SAMPLERView.swift** — Toggle in den jeweiligen Sections:

A – Allergien:
```swift
Toggle("Unbekannt", isOn: $befund.allergienUnbekannt)
    .onChange(of: befund.allergienUnbekannt) { _, isUnknown in
        if isUnknown { befund.allergien = "" }
    }
if !befund.allergienUnbekannt {
    TextEditor(text: $befund.allergien).frame(minHeight: 60)
}
```

M – Medikamente (Toggle vor bestehendem TextField, TextEditor entfernen wenn Unbekannt):
```swift
Toggle("Unbekannt", isOn: $befund.medikamenteUnbekannt)
    .onChange(of: befund.medikamenteUnbekannt) { _, isUnknown in
        if isUnknown { befund.medikamente = "" }
    }
if !befund.medikamenteUnbekannt {
    TextField(...) // existing
    // QR-Scanner Button bleibt
}
```

P – Patientenvorgeschichte:
```swift
Toggle("Unbekannt", isOn: $befund.patientenVorgeschichteUnbekannt)
    .onChange(of: befund.patientenVorgeschichteUnbekannt) { _, isUnknown in
        if isUnknown { befund.patientenVorgeschichte = "" }
    }
if !befund.patientenVorgeschichteUnbekannt {
    TextEditor(text: $befund.patientenVorgeschichte).frame(minHeight: 70)
}
```

**PDFGenerator.swift** — in `samplerAllRows` Werte ersetzen wenn Unbekannt:
```swift
("A – Allergien",     p.sampler.allergienUnbekannt ? "Unbekannt" : p.sampler.allergien),
("M – Medikamente",   p.sampler.medikamenteUnbekannt ? "Unbekannt" : ...),
("P – Vorgeschichte", p.sampler.patientenVorgeschichteUnbekannt ? "Unbekannt" : p.sampler.patientenVorgeschichte),
```

---

## 3. Auffindewerte

### Problem
Es gibt keine strukturierte Möglichkeit, die Vitalzeichen zum Zeitpunkt des Patientenkontakts (Auffindewerte) zu dokumentieren. Der "Aktueller Zustand" in SINNHAFT ist ein Freitext für die aktuelle Situation — die initialen Messwerte fehlen.

### Fix

**Models.swift — NotfallgeschehenBefund** (neue Felder nach `notfallFreitext`):
```swift
var auffindePuls: String = ""
var auffindeSpO2: String = ""
var auffindeRRSys: String = ""
var auffindeRRDia: String = ""
var auffindeAF: String = ""
var auffindeBewusstsein: String = ""  // AVPU oder Freitext
var auffindeFreitext: String = ""
```

**NotfallgeschehenView.swift** — neuer NavigationLink in der Hauptliste:
```swift
NavigationLink {
    AuffindewerteView(befund: $befund)
} label: {
    NfgZeile(
        titel: "Auffindewerte",
        wert: befund.auffindePuls.isEmpty && befund.auffindeSpO2.isEmpty
            ? nil
            : [befund.auffindePuls.isEmpty ? nil : "Puls \(befund.auffindePuls)",
               befund.auffindeSpO2.isEmpty ? nil : "SpO₂ \(befund.auffindeSpO2)%"]
               .compactMap { $0 }.joined(separator: " · ")
    )
}
```

**AuffindewerteView** (neue View, am Ende von NotfallgeschehenView.swift):
- Section "Messwerte": NumpadSheet-Rows für Puls, SpO₂, RR, AF
- Section "Bewusstsein": TextField (AVPU oder Freitext, z.B. "A", "V", "P", "U")
- Section "Freitext": TextField multiline für ergänzende Notizen

**NumpadSheet-Pattern** (wie in anderen Views):
```swift
// Puls-Feld:
@State private var zeigePulsNumpad = false

HStack {
    Text("Puls (/min)").foregroundStyle(.secondary)
    Spacer()
    Text(befund.auffindePuls.isEmpty ? "–" : "\(befund.auffindePuls) /min")
        .foregroundStyle(befund.auffindePuls.isEmpty ? .tertiary : .primary)
}
.contentShape(Rectangle())
.onTapGesture { zeigePulsNumpad = true }
.sheet(isPresented: $zeigePulsNumpad) {
    NumpadSheet(mode: .integer(label: "Puls", unit: "/min", maxDigits: 3),
                initial: befund.auffindePuls) { val in befund.auffindePuls = val }
}
```

Gleiches Muster für SpO₂ (%), AF (/min). RR verwendet `.bloodPressure`-Modus:
```swift
@State private var zeigeRRNumpad = false

HStack {
    Text("RR (mmHg)").foregroundStyle(.secondary)
    Spacer()
    let rrText = befund.auffindeRRSys.isEmpty ? "–" : "\(befund.auffindeRRSys)/\(befund.auffindeRRDia)"
    Text(rrText).foregroundStyle(befund.auffindeRRSys.isEmpty ? .tertiary : .primary)
}
.contentShape(Rectangle())
.onTapGesture { zeigeRRNumpad = true }
.sheet(isPresented: $zeigeRRNumpad) {
    NumpadSheet(mode: .bloodPressure,
                initial: befund.auffindeRRSys.isEmpty ? "" : "\(befund.auffindeRRSys)/\(befund.auffindeRRDia)") { val in
        let parts = val.split(separator: "/")
        if parts.count == 2 {
            befund.auffindeRRSys = String(parts[0])
            befund.auffindeRRDia = String(parts[1])
        }
    }
}
```

**PDFGenerator.swift** — kompakter Auffindewerte-Block nach den ABCDE-Zeilen (oder als Teil von Section 2):

```swift
// Auffindewerte — nur wenn mindestens ein Feld gesetzt
let hatAuffindewerte = !p.notfallGeschehen.auffindePuls.isEmpty
    || !p.notfallGeschehen.auffindeSpO2.isEmpty
    || !p.notfallGeschehen.auffindeRRSys.isEmpty
if hatAuffindewerte || !p.notfallGeschehen.auffindeBewusstsein.isEmpty {
    let werte = [
        p.notfallGeschehen.auffindePuls.isEmpty ? nil : "Puls \(p.notfallGeschehen.auffindePuls)",
        p.notfallGeschehen.auffindeSpO2.isEmpty ? nil : "SpO₂ \(p.notfallGeschehen.auffindeSpO2)%",
        p.notfallGeschehen.auffindeRRSys.isEmpty ? nil : "RR \(p.notfallGeschehen.auffindeRRSys)/\(p.notfallGeschehen.auffindeRRDia)",
        p.notfallGeschehen.auffindeAF.isEmpty ? nil : "AF \(p.notfallGeschehen.auffindeAF)/min",
        p.notfallGeschehen.auffindeBewusstsein.isEmpty ? nil : "Bew. \(p.notfallGeschehen.auffindeBewusstsein)",
    ].compactMap { $0 }.joined(separator: " · ")
    field("Auffindewerte", werte, x:lx, y:y, w:rx-lx, h:11, lw:70)
    y += 11
}
```

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Models/Models.swift` | +6 L-Felder + 3 Unbekannt-Felder in SAMPLERBefund; +7 Auffindewerte-Felder in NotfallgeschehenBefund |
| `PatProt/Views/SAMPLERView.swift` | 2 neue L-Sections + Unbekannt-Toggles für A/M/P |
| `PatProt/Views/NotfallgeschehenView.swift` | NavigationLink "Auffindewerte" + neue AuffindewerteView |
| `PatProt/Services/PDFGenerator.swift` | +2 SAMPLER-Rows + Unbekannt in A/M/P + Auffindewerte-Zeile |
| `PatProtTests/PatProtTests.swift` | Tests für neue Model-Felder |

## Tests

```swift
@Test func samplerBefundHatStuhlgangUndRegelblutung() {
    let s = SAMPLERBefund()
    #expect(s.letzterStuhlgang == "")
    #expect(s.letzterStuhlgangUnbekannt == false)
    #expect(s.letzteRegelblutung == "")
    #expect(s.letzteRegelblutungUnbekannt == false)
}

@Test func samplerBefundHatUnbekanntFelder() {
    let s = SAMPLERBefund()
    #expect(s.allergienUnbekannt == false)
    #expect(s.medikamenteUnbekannt == false)
    #expect(s.patientenVorgeschichteUnbekannt == false)
}

@Test func notfallgeschehenHatAuffindewerte() {
    let n = NotfallgeschehenBefund()
    #expect(n.auffindePuls == "")
    #expect(n.auffindeSpO2 == "")
    #expect(n.auffindeRRSys == "")
}
```
