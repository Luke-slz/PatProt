# Batch 5 — SAMPLER-Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SAMPLERBefund um Uhrzeit+Unbekannt für letztes Mahl und Schwangerschaft erweitern — in Modell, View und PDF.

**Architecture:** Alle Änderungen sind additive Bool/Date/Int-Felder in einem Codable-Struct (rückwärtskompatibel) plus reine View-Erweiterungen in SwiftUI. Kein neues File, kein neues Service.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Testing (`@Test`, `#expect`), `xcodebuild test`

---

## Dateien

| Datei | Zweck |
|---|---|
| `PatProt/Models/Models.swift` | Neue Felder in `SAMPLERBefund` |
| `PatProt/Views/SAMPLERView.swift` | L-Section erweitern; Schwangerschaft-Section hinzufügen |
| `PatProt/Services/PDFGenerator.swift` | L-Zeile mit Zeit; Schwangerschaft-Zeile |
| `PatProtTests/PatProtTests.swift` | 2 neue Unit-Tests |

---

## Task 1: Datenmodell — letztesMahlZeit, letztesMahlUnbekannt, schwangerschaft, schwangerschaftSSW

**Files:**
- Modify: `PatProt/Models/Models.swift` (lines ~505–508)
- Test: `PatProtTests/PatProtTests.swift`

- [ ] **Step 1: Tests schreiben (failing)**

In `PatProtTests/PatProtTests.swift`, nach dem letzten `@Test`:

```swift
@Test func samplerBefundHatLetztesMahlFelder() {
    let s = SAMPLERBefund()
    #expect(s.letztesMahlUnbekannt == false)
}

@Test func samplerBefundHatSchwangerschaft() {
    let s = SAMPLERBefund()
    #expect(s.schwangerschaft == false)
    #expect(s.schwangerschaftSSW == 0)
}
```

- [ ] **Step 2: Tests ausführen — müssen fehlschlagen**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "FAILED|samplerBefund"
```

Erwartet: `FAILED` für beide neuen Tests.

- [ ] **Step 3: SAMPLERBefund erweitern**

In `PatProt/Models/Models.swift`, die `SAMPLERBefund`-Struct ersetzen:

Vorher (Zeilen ~500–508):
```swift
struct SAMPLERBefund: Codable {
    var symptome = ""
    var allergien = ""
    var medikamente = ""
    var patientenVorgeschichte = ""
    var letztesMahl = ""
    var ereignis = ""
    var risikofaktoren = ""
}
```

Nachher:
```swift
struct SAMPLERBefund: Codable {
    var symptome = ""
    var allergien = ""
    var medikamente = ""
    var patientenVorgeschichte = ""
    var letztesMahl = ""
    var letztesMahlZeit: Date = Date()
    var letztesMahlUnbekannt: Bool = false
    var ereignis = ""
    var risikofaktoren = ""
    var schwangerschaft: Bool = false
    var schwangerschaftSSW: Int = 0
}
```

- [ ] **Step 4: Tests ausführen — müssen bestehen**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED"
```

Erwartet: alle Tests `passed`, 0 `FAILED`.

- [ ] **Step 5: Commit**

```bash
git add PatProt/Models/Models.swift PatProtTests/PatProtTests.swift
git commit -m "feat: add letztesMahlZeit/Unbekannt and schwangerschaft to SAMPLERBefund"
```

---

## Task 2: SAMPLERView — L-Section + Schwangerschaft

**Files:**
- Modify: `PatProt/Views/SAMPLERView.swift` (lines ~78–85 für L; nach Zeile 101 für Schwangerschaft)

**Context:** `ZeitFeld` ist bereits im Projekt vorhanden (siehe `ReanimationView` in derselben Datei) und kann direkt genutzt werden. Es nimmt `label: String` und `datum: Binding<Date>`.

- [ ] **Step 1: L-Section erweitern**

In `PatProt/Views/SAMPLERView.swift`, die L-Section (aktuell Zeilen ~78–85) ersetzen:

Vorher:
```swift
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("L — Letzte Mahlzeit").font(.subheadline.bold())
        Text("Wann und was zuletzt gegessen/getrunken").font(.caption).foregroundColor(.secondary)
        TextField("z.B. heute Morgen, Brot und Kaffee", text: $befund.letztesMahl)
        Text("→ PDF S. 1 · SAMPLER · L").font(.caption2).foregroundColor(.secondary)
    }
}
```

Nachher:
```swift
Section {
    VStack(alignment: .leading, spacing: 4) {
        Text("L — Letzte Mahlzeit").font(.subheadline.bold())
        Text("Wann und was zuletzt gegessen/getrunken").font(.caption).foregroundColor(.secondary)
        Toggle("Unbekannt", isOn: $befund.letztesMahlUnbekannt)
        if !befund.letztesMahlUnbekannt {
            ZeitFeld(label: "Uhrzeit", datum: $befund.letztesMahlZeit)
        }
        TextField("z.B. Brot und Kaffee", text: $befund.letztesMahl)
        Text("→ PDF S. 1 · SAMPLER · L").font(.caption2).foregroundColor(.secondary)
    }
}
```

- [ ] **Step 2: Schwangerschaft-Section hinzufügen**

In `PatProt/Views/SAMPLERView.swift`, nach der R-Section (nach Zeile 101, vor `}` der Form, also nach der schließenden `}` der R-Section):

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

- [ ] **Step 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests `passed`, 0 Fehler.

- [ ] **Step 4: Commit**

```bash
git add PatProt/Views/SAMPLERView.swift
git commit -m "feat: extend L-section with time/unknown, add Schwangerschaft to SAMPLERView"
```

---

## Task 3: PDFGenerator — L-Zeile mit Zeit, Schwangerschaft-Zeile

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift` (lines ~519–530)

**Context:** Die `samplerAllRows`-Konstante (Zeile ~520) enthält 7 feste Tupel. Wir ersetzen das L-Tupel und fügen ein 8. Tupel für Schwangerschaft an.

- [ ] **Step 1: samplerAllRows anpassen**

In `PatProt/Services/PDFGenerator.swift`, den `samplerAllRows`-Block (Zeilen ~519–530) ersetzen:

Vorher:
```swift
// SAMPLER — immer alle 7 Zeilen anzeigen
let samplerAllRows: [(String, String)] = [
    ("S – Symptome",       p.sampler.symptome),
    ("A – Allergien",      p.sampler.allergien),
    ("M – Medikamente",    p.medikamentFotos.isEmpty
                            ? p.sampler.medikamente
                            : "Medikamentenplan: Foto-Anhang (S. 3ff.)"),
    ("P – Vorgeschichte",  p.sampler.patientenVorgeschichte),
    ("L – Letztes Essen",  p.sampler.letztesMahl),
    ("E – Ereignis",       p.sampler.ereignis),
    ("R – Risikofaktoren", p.sampler.risikofaktoren),
]
```

Nachher:
```swift
// SAMPLER — immer alle 8 Zeilen anzeigen
let letztesMahlText: String = {
    if p.sampler.letztesMahlUnbekannt { return "Unbekannt" }
    let fmt = DateFormatter()
    fmt.dateFormat = "HH:mm"
    let zeit = fmt.string(from: p.sampler.letztesMahlZeit)
    let was = p.sampler.letztesMahl.isEmpty ? "–" : p.sampler.letztesMahl
    return "\(was) · \(zeit) Uhr"
}()
let schwangerschaftText: String = {
    guard p.sampler.schwangerschaft else { return "Nein" }
    return p.sampler.schwangerschaftSSW == 0 ? "Ja – SSW unbekannt"
                                             : "Ja – SSW \(p.sampler.schwangerschaftSSW)"
}()
let samplerAllRows: [(String, String)] = [
    ("S – Symptome",       p.sampler.symptome),
    ("A – Allergien",      p.sampler.allergien),
    ("M – Medikamente",    p.medikamentFotos.isEmpty
                            ? p.sampler.medikamente
                            : "Medikamentenplan: Foto-Anhang (S. 3ff.)"),
    ("P – Vorgeschichte",  p.sampler.patientenVorgeschichte),
    ("L – Letztes Essen",  letztesMahlText),
    ("E – Ereignis",       p.sampler.ereignis),
    ("R – Risikofaktoren", p.sampler.risikofaktoren),
    ("Schwangerschaft",    schwangerschaftText),
]
```

- [ ] **Step 2: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests `passed`, 0 Fehler.

- [ ] **Step 3: Commit**

```bash
git add PatProt/Services/PDFGenerator.swift
git commit -m "feat: enhance SAMPLER PDF with meal time and Schwangerschaft row"
```
