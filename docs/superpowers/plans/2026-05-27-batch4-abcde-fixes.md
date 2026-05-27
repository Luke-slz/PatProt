# Batch 4 — ABCDE-Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vier gezielte Korrekturen an den ABCDE-Befundviews: Brodeln in B hinzufügen, EKG-Abschnitte nur bei abgeleitetem EKG anzeigen, Rekapillarisierung in die Kreislauf-Section verschieben, Guedel/Wendl-Tubus in Maßnahmen ergänzen.

**Architecture:** Alle Änderungen sind Erweiterungen bestehender Codable-Structs (rückwärtskompatibel) sowie rein visuelle Umstrukturierungen in SwiftUI-Views. Kein neues File, kein neues Service.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Testing (`@Test`, `#expect`), `xcodebuild test`

---

## Dateien

| Datei | Zweck |
|---|---|
| `PatProt/Models/Models.swift` | Neue Bool-Felder in `BreathingBefund`, `UebergabeBefunde`, `MassnahmenBefund` |
| `PatProt/Views/ABCDEDetailViews.swift` | Brodeln-Checkbox in B; EKG-Gate; Rekap. verschieben |
| `PatProt/Views/UebergabeBefundeView.swift` | Brodeln-DualCheckRow in A+B-Section |
| `PatProt/Views/MassnahmenView.swift` | Guedel + Wendl Checkboxen |
| `PatProt/Services/PDFGenerator.swift` | Brodeln in `abItems`; Guedel+Wendl in `maItems1` |
| `PatProtTests/PatProtTests.swift` | 2 neue Unit-Tests |

---

## Task 1: Datenmodell — brodeln, guedelTubus, wendlTubus

**Files:**
- Modify: `PatProt/Models/Models.swift` (lines ~278, ~431, ~642)
- Test: `PatProtTests/PatProtTests.swift`

- [ ] **Step 1: Tests schreiben (failing)**

In `PatProtTests/PatProtTests.swift`, nach dem letzten `@Test`:

```swift
@Test func breathingBefundHatBrodeln() {
    let b = BreathingBefund()
    #expect(b.brodeln == false)
}

@Test func massnahmenHatGuedelWendl() {
    let m = MassnahmenBefund()
    #expect(m.guedelTubus == false)
    #expect(m.wendlTubus  == false)
}
```

- [ ] **Step 2: Tests ausführen — müssen fehlschlagen**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "FAILED|breathingBefundHat|massnahmenHat"
```

Erwartet: `FAILED` für beide neuen Tests.

- [ ] **Step 3: BreathingBefund erweitern**

In `PatProt/Models/Models.swift`, nach Zeile 278 (`var rasselgeraeusche: Bool = false`):

```swift
var brodeln:            Bool = false
```

- [ ] **Step 4: UebergabeBefunde erweitern**

In `PatProt/Models/Models.swift`, nach Zeile 431 (`var rasselgeraeusche: Bool = false` in UebergabeBefunde):

```swift
var brodeln:            Bool = false
```

- [ ] **Step 5: MassnahmenBefund erweitern**

In `PatProt/Models/Models.swift`, nach Zeile 642 (`var absaugung: Bool = false`):

```swift
var guedelTubus: Bool = false
var wendlTubus:  Bool = false
```

- [ ] **Step 6: Tests ausführen — müssen bestehen**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED"
```

Erwartet: alle Tests `passed`, 0 `FAILED`.

- [ ] **Step 7: Commit**

```bash
git add PatProt/Models/Models.swift PatProtTests/PatProtTests.swift
git commit -m "feat: add brodeln, guedelTubus, wendlTubus to models"
```

---

## Task 2: BreathingView + UebergabeBefundeView + PDF — Brodeln

**Files:**
- Modify: `PatProt/Views/ABCDEDetailViews.swift` (line ~250)
- Modify: `PatProt/Views/UebergabeBefundeView.swift` (line ~64)
- Modify: `PatProt/Services/PDFGenerator.swift` (line ~606)

**Context:** Alle drei Stellen betreffen denselben klinischen Befund „Brodeln" auf drei Ebenen: Erfassung (BreathingView), Übergabe (UebergabeBefundeView), PDF (PDFGenerator). Ignoriere SourceKit-Warnungen wie `No such module 'UIKit'` — diese sind macOS-False-Positives; nur `xcodebuild`-Output zählt.

- [ ] **Step 1: Checkbox in BreathingView**

In `PatProt/Views/ABCDEDetailViews.swift`, nach `CheckboxRow("Rasselgeräusche", isOn: $befund.rasselgeraeusche)` (aktuell Zeile 250):

```swift
CheckboxRow("Brodeln",           isOn: $befund.brodeln)
```

Die Section sieht danach so aus:
```swift
Section {
    CheckboxRow("Spastik",           isOn: $befund.spastik)
    CheckboxRow("Rasselgeräusche",   isOn: $befund.rasselgeraeusche)
    CheckboxRow("Brodeln",           isOn: $befund.brodeln)
    CheckboxRow("Stridor",           isOn: $befund.stridor)
    CheckboxRow("Schnappatmung",     isOn: $befund.schnappatmung)
    CheckboxRow("Apnoe",             isOn: $befund.apnoe)
    CheckboxRow("Hyperventilation",  isOn: $befund.hyperventilation)
    CheckboxRow("Nicht beurteilbar", isOn: $befund.abNichtBeurteilbar)
} header: { Label("Atemstörungen", systemImage: "wind") }
```

- [ ] **Step 2: DualCheckRow in UebergabeBefundeView**

In `PatProt/Views/UebergabeBefundeView.swift`, nach der Rasselgeräusche-Zeile (aktuell ab Zeile 64):

```swift
DualCheckRow(label: "Brodeln",
             ankunft: protokoll.breathing.brodeln,
             uebergabe: $protokoll.uebergabeBefunde.brodeln)
```

Vollständiger Kontext danach:
```swift
DualCheckRow(label: "Rasselgeräusche",
             ankunft: protokoll.breathing.rasselgeraeusche,
             uebergabe: $protokoll.uebergabeBefunde.rasselgeraeusche)
DualCheckRow(label: "Brodeln",
             ankunft: protokoll.breathing.brodeln,
             uebergabe: $protokoll.uebergabeBefunde.brodeln)
DualCheckRow(label: "Stridor",
             ankunft: protokoll.breathing.stridor,
             uebergabe: $protokoll.uebergabeBefunde.stridor)
```

- [ ] **Step 3: abItems in PDFGenerator erweitern**

In `PatProt/Services/PDFGenerator.swift`, nach `("Rasselger.", p.breathing.rasselgeraeusche, ub.rasselgeraeusche),` (aktuell Zeile 606):

```swift
("Brodeln",      p.breathing.brodeln,        ub.brodeln),
```

- [ ] **Step 4: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests `passed`, 0 Fehler.

- [ ] **Step 5: Commit**

```bash
git add PatProt/Views/ABCDEDetailViews.swift PatProt/Views/UebergabeBefundeView.swift PatProt/Services/PDFGenerator.swift
git commit -m "feat: add Brodeln to BreathingView, UebergabeBefundeView, PDF"
```

---

## Task 3: CirculationView — EKG gaten + Rekapillarisierung verschieben

**Files:**
- Modify: `PatProt/Views/ABCDEDetailViews.swift` (lines ~402–429)

**Context:** In `CirculationView` (Datei `ABCDEDetailViews.swift`, MARK: `- C: Circulation`):
- Die Section "EKG-Rhythmus" (lines 409–422) und "Extrasystolen" (lines 424–429) müssen in `if befund.ekg { … }` eingebettet werden.
- `CheckboxRow("Rekap. > 2 Sek.", isOn: $befund.rekapillierung)` (Zeile 420) muss aus der EKG-Rhythmus-Section **heraus** und in die Kreislauf-Section (header "Kreislauf", endet mit `} header: { Label("Kreislauf", systemImage: "heart.fill") }` bei Zeile 400).

Kein Modell-Change nötig.

- [ ] **Step 1: Rekap.-Checkbox aus EKG-Rhythmus entfernen und in Kreislauf einfügen**

Der aktuelle Kreislauf-Section-Abschluss in `ABCDEDetailViews.swift` (Zeile ~400):
```swift
            Toggle("Pulslosigkeit / Kreislaufstillstand", isOn: $befund.pulslosigkeit)
        } header: { Label("Kreislauf", systemImage: "heart.fill") }
```

Ändern zu:
```swift
            Toggle("Pulslosigkeit / Kreislaufstillstand", isOn: $befund.pulslosigkeit)
            CheckboxRow("Rekap. > 2 Sek.", isOn: $befund.rekapillierung)
        } header: { Label("Kreislauf", systemImage: "heart.fill") }
```

Gleichzeitig: In der EKG-Rhythmus-Section (Zeile ~420) die Zeile
```swift
CheckboxRow("Rekap. > 2 Sek.",          isOn: $befund.rekapillierung)
```
**löschen**.

- [ ] **Step 2: EKG-Rhythmus und Extrasystolen hinter `if befund.ekg` gaten**

Die komplette EKG-Rhythmus-Section und die Extrasystolen-Section werden in ein `if befund.ekg { }` eingebettet. Der relevante Block nach der EKG-Section sieht danach so aus:

```swift
        Section {
            Toggle("EKG abgeleitet", isOn: $befund.ekg)
            if befund.ekg {
                TextField("EKG-Befund", text: $befund.ekgBefund)
            }
        } header: { Label("EKG", systemImage: "waveform.path.ecg") }

        if befund.ekg {
            Section {
                CheckboxRow("Sinusrhythmus",            isOn: $befund.sinusrhythmus)
                CheckboxRow("Absolute Arrhythmie",      isOn: $befund.absoluteArrhythmie)
                CheckboxRow("AV-Block II°/III°",        isOn: $befund.avBlock)
                CheckboxRow("QRS-Tachykardie breit",    isOn: $befund.qrsTachykardieBreit)
                CheckboxRow("QRS-Tachykardie schmal",   isOn: $befund.qrsTachykardieSchmal)
                CheckboxRow("Kammerflattern/-flimmern", isOn: $befund.kammerflattern)
                CheckboxRow("Pulslose elektr. Akt.",    isOn: $befund.pea)
                CheckboxRow("Asystolie",                isOn: $befund.asystolie)
                CheckboxRow("Schrittmacherrhythmus",    isOn: $befund.schrittmacher)
                CheckboxRow("Infarkt-EKG (STEMI/LSB)", isOn: $befund.infarktEkg)
                CheckboxRow("Nicht beurteilbar",        isOn: $befund.cNichtBeurteilbar)
            } header: { Label("EKG-Rhythmus", systemImage: "waveform") }

            Section {
                CheckboxRow("SVES",      isOn: $befund.sves)
                CheckboxRow("VES",       isOn: $befund.ves)
                CheckboxRow("Monomorph", isOn: $befund.extrasystolenMonomorph)
                CheckboxRow("Polymorph", isOn: $befund.extrasystolenPolymorph)
            } header: { Text("Extrasystolen") }
        }
```

- [ ] **Step 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests `passed`, 0 Fehler.

- [ ] **Step 4: Commit**

```bash
git add PatProt/Views/ABCDEDetailViews.swift
git commit -m "fix: gate EKG sections behind ekgAbgeleitet, move Rekap to Kreislauf"
```

---

## Task 4: MassnahmenView + PDFGenerator — Guedel/Wendl-Tubus

**Files:**
- Modify: `PatProt/Views/MassnahmenView.swift` (line ~21)
- Modify: `PatProt/Services/PDFGenerator.swift` (line ~1090)

**Context:** `MassnahmenBefund.guedelTubus` und `wendlTubus` wurden in Task 1 hinzugefügt. Jetzt UI und PDF verdrahten.

- [ ] **Step 1: Checkboxen in MassnahmenView**

In `PatProt/Views/MassnahmenView.swift`, nach `CheckboxRow("Absaugung", isOn: $befund.absaugung)` (Zeile 21):

```swift
CheckboxRow("Guedel-Tubus (OPA)", isOn: $befund.guedelTubus)
CheckboxRow("Wendl-Tubus (NPA)",  isOn: $befund.wendlTubus)
```

- [ ] **Step 2: maItems1 in PDFGenerator erweitern**

In `PatProt/Services/PDFGenerator.swift`, nach `("Absaugung", p.massnahmen.absaugung),` (Zeile 1090):

```swift
("Guedel-Tubus (OPA)", p.massnahmen.guedelTubus),
("Wendl-Tubus (NPA)",  p.massnahmen.wendlTubus),
```

- [ ] **Step 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests `passed`, 0 Fehler.

- [ ] **Step 4: Commit**

```bash
git add PatProt/Views/MassnahmenView.swift PatProt/Services/PDFGenerator.swift
git commit -m "feat: add Guedel/Wendl-Tubus to MassnahmenView and PDF"
```
