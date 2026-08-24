# Batch 11 — Qualifikation, SINNHAFT Medikamente, Vitaltrendanzeige

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ProtokollVerfasser unterstützt 6 Qualifikationsstufen; SINNHAFT-Autoausfüllung enthält administrierte Medikamente; AbschlussView zeigt Vitaltrendanzeige.

**Architecture:** Reine Model- und View-Fixes. Task 1 berührt Models + PDF. Task 2 ist Model-only. Task 3 ist View-only. Alle Tasks unabhängig.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Testing, `xcodebuild test`

---

## Dateien

| Datei | Änderung |
|---|---|
| `PatProt/Models/Models.swift` | `ProtokollVerfasser` +4 Cases; `autoFilled` Medikamente-Schleife |
| `PatProt/Views/AbschlussView.swift` | Picker `.menu`; neue Vitaltrendanzeige-Section |
| `PatProt/Services/PDFGenerator.swift` | 6 Verfasser-Checkboxen statt 2 |
| `PatProtTests/PatProtTests.swift` | 2 neue Tests |

---

## Task 1: ProtokollVerfasser Qualifikation erweitern

**Files:**
- Modify: `PatProt/Models/Models.swift` (Zeilen 93–96)
- Modify: `PatProt/Views/AbschlussView.swift` (Zeile ~52)
- Modify: `PatProt/Services/PDFGenerator.swift` (Zeilen 385–386)
- Test: `PatProtTests/PatProtTests.swift`

**Context:**
- `ProtokollVerfasser` liegt in Models.swift Zeilen 93–96. Aktuell: 2 Cases (`notfallsanitaeter = "Notfallsanitäter"`, `rettungssanitaeter = "Rettungssanitäter"`).
- AbschlussView.swift Zeilen 48–53: `Picker("Verfasser", ...) .pickerStyle(.segmented)` — muss zu `.menu` werden wegen 6 Items.
- PDFGenerator.swift Zeilen 385–386: `cb("Notfallsanitäter", ...)` und `cb("Rettungssanitäter", ...)` müssen durch 6 Checkboxen ersetzt werden.
- Die `cb()` Funktion hat Signatur `cb(_ label: String, _ checked: Bool, x: CGFloat, y: CGFloat, bs: CGFloat, lw: CGFloat)`.

- [ ] **Step 1: Tests schreiben (failing)**

In `PatProtTests/PatProtTests.swift`, nach dem letzten `@Test`:

```swift
@Test func protokollVerfasserHatSechsFaelle() {
    #expect(ProtokollVerfasser.allCases.count == 6)
    #expect(ProtokollVerfasser.notfallsanitaeter.rawValue == "Notfallsanitäter")
    #expect(ProtokollVerfasser.rettungssanitaeter.rawValue == "Rettungssanitäter")
}
```

- [ ] **Step 2: Test ausführen — muss FAILED sein**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "protokollVerfasserHatSechsFaelle|FAILED"
```

- [ ] **Step 3: ProtokollVerfasser erweitern**

In `PatProt/Models/Models.swift`, ersetze den `ProtokollVerfasser` enum (Zeilen 93–96):

```swift
enum ProtokollVerfasser: String, Codable, CaseIterable {
    case ersthelfer         = "Ersthelfer"
    case ersthelferE        = "Ersthelfer (E)"
    case rettungssanitaeter = "Rettungssanitäter"
    case rettungsassistent  = "Rettungsassistent"
    case notfallsanitaeter  = "Notfallsanitäter"
    case arzt               = "Arzt"
}
```

- [ ] **Step 4: AbschlussView Picker-Style ändern**

In `PatProt/Views/AbschlussView.swift`, ersetze `.pickerStyle(.segmented)` im Verfasser-Picker durch:

```swift
.pickerStyle(.menu)
```

- [ ] **Step 5: PDFGenerator — 6 Verfasser-Checkboxen**

In `PatProt/Services/PDFGenerator.swift`, ersetze Zeilen 385–386:

```swift
            cb("Notfallsanitäter", p.verfasser == .notfallsanitaeter, x:x+3, y:titleY+19, bs:7, lw:80)
            cb("Rettungssanitäter", p.verfasser == .rettungssanitaeter, x:x+95, y:titleY+19, bs:7, lw:80)
```

durch:

```swift
            cb("EH",     p.verfasser == .ersthelfer,          x:x+3,   y:titleY+19, bs:7, lw:28)
            cb("EH-E",   p.verfasser == .ersthelferE,         x:x+45,  y:titleY+19, bs:7, lw:33)
            cb("RS",     p.verfasser == .rettungssanitaeter,  x:x+95,  y:titleY+19, bs:7, lw:22)
            cb("RA",     p.verfasser == .rettungsassistent,   x:x+3,   y:titleY+28, bs:7, lw:22)
            cb("NotSan", p.verfasser == .notfallsanitaeter,   x:x+45,  y:titleY+28, bs:7, lw:40)
            cb("Arzt",   p.verfasser == .arzt,                x:x+95,  y:titleY+28, bs:7, lw:25)
```

- [ ] **Step 6: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed, 0 Fehler.

- [ ] **Step 7: Commit**

```bash
git add PatProt/Models/Models.swift PatProt/Views/AbschlussView.swift PatProt/Services/PDFGenerator.swift PatProtTests/PatProtTests.swift
git commit -m "feat: extend ProtokollVerfasser to 6 qualification levels"
```

---

## Task 2: SINNHAFT N2 — Medikamente in autoFilled

**Files:**
- Modify: `PatProt/Models/Models.swift`
- Test: `PatProtTests/PatProtTests.swift`

**Context:**
- `SINNHAFTBefund.autoFilled(from:)` liegt in Models.swift ab Zeile 1050.
- Die Variable `massnahmenList: [String]` wird befüllt (Zeilen 1075–1104) und dann Zeile 1105 zugewiesen: `befund.notwendigeMassnahmen = massnahmenList.joined(separator: "\n")`.
- `protokoll.medikamente: [MedikamentEintrag]` ist in EinsatzProtokoll Zeile 141. `MedikamentEintrag` hat Felder: `name: String`, `dosis: String`, `einheit: String`, `route: String`, `zeit: Date`, `maximaldosis: String`.

- [ ] **Step 1: Test schreiben (failing)**

In `PatProtTests/PatProtTests.swift`, nach dem letzten `@Test`:

```swift
@Test func sinnhaftAutoFillIncludesMedikamente() {
    let p = EinsatzProtokoll()
    var med = MedikamentEintrag()
    med.name = "Midazolam"
    med.dosis = "2"
    med.einheit = "mg"
    med.route = "IV"
    p.medikamente = [med]
    let s = SINNHAFTBefund.autoFilled(from: p)
    #expect(s.notwendigeMassnahmen.contains("Midazolam"))
}
```

- [ ] **Step 2: Test ausführen — muss FAILED sein**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "sinnhaftAutoFillIncludesMedikamente|FAILED"
```

- [ ] **Step 3: Medikamente-Schleife einfügen**

In `PatProt/Models/Models.swift`, in `autoFilled(from:)`, nach Zeile 1104 (`if m.extremitaetenschienung ...`) und VOR Zeile 1105 (`befund.notwendigeMassnahmen = massnahmenList.joined...`):

```swift
        for med in protokoll.medikamente {
            let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
            var parts: [String] = [med.name]
            if !med.dosis.isEmpty {
                parts.append("\(med.dosis)\(med.einheit.isEmpty ? "" : " \(med.einheit)")")
            }
            if !med.route.isEmpty { parts.append(med.route) }
            massnahmenList.append("\(parts.joined(separator: " ")) · \(fmt.string(from: med.zeit))")
        }
```

- [ ] **Step 4: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed, 0 Fehler.

- [ ] **Step 5: Commit**

```bash
git add PatProt/Models/Models.swift PatProtTests/PatProtTests.swift
git commit -m "feat: include administered Medikamente in SINNHAFT N2 auto-fill"
```

---

## Task 3: Vitaltrendanzeige in AbschlussView

**Files:**
- Modify: `PatProt/Views/AbschlussView.swift`

**Context:**
- AbschlussView.swift: Section "Übergabe-Messwerte" endet um Zeile 69 (header "Übergabe-Messwerte"). Danach folgt Section "Transportziel" (Zeile 71).
- `protokoll.verlaufMessungen: [VerlaufsMessung]` enthält zeitgestempelte Vitalparameter. `VerlaufsMessung` hat: `zeitpunkt: Date`, `atemFrequenz: Int?`, `spo2: Int?`, `puls: Int?`, `blutdruckSys: Int?`, `blutdruckDia: Int?`, `gcsGesamt: Int?`, `blutzucker: Double?`, `temperatur: Double?`.
- Erste Messung (sortiert nach zeitpunkt) = auto-importierter ABCDE-Snapshot. Letzte = aktuellster Wert.
- Section nur anzeigen wenn `protokoll.verlaufMessungen.count >= 2`.

- [ ] **Step 1: trendRow-Hilfsfunktion und neue Section einfügen**

In `PatProt/Views/AbschlussView.swift`:

1. Neue `@ViewBuilder private func` am Ende von `AbschlussView` (vor der schließenden `}`), nach der letzten vorhandenen `private func`:

```swift
    @ViewBuilder
    private func trendRow(_ label: String, _ erst: Int?, _ letzt: Int?, _ einheit: String, normal: ClosedRange<Int>) -> some View {
        if let e = erst, let l = letzt {
            let pfeil = l > e ? "↑" : l < e ? "↓" : "→"
            let farbe: Color = normal.contains(l) ? .green : .red
            HStack {
                Text(label).foregroundColor(.secondary).font(.subheadline)
                Spacer()
                Text("\(e) \(pfeil) \(l) \(einheit)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(farbe)
            }
        }
    }
```

2. Neue Section nach der Übergabe-Messwerte-Section (nach der `}` die die Section "Übergabe-Messwerte" schließt, vor der Section "Transportziel"):

```swift
            // Vitaltrendanzeige — nur wenn ≥2 Verlaufs-Messungen
            if protokoll.verlaufMessungen.count >= 2,
               let ersteMsg = protokoll.verlaufMessungen.sorted(by: { $0.zeitpunkt < $1.zeitpunkt }).first,
               let letzteMsg = protokoll.verlaufMessungen.sorted(by: { $0.zeitpunkt < $1.zeitpunkt }).last {
                Section {
                    trendRow("Puls",  ersteMsg.puls,      letzteMsg.puls,      "/min", normal: 60...100)
                    trendRow("SpO₂",  ersteMsg.spo2,      letzteMsg.spo2,      "%",    normal: 95...100)
                    trendRow("GCS",   ersteMsg.gcsGesamt, letzteMsg.gcsGesamt, "",     normal: 13...15)
                    if let es = ersteMsg.blutdruckSys, let ed = ersteMsg.blutdruckDia,
                       let ls = letzteMsg.blutdruckSys, let ld = letzteMsg.blutdruckDia {
                        let pfeil = ls > es ? "↑" : ls < es ? "↓" : "→"
                        let farbe: Color = (100...140).contains(ls) ? .green : .red
                        HStack {
                            Text("RR").foregroundColor(.secondary).font(.subheadline)
                            Spacer()
                            Text("\(es)/\(ed) \(pfeil) \(ls)/\(ld) mmHg")
                                .font(.subheadline.monospacedDigit())
                                .foregroundColor(farbe)
                        }
                    }
                } header: {
                    Label("Verlaufstrend (Anfang → Aktuell)", systemImage: "waveform.path.ecg")
                }
            }
```

- [ ] **Step 2: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed, 0 Fehler.

- [ ] **Step 3: Commit**

```bash
git add PatProt/Views/AbschlussView.swift
git commit -m "feat: add vital trend display (Anfang → Aktuell) to AbschlussView"
```
