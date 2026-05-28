# Design: Batch 10 — GCS Stepper, NumpadSheet iPad, Medikamente Maximaldosis

**Datum:** 2026-05-28
**Scope:** GCS Stepper verbessern, NumpadSheet iPad-Größe, Medikamente Maximaldosis

---

## 1. GCS Stepper verbessern

### Problem
Die GCS-Felder (Augen/Verbal/Motor) in `DisabilityView` nutzen `Menu`-Dropdowns. Diese sind im Einsatz langsam (2 Taps: öffnen + auswählen) und zeigen den aktuellen Wert nur als Text. Ein Stepper erlaubt schnelleres +/− ohne Dropdown.

Es gibt bereits eine `GCSStepper`-Komponente (ABCDEDetailViews.swift, Zeile 698), die aber nicht genutzt wird und kein semantisches Label anzeigt.

### Fix

**ABCDEDetailViews.swift — GCSStepper erweitern:**

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

**DisabilityView — drei Menu-HStacks durch GCSStepper ersetzen:**

```swift
// vorher (Zeilen 509-547):
HStack {
    Text("Augen öffnen (E)").font(.subheadline).foregroundColor(.secondary)
    Spacer()
    Menu { ... } label: { Text(labelForGCSAugen(befund.gcsAugen)) }
}
HStack { ... Menu Verbal ... }
HStack { ... Menu Motor ... }

// nachher:
GCSStepper(titel: "Augen öffnen (E)",    wert: $befund.gcsAugen,  min: 1, max: 4, labelFor: labelForGCSAugen)
GCSStepper(titel: "Verbale Reaktion (V)", wert: $befund.gcsVerbal, min: 1, max: 5, labelFor: labelForGCSVerbal)
GCSStepper(titel: "Motorische Reaktion (M)", wert: $befund.gcsMotor, min: 1, max: 6, labelFor: labelForGCSMotor)
```

Die `labelForGCSAugen/Verbal/Motor`-Funktionen sind bereits `fileprivate` in derselben Datei — kein Import nötig.

---

## 2. NumpadSheet iPad-Größe

### Problem
`.presentationDetents([.medium])` ist für iPhone ausgelegt. Auf iPad öffnet sich die Sheet in einem kompakten Popup-Modus, bei dem `.medium` zu wenig Höhe für die Numpad-Tasten lässt.

### Fix

In `PatProt/Views/NumpadSheet.swift`, Zeile 205:

```swift
// vorher:
.presentationDetents([.medium])

// nachher:
.presentationDetents(UIDevice.current.userInterfaceIdiom == .pad ? [.height(560)] : [.medium])
```

Auf iPad: feste Höhe 560pt — genug für alle Tastenreihen + Display + Toolbar.
Auf iPhone: bleibt `.medium` (unverändert).

---

## 3. Medikamente Maximaldosis

### Problem
`MedikamentEintrag` hat kein Feld für die Maximaldosis. First-Responder-Protokolle sollen die maximale Gesamtdosis eines Medikaments dokumentieren (z.B. Midazolam: 2mg gegeben, max. 10mg erlaubt).

### Fix

**Models.swift — MedikamentEintrag** (nach `var zeit: Date = Date()`):
```swift
var maximaldosis: String = ""
```

**MedikamenteView.swift — MedikamentRow** — neues numpad-Feld nach der Dosis-Zeile:

```swift
// Nach der HStack-Zeile mit Dosis/Einheit/Route:
@State private var zeigeMaxDosisNumpad = false

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

**PDFGenerator.swift** — letztes (leeres) Feld in der Medikamenten-Tabelle nutzen:

```swift
// Header (Zeile 1089):
let mHdr = ["Medikament","Dosis","Einheit","Applikationsweg","Zeit","Max.Dos."]

// Row-Werte (Zeile 1105):
let vals2 = [med.name, med.dosis, med.einheit, med.route, t(med.zeit), med.maximaldosis]
```

Die letzte Spalte (11% Breite, war leer) bekommt den `maximaldosis`-Wert. Keine Spaltenbreiten-Anpassung nötig.

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Views/ABCDEDetailViews.swift` | GCSStepper mit labelFor-Parameter; DisabilityView Menüs → GCSStepper |
| `PatProt/Views/NumpadSheet.swift` | iPad-spezifisches presentationDetent |
| `PatProt/Models/Models.swift` | `maximaldosis: String = ""` in MedikamentEintrag |
| `PatProt/Views/MedikamenteView.swift` | Max. Dosis-Zeile in MedikamentRow |
| `PatProt/Services/PDFGenerator.swift` | Max.Dos. Header + Wert in Medikamenten-Tabelle |

## Tests

```swift
@Test func medikamentEintragHatMaximaldosis() {
    let m = MedikamentEintrag()
    #expect(m.maximaldosis == "")
}
```
