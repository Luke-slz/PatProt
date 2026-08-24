# Batch 6 — Verlauf & Übergabe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Übergabe-Messwerte automatisch aus der letzten Verlaufsmessung vorausfüllen; GCS-Übergabe aus dem initialen ABCDE-Disability-Befund vorausfüllen.

**Architecture:** Zwei neue Methoden auf `EinsatzProtokoll` (ObservableObject-Klasse) implementieren die Prefill-Logik — direkt unit-testbar. Views rufen diese Methoden via `.onAppear` auf. Kein neues File, kein neues Service.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Testing (`@Test`, `#expect`), `xcodebuild test`

---

## Dateien

| Datei | Zweck |
|---|---|
| `PatProt/Models/Models.swift` | 2 neue Methoden auf `EinsatzProtokoll` |
| `PatProt/Views/AbschlussView.swift` | `.onAppear` Aufruf |
| `PatProt/Views/UebergabeBefundeView.swift` | `.onAppear` Aufruf |
| `PatProtTests/PatProtTests.swift` | 3 neue Tests |

---

## Task 1: EinsatzProtokoll — prefill-Methoden + Tests

**Files:**
- Modify: `PatProt/Models/Models.swift` (am Ende des EinsatzProtokoll-Blocks)
- Test: `PatProtTests/PatProtTests.swift`

**Context:** `EinsatzProtokoll` ist eine `ObservableObject`-Klasse (nicht Struct). Die Methoden greifen auf `@Published` Properties zu. `ABCDEStatus.unbewertet` ist ein Enum-Case. `VerlaufsMessung.blutdruckSys` ist `Int?`.

- [ ] **Step 1: Tests schreiben (failing)**

In `PatProtTests/PatProtTests.swift`, nach dem letzten `@Test`:

```swift
@Test func prefillFuelltUebergabeMesswerteAusVerlauf() {
    let p = EinsatzProtokoll()
    var m = VerlaufsMessung()
    m.blutdruckSys = 120
    m.blutdruckDia = 80
    m.puls         = 72
    m.spo2         = 98
    m.atemFrequenz = 16
    p.verlaufMessungen = [m]
    p.prefillUebergabeMesswerteAusVerlauf()
    #expect(p.uebergabeMesswerte.rrSys == "120")
    #expect(p.uebergabeMesswerte.rrDia == "80")
    #expect(p.uebergabeMesswerte.hf    == "72")
    #expect(p.uebergabeMesswerte.spo2  == "98")
    #expect(p.uebergabeMesswerte.af    == "16")
}

@Test func prefillGCSAusDisabilityWennDefault() {
    let p = EinsatzProtokoll()
    p.disability.status    = .nicht_kritisch
    p.disability.gcsAugen  = 3
    p.disability.gcsVerbal = 4
    p.disability.gcsMotor  = 5
    p.prefillGCSAusDisability()
    #expect(p.uebergabeBefunde.gcsAugen  == 3)
    #expect(p.uebergabeBefunde.gcsVerbal == 4)
    #expect(p.uebergabeBefunde.gcsMotor  == 5)
}

@Test func prefillGCSUeberschreibtNichtManuelleWerte() {
    let p = EinsatzProtokoll()
    p.disability.status     = .nicht_kritisch
    p.disability.gcsAugen   = 3
    p.uebergabeBefunde.gcsAugen = 2
    p.prefillGCSAusDisability()
    #expect(p.uebergabeBefunde.gcsAugen == 2)
}
```

- [ ] **Step 2: Tests ausführen — müssen fehlschlagen**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "FAILED|prefillFuellt|prefillGCS"
```

Erwartet: `FAILED` für alle drei neuen Tests.

- [ ] **Step 3: Methoden in EinsatzProtokoll implementieren**

In `PatProt/Models/Models.swift`, kurz vor dem letzten `}` des `EinsatzProtokoll`-Blocks (suche nach `// MARK: - SAMPLER` oder dem Ende des Class-Blocks), folgende zwei Methoden einfügen.

Um die richtige Stelle zu finden: grep nach `func reset()` oder `func archivieren()` — einfügen nach der letzten Methode.

```swift
func prefillUebergabeMesswerteAusVerlauf() {
    guard let letzte = verlaufMessungen
        .sorted(by: { $0.zeitpunkt < $1.zeitpunkt }).last else { return }
    if uebergabeMesswerte.rrSys.isEmpty, let v = letzte.blutdruckSys  { uebergabeMesswerte.rrSys = "\(v)" }
    if uebergabeMesswerte.rrDia.isEmpty, let v = letzte.blutdruckDia  { uebergabeMesswerte.rrDia = "\(v)" }
    if uebergabeMesswerte.hf.isEmpty,    let v = letzte.puls          { uebergabeMesswerte.hf    = "\(v)" }
    if uebergabeMesswerte.spo2.isEmpty,  let v = letzte.spo2          { uebergabeMesswerte.spo2  = "\(v)" }
    if uebergabeMesswerte.af.isEmpty,    let v = letzte.atemFrequenz  { uebergabeMesswerte.af    = "\(v)" }
    if uebergabeMesswerte.bz.isEmpty,    let v = letzte.blutzucker    { uebergabeMesswerte.bz    = String(format: "%.0f", v) }
    if uebergabeMesswerte.temp.isEmpty,  let v = letzte.temperatur    { uebergabeMesswerte.temp  = String(format: "%.1f", v) }
}

func prefillGCSAusDisability() {
    guard disability.status != .unbewertet else { return }
    guard uebergabeBefunde.gcsAugen  == 4,
          uebergabeBefunde.gcsVerbal == 5,
          uebergabeBefunde.gcsMotor  == 6 else { return }
    uebergabeBefunde.gcsAugen  = disability.gcsAugen
    uebergabeBefunde.gcsVerbal = disability.gcsVerbal
    uebergabeBefunde.gcsMotor  = disability.gcsMotor
}
```

- [ ] **Step 4: Tests ausführen — müssen bestehen**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED"
```

Erwartet: alle Tests `passed`, 0 `FAILED`. (Gesamt jetzt 35 Tests.)

- [ ] **Step 5: Commit**

```bash
git add PatProt/Models/Models.swift PatProtTests/PatProtTests.swift
git commit -m "feat: add prefillUebergabeMesswerteAusVerlauf and prefillGCSAusDisability to EinsatzProtokoll"
```

---

## Task 2: Views — onAppear Aufrufe

**Files:**
- Modify: `PatProt/Views/AbschlussView.swift`
- Modify: `PatProt/Views/UebergabeBefundeView.swift`

**Context:**
- `AbschlussView` hat eine Form. Die Form hat bereits `.onAppear` auf einzelnen Sections (z.B. Zeile 78 für uebergabeAn). Füge `.onAppear` auf **Form-Ebene** hinzu (direkt nach `.onAppear` des existierenden Abschnitt oder als separater Modifier an der Form).
- `UebergabeBefundeView` hat eine Form. Füge `.onAppear` hinzu, der `prefillGCSAusDisability()` aufruft. Die Form endet mit `.navigationTitle("Übergabe-Befunde")` — füge `.onAppear` direkt danach ein.

- [ ] **Step 1: AbschlussView.swift**

In `PatProt/Views/AbschlussView.swift`, finde den letzten Modifier der Form (z.B. `.navigationTitle(...)` oder ähnliches). Füge hinzu — direkt am Form-Body (nach allen Sections, vor `.navigationTitle` oder als letzter Modifier):

```swift
.onAppear { protokoll.prefillUebergabeMesswerteAusVerlauf() }
```

Falls bereits ein `.onAppear` auf Form-Ebene existiert, die neue Zeile in den bestehenden Block aufnehmen.

- [ ] **Step 2: UebergabeBefundeView.swift**

In `PatProt/Views/UebergabeBefundeView.swift`, finde `.navigationTitle("Übergabe-Befunde")` (aktuell Zeile ~280). Füge direkt dahinter ein:

```swift
.onAppear { protokoll.prefillGCSAusDisability() }
```

- [ ] **Step 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests `passed`, 0 Fehler.

- [ ] **Step 4: Commit**

```bash
git add PatProt/Views/AbschlussView.swift PatProt/Views/UebergabeBefundeView.swift
git commit -m "feat: prefill Übergabe-Messwerte from Verlauf and GCS from Disability on appear"
```
