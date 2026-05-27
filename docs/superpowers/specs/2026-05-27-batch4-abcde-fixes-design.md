# Design: Batch 4 — ABCDE-Fixes

**Datum:** 2026-05-27
**Scope:** Brodeln in B-Sektion, EKG-Rhythmus nur bei abgeleitetem EKG, Rekapillarisierung in Kreislauf-Section, Guedel/Wendl-Tubus in Maßnahmen

---

## 1. Brodeln in B — Modell + View + PDF

### Models.swift

`BreathingBefund` — nach `rasselgeraeusche`:
```swift
var brodeln: Bool = false
```

`UebergabeBefunde` — nach `rasselgeraeusche`:
```swift
var brodeln: Bool = false
```

Beide Felder sind rückwärtskompatibel (Codable-Default `false`).

### ABCDEDetailViews.swift — BreathingView

In der „Atemstörungen"-Section, nach `CheckboxRow("Rasselgeräusche", …)`:
```swift
CheckboxRow("Brodeln", isOn: $befund.brodeln)
```

### UebergabeBefundeView.swift

Nach der Rasselgeräusche-Zeile:
```swift
UebergabeRow("Brodeln",
             ankunft:  protokoll.breathing.brodeln,
             uebergabe: $protokoll.uebergabeBefunde.brodeln)
```

### PDFGenerator.swift — abItems

In `drawPage1`, nach dem `("Rasselger.", …)`-Tupel:
```swift
("Brodeln",      p.breathing.brodeln,        ub.brodeln),
```

---

## 2. EKG-Auswahl — EKG-Rhythmus + Extrasystolen gaten

### ABCDEDetailViews.swift — CirculationView

Die EKG-Rhythmus-Section und die Extrasystolen-Section werden in `if befund.ekg { … }` eingebettet.

**Vorher:**
```swift
Section { Label("EKG", …) } header { … }

Section {
    CheckboxRow("Sinusrhythmus", …)
    // … weitere Rhythmen …
    CheckboxRow("Rekap. > 2 Sek.", …)  // ← hier falsch platziert
    CheckboxRow("Nicht beurteilbar", …)
} header: { Label("EKG-Rhythmus", …) }

Section {
    CheckboxRow("SVES", …)
    // …
} header: { Text("Extrasystolen") }
```

**Nachher:**
```swift
Section {
    Toggle("EKG abgeleitet", isOn: $befund.ekg)
    if befund.ekg {
        TextField("EKG-Befund", text: $befund.ekgBefund)
    }
} header: { Label("EKG", …) }

if befund.ekg {
    Section {
        CheckboxRow("Sinusrhythmus", …)
        CheckboxRow("Absolute Arrhythmie", …)
        CheckboxRow("AV-Block II°/III°", …)
        CheckboxRow("QRS-Tachykardie breit", …)
        CheckboxRow("QRS-Tachykardie schmal", …)
        CheckboxRow("Kammerflattern/-flimmern", …)
        CheckboxRow("Pulslose elektr. Akt.", …)
        CheckboxRow("Asystolie", …)
        CheckboxRow("Schrittmacherrhythmus", …)
        CheckboxRow("Infarkt-EKG (STEMI/LSB)", …)
        CheckboxRow("Nicht beurteilbar", …)
    } header: { Label("EKG-Rhythmus", …) }

    Section {
        CheckboxRow("SVES", …)
        CheckboxRow("VES", …)
        CheckboxRow("Monomorph", …)
        CheckboxRow("Polymorph", …)
    } header: { Text("Extrasystolen") }
}
```

Kein Modell-Change nötig.

---

## 3. Rekapillarisierung in Kreislauf-Section verschieben

### ABCDEDetailViews.swift — CirculationView

`CheckboxRow("Rekap. > 2 Sek.", isOn: $befund.rekapillierung)` aus der EKG-Rhythmus-Section **entfernen** und in die Kreislauf-Section einfügen (nach dem Puls-/Blutdruck-Block, vor dem Toggle "Pulslosigkeit" oder als erstes Element nach dem Blutdruck).

```swift
Section {
    // … Puls-Numpad-Row …
    // … RR-Numpad-Row …
    Toggle("Pulslosigkeit / Kreislaufstillstand", isOn: $befund.pulslosigkeit)
    CheckboxRow("Rekap. > 2 Sek.", isOn: $befund.rekapillierung)
} header: { Label("Kreislauf", systemImage: "heart.fill") }
```

Kein Modell-Change nötig (`rekapillierung` ist bereits in `CirculationBefund`).

---

## 4. Guedel/Wendl-Tubus in Maßnahmen

### Models.swift — MassnahmenBefund

Nach `absaugung`:
```swift
var guedelTubus: Bool = false
var wendlTubus:  Bool = false
```

### MassnahmenView.swift

Im Airway/Stabilisation-Block, nach `CheckboxRow("Absaugung", …)`:
```swift
CheckboxRow("Guedel-Tubus (OPA)", isOn: $befund.guedelTubus)
CheckboxRow("Wendl-Tubus (NPA)",  isOn: $befund.wendlTubus)
```

### PDFGenerator.swift — maItems1

In `drawPage2`, Section 6, im `maItems1`-Array nach `("Absaugung", p.massnahmen.absaugung)`:
```swift
("Guedel-Tubus (OPA)", p.massnahmen.guedelTubus),
("Wendl-Tubus (NPA)",  p.massnahmen.wendlTubus),
```

---

## 5. Tests

- `breathingBefundHatBrodeln()` — `BreathingBefund().brodeln == false`
- `massnahmenHatGuedelWendl()` — `MassnahmenBefund().guedelTubus == false`, `.wendlTubus == false`

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Models/Models.swift` | `brodeln` in `BreathingBefund` + `UebergabeBefunde`; `guedelTubus` + `wendlTubus` in `MassnahmenBefund` |
| `PatProt/Views/ABCDEDetailViews.swift` | Brodeln-Checkbox in B; EKG-Rhythmus+Extrasystolen gaten; Rekap. in Kreislauf |
| `PatProt/Views/UebergabeBefundeView.swift` | Brodeln-Übergabe-Row |
| `PatProt/Views/MassnahmenView.swift` | Guedel + Wendl Checkboxen |
| `PatProt/Services/PDFGenerator.swift` | Brodeln in abItems; Guedel+Wendl in maItems1 |
| `PatProtTests/PatProtTests.swift` | 2 neue Tests |
