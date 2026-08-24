# Design: Batch 11 — Qualifikation, SINNHAFT Medikamente, Vitaltrendanzeige

**Datum:** 2026-05-28
**Scope:** ProtokollVerfasser Qualifikation erweitern, SINNHAFT N2 Medikamente, Vitaltrendanzeige in AbschlussView

---

## 1. ProtokollVerfasser Qualifikation erweitern

### Problem
`ProtokollVerfasser` hat nur 2 Fälle: `notfallsanitaeter` und `rettungssanitaeter`. Ersthelfer (EH/EH-E), Rettungsassistent und Arzt können das Protokoll nicht korrekt abzeichnen. Im PDF werden nur 2 Checkboxen gerendert.

### Fix

**Models.swift** — `ProtokollVerfasser` (Zeilen 93–96), 4 neue Cases, bestehende rawValues beibehalten (Codable-Kompatibilität):

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

Bestehende rawValues `"Rettungssanitäter"` und `"Notfallsanitäter"` bleiben unverändert → vorhandene Archive dekodieren fehlerfrei.

**AbschlussView.swift** — Picker-Style ändern: mit 6 Items ist `.segmented` zu schmal → `.menu`:
```swift
.pickerStyle(.menu)
```

**PDFGenerator.swift** — Zeilen 385–386: 2 Checkboxen → 6 Checkboxen in 2 Reihen:

```swift
// Reihe 1
cb("EH",     p.verfasser == .ersthelfer,          x:x+3,   y:titleY+19, bs:7, lw:28)
cb("EH-E",   p.verfasser == .ersthelferE,         x:x+45,  y:titleY+19, bs:7, lw:33)
cb("RS",     p.verfasser == .rettungssanitaeter,  x:x+95,  y:titleY+19, bs:7, lw:22)
// Reihe 2
cb("RA",     p.verfasser == .rettungsassistent,   x:x+3,   y:titleY+28, bs:7, lw:22)
cb("NotSan", p.verfasser == .notfallsanitaeter,   x:x+45,  y:titleY+28, bs:7, lw:40)
cb("Arzt",   p.verfasser == .arzt,                x:x+95,  y:titleY+28, bs:7, lw:25)
```

---

## 2. SINNHAFT N2 — Medikamente in autoFilled

### Problem
`SINNHAFTBefund.autoFilled(from:)` füllt `notwendigeMassnahmen` aus `MassnahmenBefund`, aber nicht aus den administrierten Medikamenten (`protokoll.medikamente: [MedikamentEintrag]`). Medikamentengaben fehlen im SINNHAFT-Übergabetext.

### Fix

**Models.swift** — in `autoFilled(from:)`, nach der Massnahmen-Schleife (nach Zeile 1104), vor der Zuweisung an `befund.notwendigeMassnahmen`:

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

Beispiel-Output: `"Midazolam 2 mg IV · 10:35"`

---

## 3. Vitaltrendanzeige in AbschlussView

### Problem
AbschlussView zeigt Übergabe-Messwerte (manuell einzutragen), aber keinen automatischen Vergleich Anfangswerte vs. aktuelle Werte. Der EMS-Helfer muss manuell zwischen VerlaufView und AbschlussView wechseln, um Trends zu beurteilen.

### Fix

**AbschlussView.swift** — neue read-only Section „Verlaufstrend" zwischen Übergabe-Messwerte und Transportziel.

Anzeige **nur wenn** `protokoll.verlaufMessungen.count >= 2`.

Erste Messung = `verlaufMessungen.sorted(by: { $0.zeitpunkt < $1.zeitpunkt }).first` (auto-importierter ABCDE-Snapshot).
Letzte Messung = `.last` in derselben Sortierung.

```swift
Section {
    trendRow("Puls",  ersteMsg.puls,        letzteMsg.puls,        "/min", normal: 60...100)
    trendRow("SpO₂",  ersteMsg.spo2,        letzteMsg.spo2,        "%",    normal: 95...100)
    trendRow("GCS",   ersteMsg.gcsGesamt,   letzteMsg.gcsGesamt,   "",     normal: 13...15)
    // RR: separates if let da sys+dia
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
```

`trendRow` als `@ViewBuilder private func` in AbschlussView:

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

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Models/Models.swift` | `ProtokollVerfasser` +4 Cases; `autoFilled` Medikamente-Schleife |
| `PatProt/Views/AbschlussView.swift` | Picker `.menu`; neue Vitaltrendanzeige-Section |
| `PatProt/Services/PDFGenerator.swift` | 6 Verfasser-Checkboxen statt 2 |
| `PatProtTests/PatProtTests.swift` | 2 neue Tests |

## Tests

```swift
@Test func protokollVerfasserHatSechsFaelle() {
    #expect(ProtokollVerfasser.allCases.count == 6)
    // Bestehende rawValues für Codable-Kompatibilität
    #expect(ProtokollVerfasser.notfallsanitaeter.rawValue == "Notfallsanitäter")
    #expect(ProtokollVerfasser.rettungssanitaeter.rawValue == "Rettungssanitäter")
}

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
