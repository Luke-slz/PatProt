# Batch 10 — GCS Stepper, NumpadSheet iPad, Medikamente Maximaldosis

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** GCS per Stepper bedienbar; NumpadSheet auf iPad größer; Medikamente-Einträge haben Maximaldosis.

**Architecture:** Reine View- und Model-Fixes. Task 1 (GCS) und Task 2 (NumpadSheet) sind View-only. Task 3 benötigt Model + View + PDF. Alle Tasks unabhängig.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Testing, `xcodebuild test`

---

## Dateien

| Datei | Änderung |
|---|---|
| `PatProt/Views/ABCDEDetailViews.swift` | GCSStepper + labelFor; DisabilityView Menüs ersetzen |
| `PatProt/Views/NumpadSheet.swift` | iPad-Höhe 560pt |
| `PatProt/Models/Models.swift` | `maximaldosis` in MedikamentEintrag |
| `PatProt/Views/MedikamenteView.swift` | Max. Dosis-Feld in MedikamentRow |
| `PatProt/Services/PDFGenerator.swift` | Max.Dos. in Medikamenten-Tabelle |
| `PatProtTests/PatProtTests.swift` | 1 neuer Test |

---

## Task 1: GCS Stepper verbessern

**Files:**
- Modify: `PatProt/Views/ABCDEDetailViews.swift`

**Context:**
- `GCSStepper` struct: Zeilen 698-713. Hat kein `labelFor`-Parameter.
- DisabilityView GCS-Section: Zeilen 502-550. Drei `Menu`-HStacks für Augen (1–4), Verbal (1–5), Motor (1–6).
- `labelForGCSAugen`, `labelForGCSVerbal`, `labelForGCSMotor` sind `fileprivate` in derselben Datei (Zeilen 665-696).

- [ ] **Step 1: GCSStepper struct ersetzen**

In `PatProt/Views/ABCDEDetailViews.swift`, ersetze den gesamten `GCSStepper` struct (Zeilen 698–713):

```swift
struct GCSStepper: View {
    let titel: String
    @Binding var wert: Int
    let min: Int
    let max: Int
    let labelFor: (Int) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(titel).font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Stepper(value: $wert, in: min...max) {
                    Text("\(wert)")
                        .font(.subheadline.monospacedDigit())
                        .frame(minWidth: 24, alignment: .trailing)
                }
            }
            Text(labelFor(wert))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 2)
        }
    }
}
```

- [ ] **Step 2: DisabilityView — drei Menu-HStacks durch GCSStepper ersetzen**

In `PatProt/Views/ABCDEDetailViews.swift`, in `DisabilityView`, die GCS-Section (Zeilen 502–550). Ersetze den Inhalt des inneren `VStack` (ab `Text("GCS Gesamt: \(befund.gcsGesamt)")` bis zum `padding(.vertical, 4)`) — behalte den Gesamtscore-Header, ersetze die drei HStack/Menu-Blöcke:

```swift
                VStack(alignment: .leading, spacing: 10) {
                    Text("GCS Gesamt: \(befund.gcsGesamt)")
                        .font(.headline)
                        .foregroundColor(gcsBg == .clear ? .primary : (befund.gcsGesamt >= 13 ? Color.green : (befund.gcsGesamt >= 9 ? Color.orange : Color.red)))
                        .padding(.bottom, 4)

                    GCSStepper(titel: "Augen öffnen (E)",         wert: $befund.gcsAugen,  min: 1, max: 4, labelFor: labelForGCSAugen)
                    GCSStepper(titel: "Verbale Reaktion (V)",      wert: $befund.gcsVerbal, min: 1, max: 5, labelFor: labelForGCSVerbal)
                    GCSStepper(titel: "Motorische Reaktion (M)",   wert: $befund.gcsMotor,  min: 1, max: 6, labelFor: labelForGCSMotor)
                }
                .padding(.vertical, 4)
```

- [ ] **Step 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed, 0 Fehler.

- [ ] **Step 4: Commit**

```bash
git add PatProt/Views/ABCDEDetailViews.swift
git commit -m "feat: replace GCS Menu pickers with labeled Steppers in DisabilityView"
```

---

## Task 2: NumpadSheet iPad-Größe

**Files:**
- Modify: `PatProt/Views/NumpadSheet.swift` (Zeile 205)

**Context:** `.presentationDetents([.medium])` — auf iPad zu klein.

- [ ] **Step 1: Detent anpassen**

In `PatProt/Views/NumpadSheet.swift`, Zeile 205, ersetze:

```swift
        .presentationDetents([.medium])
```

durch:

```swift
        .presentationDetents(UIDevice.current.userInterfaceIdiom == .pad ? [.height(560)] : [.medium])
```

- [ ] **Step 2: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed, 0 Fehler.

- [ ] **Step 3: Commit**

```bash
git add PatProt/Views/NumpadSheet.swift
git commit -m "fix: increase NumpadSheet height on iPad to 560pt"
```

---

## Task 3: Medikamente Maximaldosis

**Files:**
- Modify: `PatProt/Models/Models.swift`
- Modify: `PatProt/Views/MedikamenteView.swift`
- Modify: `PatProt/Services/PDFGenerator.swift`
- Test: `PatProtTests/PatProtTests.swift`

**Context:**
- `MedikamentEintrag` liegt in Models.swift Zeilen 655-671. Letztes Feld: `var zeit: Date = Date()`.
- `MedikamentRow` in MedikamenteView.swift, Zeilen 79-121. Nach der HStack-Zeile mit Dosis/Einheit/Route (Zeile 117) und vor `DatePicker` (Zeile 118) das neue Feld einfügen. Die Row ist ein `private struct` mit bestehenden `@State` vars.
- PDFGenerator Medikamenten-Tabelle: Zeilen 1088-1112. Letztes Spalten-Array-Element ist `""` (leere Spalte, 11% Breite).

- [ ] **Step 1: Test schreiben (failing)**

In `PatProtTests/PatProtTests.swift`, nach dem letzten `@Test`:

```swift
@Test func medikamentEintragHatMaximaldosis() {
    let m = MedikamentEintrag()
    #expect(m.maximaldosis == "")
}
```

- [ ] **Step 2: Test ausführen — muss FAILED sein**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "medikamentEintragHatMaximaldosis|FAILED"
```

- [ ] **Step 3: Model-Feld hinzufügen**

In `PatProt/Models/Models.swift`, nach `var zeit: Date = Date()` in `MedikamentEintrag`:

```swift
    var maximaldosis: String = ""
```

- [ ] **Step 4: MedikamentRow — Max. Dosis-Feld**

In `PatProt/Views/MedikamenteView.swift`, `MedikamentRow` (private struct, Zeilen 79-121).

1. Neue `@State`-Variable nach `@State private var zeigeDosisNumpad = false`:
```swift
    @State private var zeigeMaxDosisNumpad = false
```

2. Nach der HStack-Zeile für Dosis/Einheit/Route (die mit `DatePicker` endet bei Zeile 118), VOR dem `DatePicker`, einfügen:

```swift
            HStack(spacing: 8) {
                Text("Max. Dosis").foregroundColor(.secondary).font(.subheadline)
                Spacer()
                Text(med.maximaldosis.isEmpty ? "–" : "\(med.maximaldosis) \(med.einheit)")
                    .foregroundColor(med.maximaldosis.isEmpty ? .secondary : .primary)
                    .font(.subheadline)
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeMaxDosisNumpad = true }
                    .sheet(isPresented: $zeigeMaxDosisNumpad) {
                        NumpadSheet(mode: .decimal(label: "Max. Dosis", unit: med.einheit),
                                    initial: med.maximaldosis) { val in med.maximaldosis = val }
                    }
            }
```

- [ ] **Step 5: PDFGenerator — Max.Dos. in Medikamenten-Tabelle**

In `PatProt/Services/PDFGenerator.swift`:

Zeile 1089 (`mHdr`), ersetze:
```swift
            let mHdr = ["Medikament","Dosis","Einheit","Applikationsweg","Zeit",""]
```
durch:
```swift
            let mHdr = ["Medikament","Dosis","Einheit","Applikationsweg","Zeit","Max.Dos."]
```

Zeile 1105 (`vals2`), ersetze:
```swift
                let vals2 = [med.name, med.dosis, med.einheit, med.route, t(med.zeit), ""]
```
durch:
```swift
                let vals2 = [med.name, med.dosis, med.einheit, med.route, t(med.zeit), med.maximaldosis]
```

- [ ] **Step 6: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle 46 Tests passed, 0 Fehler.

- [ ] **Step 7: Commit**

```bash
git add PatProt/Models/Models.swift PatProt/Views/MedikamenteView.swift PatProt/Services/PDFGenerator.swift PatProtTests/PatProtTests.swift
git commit -m "feat: add Maximaldosis field to MedikamentEintrag with view and PDF support"
```
