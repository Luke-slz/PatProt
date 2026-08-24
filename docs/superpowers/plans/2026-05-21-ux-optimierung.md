# UX-Optimierung PatProt — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** EMS-Protokoll-App für ein-händige Bedienung mit Handschuhen optimieren: großes Numpad für alle Zahlen-/Zeitfelder, "Jetzt"-Button für Zeiten, floating "Weiter"-Button immer sichtbar.

**Architecture:** Neue generische `NumpadSheet`-Komponente (Views/NumpadSheet.swift) wird von allen Zahlen- und Zeitfeldern als Sheet verwendet. `ZeitFeld` bekommt zusätzlich einen "Jetzt"-Button. Alle Step-Views erhalten `.safeAreaInset(edge: .bottom)` statt des eingebetteten Form-Buttons.

**Tech Stack:** SwiftUI, Swift 5.9+, Swift Testing (@Test), iOS 16+

---

## File Map

| Datei | Aktion | Was |
|---|---|---|
| `Models/Models.swift` | Modify | `reset()` → Alarmzeit auto-setzen |
| `Views/NumpadSheet.swift` | **Create** | Generische Numpad-Komponente |
| `Views/EinsatzOrtView.swift` | Modify | `ZeitFeld` (Jetzt + Numpad), Einsatz-Nr., Gewicht, Geburtsdatum → Numpad; floating Weiter-Button |
| `Views/ABCDEDetailViews.swift` | Modify | AF, SpO2, Puls, RR, BZ, Temperatur → Numpad; floating Zurück-Button in allen 5 ABCDE-Views |
| `Views/NotfallgeschehenView.swift` | Modify | Floating Weiter-Button |
| `Views/VerlaufView.swift` | Modify | `ZahlenFeld` → NumpadSheet |
| `Views/SAMPLERView.swift` | Modify | Floating Zurück/Weiter-Button |
| `Views/SINNHAFTView.swift` | Modify | Floating Zurück-Button |
| `Views/DiagnoseView.swift` | Modify | Floating Back-Button |
| `Views/MassnahmenView.swift` | Modify | Floating Back-Button |
| `Views/MedikamenteView.swift` | Modify | Floating Back-Button |
| `PatProtTests/PatProtTests.swift` | Modify | Tests für Auto-Alarm + NumpadSheet-Formatierung |

---

## Task 1: Auto-Alarmzeit beim neuen Protokoll

**Files:**
- Modify: `Models/Models.swift` — `reset()` Methode, Zeile ~158
- Modify: `PatProtTests/PatProtTests.swift`

- [ ] **Schritt 1: Failing Test schreiben**

In `PatProtTests/PatProtTests.swift` nach den bestehenden Tests einfügen:

```swift
@Test func neuesProtokollHatAlarmzeit() {
    let p = EinsatzProtokoll()
    p.reset()
    #expect(p.einsatzOrt.alarmzeit != nil)
    let diff = abs(p.einsatzOrt.alarmzeit!.timeIntervalSinceNow)
    #expect(diff < 5)  // innerhalb von 5 Sekunden gesetzt
}
```

- [ ] **Schritt 2: Test laufen lassen — erwartet FAIL**

Xcode: ⌘U (Product → Test)  
Erwartung: `neuesProtokollHatAlarmzeit` schlägt fehl, weil `alarmzeit` nil ist.

- [ ] **Schritt 3: reset() anpassen**

In `Models/Models.swift`, in `reset()` nach `einsatzOrt = EinsatzOrt()` einfügen:

```swift
func reset() {
    einsatzOrt = EinsatzOrt()
    einsatzOrt.alarmzeit = Date()   // ← NEU
    patientDaten = PatientDaten()
    // ... Rest unverändert
```

- [ ] **Schritt 4: Test laufen lassen — erwartet PASS**

- [ ] **Schritt 5: Commit**

```bash
git add PatProt/Models/Models.swift PatProt/PatProtTests/PatProtTests.swift
git commit -m "feat: Alarmzeit wird beim Protokoll-Reset automatisch auf jetzt gesetzt"
```

---

## Task 2: NumpadSheet — Kernkomponente

**Files:**
- Create: `Views/NumpadSheet.swift`
- Modify: `PatProtTests/PatProtTests.swift`

- [ ] **Schritt 1: Tests für Formatierungs-Logik schreiben**

In `PatProtTests/PatProtTests.swift` einfügen:

```swift
@Test func numpadFormatInteger() {
    #expect(NumpadSheet.formatDisplay(digits: "80", mode: .integer(label: "", unit: "")) == "80")
    #expect(NumpadSheet.formatDisplay(digits: "", mode: .integer(label: "", unit: "")) == "—")
}

@Test func numpadFormatTime() {
    #expect(NumpadSheet.formatDisplay(digits: "1432", mode: .time(label: "")) == "14:32")
    #expect(NumpadSheet.formatDisplay(digits: "14", mode: .time(label: "")) == "14")
    #expect(NumpadSheet.formatDisplay(digits: "0", mode: .time(label: "")) == "0")
    #expect(NumpadSheet.formatDisplay(digits: "", mode: .time(label: "")) == "—")
}

@Test func numpadFormatDate() {
    #expect(NumpadSheet.formatDisplay(digits: "01021985", mode: .date(label: "")) == "01.02.1985")
    #expect(NumpadSheet.formatDisplay(digits: "0102", mode: .date(label: "")) == "01.02")
    #expect(NumpadSheet.formatDisplay(digits: "01", mode: .date(label: "")) == "01")
    #expect(NumpadSheet.formatDisplay(digits: "", mode: .date(label: "")) == "—")
}

@Test func numpadFormatDecimal() {
    #expect(NumpadSheet.formatDisplay(digits: "5.4", mode: .decimal(label: "", unit: "")) == "5.4")
    #expect(NumpadSheet.formatDisplay(digits: "", mode: .decimal(label: "", unit: "")) == "—")
}
```

- [ ] **Schritt 2: Tests laufen lassen — erwartet FAIL** (NumpadSheet existiert noch nicht)

- [ ] **Schritt 3: NumpadSheet.swift erstellen**

Neue Datei `PatProt/Views/NumpadSheet.swift`:

```swift
import SwiftUI

// MARK: - Numpad Mode

enum NumpadMode: Equatable {
    case integer(label: String, unit: String, maxDigits: Int = 3)
    case decimal(label: String, unit: String)
    case time(label: String)        // HH:MM — 4 Ziffern, Doppelpunkt auto
    case date(label: String)        // TT.MM.JJJJ — 8 Ziffern, Punkte auto
    case bloodPressure              // Zwei-Schritt: sys dann dia
}

// MARK: - NumpadSheet

struct NumpadSheet: View {
    let mode: NumpadMode
    let initial: String
    let onConfirm: (String) -> Void
    let initialSys: String
    let initialDia: String
    let onConfirmBP: ((String, String) -> Void)?

    @State private var digits: String = ""
    @State private var bpStep: BPStep = .sys
    @State private var sysDigits: String = ""
    @Environment(\.dismiss) private var dismiss

    enum BPStep { case sys, dia }

    // Initializer für alle Modi außer bloodPressure
    init(mode: NumpadMode, initial: String = "", onConfirm: @escaping (String) -> Void) {
        self.mode = mode
        self.initial = initial
        self.onConfirm = onConfirm
        self.initialSys = ""
        self.initialDia = ""
        self.onConfirmBP = nil
    }

    // Initializer für bloodPressure
    init(initialSys: String = "", initialDia: String = "",
         onConfirmBP: @escaping (String, String) -> Void) {
        self.mode = .bloodPressure
        self.initial = initialSys
        self.onConfirm = { _ in }
        self.initialSys = initialSys
        self.initialDia = initialDia
        self.onConfirmBP = onConfirmBP
    }

    // MARK: - Statische Formatierung (testbar)

    static func formatDisplay(digits: String, mode: NumpadMode) -> String {
        guard !digits.isEmpty else { return "—" }
        switch mode {
        case .integer, .decimal, .bloodPressure:
            return digits
        case .time:
            guard digits.count > 2 else { return digits }
            let h = String(digits.prefix(2))
            let m = String(digits.dropFirst(2))
            return "\(h):\(m)"
        case .date:
            var s = digits
            if s.count > 2 {
                s.insert(".", at: s.index(s.startIndex, offsetBy: 2))
            }
            if s.count > 5 {
                s.insert(".", at: s.index(s.startIndex, offsetBy: 5))
            }
            return s
        }
    }

    // MARK: - Computed

    private var title: String {
        switch mode {
        case .integer(let label, _, _): return label
        case .decimal(let label, _):    return label
        case .time(let label):          return label
        case .date(let label):          return label
        case .bloodPressure:            return bpStep == .sys ? "Blutdruck systolisch" : "Blutdruck diastolisch"
        }
    }

    private var unitText: String {
        switch mode {
        case .integer(_, let unit, _): return unit
        case .decimal(_, let unit):    return unit
        default: return ""
        }
    }

    private var maxDigits: Int {
        switch mode {
        case .integer(_, _, let m): return m
        case .decimal:              return 6   // z.B. "123.45"
        case .time:                 return 4
        case .date:                 return 8
        case .bloodPressure:        return 3
        }
    }

    private var displayText: String {
        Self.formatDisplay(digits: digits, mode: mode)
    }

    // MARK: - Aktionen

    private func appendDigit(_ d: String) {
        let currentMax = maxDigits
        let pure = digits.filter { $0.isNumber }
        if pure.count < currentMax { digits += d }
    }

    private func appendDecimalPoint() {
        if !digits.contains(".") && !digits.isEmpty { digits += "." }
    }

    private func delete() {
        if !digits.isEmpty { digits.removeLast() }
    }

    private func confirm() {
        switch mode {
        case .bloodPressure:
            if bpStep == .sys {
                sysDigits = digits
                digits = initialDia.filter { $0.isNumber }
                bpStep = .dia
            } else {
                onConfirmBP?(sysDigits, digits)
                dismiss()
            }
        case .time:
            let d = displayText
            guard d.count == 5 else { return }
            let parts = d.split(separator: ":")
            guard parts.count == 2,
                  let h = Int(parts[0]), let m = Int(parts[1]),
                  (0..<24).contains(h), (0..<60).contains(m) else { return }
            onConfirm(d)
            dismiss()
        default:
            guard !digits.isEmpty else { return }
            onConfirm(displayText)
            dismiss()
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.top, 24)

            if !unitText.isEmpty {
                Text(unitText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }

            Text(displayText)
                .font(.system(size: 52, weight: .light, design: .monospaced))
                .frame(height: 72)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

            Divider().padding(.bottom, 10)

            VStack(spacing: 10) {
                ForEach([[7, 8, 9], [4, 5, 6], [1, 2, 3]], id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { digit in
                            NumpadKey(label: "\(digit)") { appendDigit("\(digit)") }
                        }
                    }
                }

                HStack(spacing: 10) {
                    if case .decimal = mode {
                        NumpadKey(label: ",") { appendDecimalPoint() }
                    } else {
                        NumpadKey(label: "⌫", style: .secondary) { delete() }
                    }
                    NumpadKey(label: "0") { appendDigit("0") }
                    NumpadKey(label: "✓", style: .primary) { confirm() }
                }

                if case .decimal = mode {
                    HStack(spacing: 10) {
                        NumpadKey(label: "⌫", style: .secondary) { delete() }
                        NumpadKey(label: "Bestätigen", style: .primary, wide: true) { confirm() }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 24)
        }
        .presentationDetents([.medium])
        .onAppear {
            switch mode {
            case .bloodPressure:
                digits = initialSys.filter { $0.isNumber }
            default:
                digits = initial.filter { $0.isNumber }
            }
        }
    }
}

// MARK: - NumpadKey

private struct NumpadKey: View {
    enum Style { case normal, primary, secondary }
    let label: String
    var style: Style = .normal
    var wide: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title2.weight(.medium))
                .frame(maxWidth: wide ? .infinity : nil)
                .frame(width: wide ? nil : 100, height: 72)
                .background(background)
                .foregroundColor(style == .primary ? .white : .primary)
                .cornerRadius(14)
        }
    }

    private var background: Color {
        switch style {
        case .primary:   return Color("RDOrange")
        case .secondary: return Color(.systemGray4)
        case .normal:    return Color(.systemGray5)
        }
    }
}
```

- [ ] **Schritt 4: Tests laufen lassen — erwartet PASS**

- [ ] **Schritt 5: Commit**

```bash
git add PatProt/Views/NumpadSheet.swift PatProt/PatProtTests/PatProtTests.swift
git commit -m "feat: NumpadSheet — generische Numpad-Komponente für alle Zahlen- und Zeitfelder"
```

---

## Task 3: ZeitFeld — Jetzt-Button + NumpadSheet

**Files:**
- Modify: `Views/EinsatzOrtView.swift` — `ZeitFeld` struct, Zeile ~669

- [ ] **Schritt 1: ZeitFeld komplett ersetzen**

In `EinsatzOrtView.swift` den gesamten `ZeitFeld`-Struct (Zeilen ~669–718) durch folgende Version ersetzen:

```swift
struct ZeitFeld: View {
    let label: String
    @Binding var datum: Date?
    @State private var zeigeNumpad = false

    private var displayText: String {
        guard let d = datum else { return "" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(displayText.isEmpty ? "--:--" : displayText)
                .foregroundColor(displayText.isEmpty ? .secondary : .primary)
                .frame(width: 50, alignment: .trailing)
            Button("Jetzt") { setzeJetzt() }
                .buttonStyle(.bordered)
                .tint(Color("RDOrange"))
                .controlSize(.small)
        }
        .contentShape(Rectangle())
        .onTapGesture { zeigeNumpad = true }
        .sheet(isPresented: $zeigeNumpad) {
            NumpadSheet(mode: .time(label: label), initial: displayText) { timeStr in
                applyTime(timeStr)
            }
        }
    }

    private func setzeJetzt() {
        let now = Date()
        let cal = Calendar.current
        let base = datum ?? now
        var comps = cal.dateComponents([.year, .month, .day], from: base)
        comps.hour = cal.component(.hour, from: now)
        comps.minute = cal.component(.minute, from: now)
        datum = cal.date(from: comps)
    }

    private func applyTime(_ fmt: String) {
        guard fmt.count == 5 else { return }
        let parts = fmt.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]), let m = Int(parts[1]),
              (0..<24).contains(h), (0..<60).contains(m) else { return }
        let base = datum ?? Date()
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: base)
        comps.hour = h
        comps.minute = m
        datum = Calendar.current.date(from: comps)
    }
}
```

- [ ] **Schritt 2: App bauen und testen**

Xcode: ⌘B — muss fehlerfrei kompilieren.  
Manuell prüfen: Zeitfeld antippen → Numpad erscheint; "Jetzt" tipppen → Zeit gesetzt ohne Numpad.

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Views/EinsatzOrtView.swift
git commit -m "feat: ZeitFeld mit Jetzt-Button und NumpadSheet"
```

---

## Task 4: Numpad in BreathingView (AF, SpO₂)

**Files:**
- Modify: `Views/ABCDEDetailViews.swift` — `BreathingView` struct (~Zeile 131)

- [ ] **Schritt 1: @State für Numpad-Sichtbarkeit hinzufügen**

In `BreathingView` nach den bestehenden `@State`-Variablen einfügen:

```swift
@State private var zeigeAfNumpad = false
@State private var zeigeSpo2Numpad = false
```

- [ ] **Schritt 2: AF-Zeile ersetzen** (aktuell ~Zeile 168)

```swift
// ALT:
VStack(alignment: .leading, spacing: 2) {
    HStack {
        Text("Atemfrequenz (/min)")
        Spacer()
        TextField("z.B. 16", value: $befund.atemFrequenz, format: .number)
            .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 80)
    }
    if let (msg, crit) = afWarn {
        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
    }
}
.listRowBackground(afBg)

// NEU:
VStack(alignment: .leading, spacing: 2) {
    HStack {
        Text("Atemfrequenz (/min)")
        Spacer()
        Text(befund.atemFrequenz.map(String.init) ?? "—")
            .foregroundColor(befund.atemFrequenz == nil ? .secondary : .primary)
    }
    if let (msg, crit) = afWarn {
        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
    }
}
.listRowBackground(afBg)
.contentShape(Rectangle())
.onTapGesture { zeigeAfNumpad = true }
.sheet(isPresented: $zeigeAfNumpad) {
    NumpadSheet(mode: .integer(label: "Atemfrequenz", unit: "/min"),
                initial: befund.atemFrequenz.map(String.init) ?? "") { val in
        befund.atemFrequenz = Int(val)
    }
}
```

- [ ] **Schritt 3: SpO₂-Zeile ersetzen** (aktuell ~Zeile 178)

```swift
// ALT:
VStack(alignment: .leading, spacing: 2) {
    HStack {
        Text("SpO₂ (%)")
        Spacer()
        TextField("z.B. 98", value: $befund.spo2, format: .number)
            .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 80)
    }
    if let (msg, crit) = spo2Warn {
        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
    }
}
.listRowBackground(spo2Bg)

// NEU:
VStack(alignment: .leading, spacing: 2) {
    HStack {
        Text("SpO₂ (%)")
        Spacer()
        Text(befund.spo2.map(String.init) ?? "—")
            .foregroundColor(befund.spo2 == nil ? .secondary : .primary)
    }
    if let (msg, crit) = spo2Warn {
        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
    }
}
.listRowBackground(spo2Bg)
.contentShape(Rectangle())
.onTapGesture { zeigeSpo2Numpad = true }
.sheet(isPresented: $zeigeSpo2Numpad) {
    NumpadSheet(mode: .integer(label: "SpO₂", unit: "%"),
                initial: befund.spo2.map(String.init) ?? "") { val in
        befund.spo2 = Int(val)
    }
}
```

- [ ] **Schritt 4: Bauen + manuell prüfen** (⌘B, dann Breathing-View testen)

- [ ] **Schritt 5: Commit**

```bash
git add PatProt/Views/ABCDEDetailViews.swift
git commit -m "feat: AF und SpO2 in BreathingView über NumpadSheet eingeben"
```

---

## Task 5: Numpad in CirculationView (Puls, Blutdruck)

**Files:**
- Modify: `Views/ABCDEDetailViews.swift` — `CirculationView` struct (~Zeile 242)

- [ ] **Schritt 1: @State hinzufügen**

In `CirculationView` einfügen:

```swift
@State private var zeigePulsNumpad = false
@State private var zeigeRrNumpad = false
```

- [ ] **Schritt 2: Puls-Zeile ersetzen** (aktuell ~Zeile 299)

```swift
// ALT:
VStack(alignment: .leading, spacing: 2) {
    HStack {
        Text("Puls (/min)")
        Spacer()
        TextField("z.B. 80", value: $befund.puls, format: .number)
            .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 80)
    }
    if let (msg, crit) = pulsWarn {
        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
    }
}
.listRowBackground(pulsBg)

// NEU:
VStack(alignment: .leading, spacing: 2) {
    HStack {
        Text("Puls (/min)")
        Spacer()
        Text(befund.puls.map(String.init) ?? "—")
            .foregroundColor(befund.puls == nil ? .secondary : .primary)
    }
    if let (msg, crit) = pulsWarn {
        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
    }
}
.listRowBackground(pulsBg)
.contentShape(Rectangle())
.onTapGesture { zeigePulsNumpad = true }
.sheet(isPresented: $zeigePulsNumpad) {
    NumpadSheet(mode: .integer(label: "Puls", unit: "/min"),
                initial: befund.puls.map(String.init) ?? "") { val in
        befund.puls = Int(val)
    }
}
```

- [ ] **Schritt 3: Blutdruck-Zeile ersetzen** (aktuell ~Zeile 321 nach Task 0 — die kombinierte Zeile mit sys/dia)

```swift
// ALT (die VStack mit sys/dia TextFields + rrWarn):
VStack(alignment: .leading, spacing: 2) {
    HStack {
        Text("Blutdruck")
        Spacer()
        TextField("sys", value: $befund.blutdruckSystolisch, format: .number)
            .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 52)
        Text("/").foregroundColor(.secondary)
        TextField("dia", value: $befund.blutdruckDiastolisch, format: .number)
            .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 52)
        Text("mmHg").font(.caption).foregroundColor(.secondary)
    }
    if let (msg, crit) = rrWarn {
        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
    }
}
.listRowBackground(rrBg)

// NEU:
VStack(alignment: .leading, spacing: 2) {
    HStack {
        Text("Blutdruck")
        Spacer()
        let sysStr = befund.blutdruckSystolisch.map(String.init) ?? "—"
        let diaStr = befund.blutdruckDiastolisch.map(String.init) ?? "—"
        Text("\(sysStr) / \(diaStr)")
            .foregroundColor(befund.blutdruckSystolisch == nil && befund.blutdruckDiastolisch == nil ? .secondary : .primary)
        Text("mmHg").font(.caption).foregroundColor(.secondary)
    }
    if let (msg, crit) = rrWarn {
        Text(msg).font(.caption).foregroundColor(crit ? .red : .orange)
    }
}
.listRowBackground(rrBg)
.contentShape(Rectangle())
.onTapGesture { zeigeRrNumpad = true }
.sheet(isPresented: $zeigeRrNumpad) {
    NumpadSheet(
        initialSys: befund.blutdruckSystolisch.map(String.init) ?? "",
        initialDia: befund.blutdruckDiastolisch.map(String.init) ?? ""
    ) { sys, dia in
        befund.blutdruckSystolisch = Int(sys)
        befund.blutdruckDiastolisch = Int(dia)
    }
}
```

- [ ] **Schritt 4: Bauen + prüfen** (Blutdruck-Sheet muss sys→dia zweistufig funktionieren)

- [ ] **Schritt 5: Commit**

```bash
git add PatProt/Views/ABCDEDetailViews.swift
git commit -m "feat: Puls und Blutdruck in CirculationView über NumpadSheet"
```

---

## Task 6: Numpad in DisabilityView (BZ) + ExposureView (Temperatur)

**Files:**
- Modify: `Views/ABCDEDetailViews.swift` — `DisabilityView` (~Zeile 375) und `ExposureView` (~Zeile 572)

- [ ] **Schritt 1: @State in DisabilityView hinzufügen**

```swift
@State private var zeigeBzNumpad = false
```

- [ ] **Schritt 2: Blutzucker-Zeile in DisabilityView ersetzen** (~Zeile 484)

```swift
// ALT:
HStack {
    Text("Blutzucker (mmol/L)")
    Spacer()
    TextField("optional", value: $befund.blutzucker, format: .number)
        .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
}

// NEU:
HStack {
    Text("Blutzucker (mmol/L)")
    Spacer()
    Text(befund.blutzucker.map { String(format: "%.1f", $0) } ?? "—")
        .foregroundColor(befund.blutzucker == nil ? .secondary : .primary)
}
.contentShape(Rectangle())
.onTapGesture { zeigeBzNumpad = true }
.sheet(isPresented: $zeigeBzNumpad) {
    NumpadSheet(mode: .decimal(label: "Blutzucker", unit: "mmol/L"),
                initial: befund.blutzucker.map { String(format: "%.1f", $0) } ?? "") { val in
        befund.blutzucker = Double(val.replacingOccurrences(of: ",", with: "."))
    }
}
```

Hinweis: `VStack`-Wrapper und `bzWarn` bleiben unverändert — nur der innere `HStack` wird ersetzt.

- [ ] **Schritt 3: @State in ExposureView hinzufügen**

```swift
@State private var zeigeTempNumpad = false
```

- [ ] **Schritt 4: Temperatur-Zeile in ExposureView ersetzen** (~Zeile 592)

```swift
// ALT:
HStack {
    Text("Körpertemperatur (°C)")
    Spacer()
    TextField("z.B. 37.0", value: $befund.temperatur, format: .number)
        .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
}

// NEU:
HStack {
    Text("Körpertemperatur (°C)")
    Spacer()
    Text(befund.temperatur.map { String(format: "%.1f", $0) } ?? "—")
        .foregroundColor(befund.temperatur == nil ? .secondary : .primary)
}
.contentShape(Rectangle())
.onTapGesture { zeigeTempNumpad = true }
.sheet(isPresented: $zeigeTempNumpad) {
    NumpadSheet(mode: .decimal(label: "Körpertemperatur", unit: "°C"),
                initial: befund.temperatur.map { String(format: "%.1f", $0) } ?? "") { val in
        befund.temperatur = Double(val.replacingOccurrences(of: ",", with: "."))
    }
}
```

- [ ] **Schritt 5: Bauen + prüfen**

- [ ] **Schritt 6: Commit**

```bash
git add PatProt/Views/ABCDEDetailViews.swift
git commit -m "feat: Blutzucker und Temperatur über NumpadSheet eingeben"
```

---

## Task 7: Numpad in EinsatzOrtView (Einsatz-Nr., Gewicht, Geburtsdatum)

**Files:**
- Modify: `Views/EinsatzOrtView.swift`

- [ ] **Schritt 1: @State-Variablen hinzufügen**

In `EinsatzOrtView` nach den bestehenden `@State`-Variablen:

```swift
@State private var zeigeEinsatzNrNumpad = false
@State private var zeigeGewichtNumpad = false
@State private var zeigeGeburtsdatumNumpad = false
```

- [ ] **Schritt 2: Einsatz-Nr.-TextField ersetzen** (~Zeile 51)

```swift
// ALT:
TextField("Einsatz-Nr.", text: $protokoll.einsatzOrt.einsatzNummer)
    .keyboardType(.numberPad)

// NEU:
HStack {
    Text("Einsatz-Nr.")
    Spacer()
    Text(protokoll.einsatzOrt.einsatzNummer.isEmpty ? "—" : protokoll.einsatzOrt.einsatzNummer)
        .foregroundColor(protokoll.einsatzOrt.einsatzNummer.isEmpty ? .secondary : .primary)
}
.contentShape(Rectangle())
.onTapGesture { zeigeEinsatzNrNumpad = true }
.sheet(isPresented: $zeigeEinsatzNrNumpad) {
    NumpadSheet(mode: .integer(label: "Einsatz-Nr.", unit: "", maxDigits: 10),
                initial: protokoll.einsatzOrt.einsatzNummer) { val in
        protokoll.einsatzOrt.einsatzNummer = val
    }
}
```

- [ ] **Schritt 3: Gewicht-Zeile ersetzen** (~Zeile 185)

```swift
// ALT:
HStack {
    Text("Gewicht (kg)")
    Spacer()
    TextField("optional", value: $protokoll.patientDaten.gewicht, format: .number)
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.trailing)
        .frame(width: 80)
}

// NEU:
HStack {
    Text("Gewicht (kg)")
    Spacer()
    Text(protokoll.patientDaten.gewicht.map { "\(Int($0)) kg" } ?? "—")
        .foregroundColor(protokoll.patientDaten.gewicht == nil ? .secondary : .primary)
}
.contentShape(Rectangle())
.onTapGesture { zeigeGewichtNumpad = true }
.sheet(isPresented: $zeigeGewichtNumpad) {
    NumpadSheet(mode: .decimal(label: "Gewicht", unit: "kg"),
                initial: protokoll.patientDaten.gewicht.map(String.init) ?? "") { val in
        protokoll.patientDaten.gewicht = Double(val.replacingOccurrences(of: ",", with: "."))
    }
}
```

- [ ] **Schritt 4: Geburtsdatum-Zeile ersetzen** (~Zeile 158)

```swift
// ALT (gesamter TextField + onChange-Block):
TextField("Geburtsdatum (TT.MM.JJJJ)", text: $geburtsdatumText)
    .keyboardType(.numberPad)
    .onChange(of: geburtsdatumText) { _, value in
        // ... Auto-Format-Logik ...
    }

// NEU:
HStack {
    Text("Geburtsdatum")
    Spacer()
    Text(geburtsdatumText.isEmpty ? "TT.MM.JJJJ" : geburtsdatumText)
        .foregroundColor(geburtsdatumText.isEmpty ? .secondary : .primary)
}
.contentShape(Rectangle())
.onTapGesture { zeigeGeburtsdatumNumpad = true }
.sheet(isPresented: $zeigeGeburtsdatumNumpad) {
    NumpadSheet(mode: .date(label: "Geburtsdatum"),
                initial: geburtsdatumText) { dateStr in
        geburtsdatumText = dateStr
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        if let date = formatter.date(from: dateStr) {
            protokoll.patientDaten.geburtsDatum = date
        }
    }
}
```

Das `onAppear`-Block für `geburtsdatumText` bleibt unverändert.

- [ ] **Schritt 5: Bauen + prüfen** (Alle drei Felder testen)

- [ ] **Schritt 6: Commit**

```bash
git add PatProt/Views/EinsatzOrtView.swift
git commit -m "feat: Einsatz-Nr., Gewicht und Geburtsdatum über NumpadSheet eingeben"
```

---

## Task 8: Numpad in VerlaufView (ZahlenFeld)

**Files:**
- Modify: `Views/VerlaufView.swift` — `ZahlenFeld` struct (~Zeile 467)

- [ ] **Schritt 1: ZahlenFeld-Struct ersetzen**

```swift
// ALT:
private struct ZahlenFeld: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var istDezimal: Bool = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(placeholder, text: $text)
                .keyboardType(istDezimal ? .decimalPad : .numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }
}

// NEU:
private struct ZahlenFeld: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var istDezimal: Bool = false
    @State private var zeigeNumpad = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(text.isEmpty ? placeholder : text)
                .foregroundColor(text.isEmpty ? .secondary : .primary)
        }
        .contentShape(Rectangle())
        .onTapGesture { zeigeNumpad = true }
        .sheet(isPresented: $zeigeNumpad) {
            if istDezimal {
                NumpadSheet(mode: .decimal(label: label, unit: ""),
                            initial: text) { val in text = val }
            } else {
                NumpadSheet(mode: .integer(label: label, unit: "", maxDigits: 4),
                            initial: text) { val in text = val }
            }
        }
    }
}
```

Hinweis: `speichern()` in `VerlaufView` verwendet bereits `.replacingOccurrences(of: ",", with: ".")` — das bleibt unverändert und deckt das Dezimal-Komma ab.

- [ ] **Schritt 2: Bauen + prüfen** (Verlauf-Messung öffnen, Felder antippen)

- [ ] **Schritt 3: Commit**

```bash
git add PatProt/Views/VerlaufView.swift
git commit -m "feat: VerlaufView ZahlenFeld nutzt NumpadSheet"
```

---

## Task 9: Floating Button — EinsatzOrtView + NotfallgeschehenView

**Files:**
- Modify: `Views/EinsatzOrtView.swift`
- Modify: `Views/NotfallgeschehenView.swift`

- [ ] **Schritt 1: EinsatzOrtView — Button-Section entfernen und floating einfügen**

In `EinsatzOrtView.swift`:

Entfernen (~Zeile 214):
```swift
Section {
    Button(action: onWeiter) {
        Label("Weiter zur Befunderhebung", systemImage: "arrow.right.circle.fill")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }
    .buttonStyle(.borderedProminent)
    .tint(Color("RDOrange"))
}
```

Stattdessen `.safeAreaInset` an das `Form` anhängen (direkt vor `.onAppear`):
```swift
.safeAreaInset(edge: .bottom) {
    Button(action: onWeiter) {
        Label("Weiter zur Befunderhebung", systemImage: "arrow.right.circle.fill")
            .frame(maxWidth: .infinity)
            .padding()
    }
    .buttonStyle(.borderedProminent)
    .tint(Color("RDOrange"))
    .padding([.horizontal, .bottom])
    .background(.bar)
}
```

- [ ] **Schritt 2: NotfallgeschehenView — gleiche Änderung**

Entfernen (~Zeile 57):
```swift
Section {
    Button(action: onWeiter) {
        Label("Weiter zur Befunderhebung", systemImage: "arrow.right.circle.fill")
            .frame(maxWidth: .infinity).padding(.vertical, 4)
    }
    .buttonStyle(.borderedProminent).tint(Color("RDOrange"))
}
```

Floating Button anhängen (vor `.navigationTitle`):
```swift
.safeAreaInset(edge: .bottom) {
    Button(action: onWeiter) {
        Label("Weiter zur Befunderhebung", systemImage: "arrow.right.circle.fill")
            .frame(maxWidth: .infinity)
            .padding()
    }
    .buttonStyle(.borderedProminent)
    .tint(Color("RDOrange"))
    .padding([.horizontal, .bottom])
    .background(.bar)
}
```

- [ ] **Schritt 3: Bauen + prüfen** (Button oben ohne Scrollen sichtbar)

- [ ] **Schritt 4: Commit**

```bash
git add PatProt/Views/EinsatzOrtView.swift PatProt/Views/NotfallgeschehenView.swift
git commit -m "feat: Floating Weiter-Button in EinsatzOrtView und NotfallgeschehenView"
```

---

## Task 10: Floating Button — ABCDEDetailViews

**Files:**
- Modify: `Views/ABCDEDetailViews.swift` — AirwayView, BreathingView, CirculationView, DisabilityView, ExposureView

In jeder der 5 Views das gleiche Muster anwenden:

**Muster:** Die bestehende `Section` mit dem `Button(action: onZurueck)` entfernen und stattdessen `.safeAreaInset` anhängen.

- [ ] **Schritt 1: AirwayView** (~Zeile 115)

Entfernen:
```swift
Section {
    Button(action: onZurueck) {
        Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
            .frame(maxWidth: .infinity).padding(.vertical, 4)
    }
    .buttonStyle(.borderedProminent).tint(Color("RDOrange"))
}
```

Nach der `}` des `Form {` einfügen (vor `.navigationTitle`):
```swift
.safeAreaInset(edge: .bottom) {
    Button(action: onZurueck) {
        Label("Zurück zur Übersicht", systemImage: "checkmark.circle.fill")
            .frame(maxWidth: .infinity)
            .padding()
    }
    .buttonStyle(.borderedProminent)
    .tint(Color("RDOrange"))
    .padding([.horizontal, .bottom])
    .background(.bar)
}
```

- [ ] **Schritt 2: BreathingView** — gleiche Änderung (~Zeile 227)

- [ ] **Schritt 3: CirculationView** — gleiche Änderung (~Zeile 360)

- [ ] **Schritt 4: DisabilityView** — gleiche Änderung (~Zeile 507)

- [ ] **Schritt 5: ExposureView** — gleiche Änderung (~Zeile 633)

- [ ] **Schritt 6: Bauen + prüfen** (alle 5 ABCDE-Views testen)

- [ ] **Schritt 7: Commit**

```bash
git add PatProt/Views/ABCDEDetailViews.swift
git commit -m "feat: Floating Zurück-Button in allen ABCDE-Detail-Views"
```

---

## Task 11: Floating Button — SAMPLER, SINNHAFT, Diagnose, Massnahmen, Medikamente

**Files:**
- Modify: `Views/SAMPLERView.swift`
- Modify: `Views/SINNHAFTView.swift`
- Modify: `Views/DiagnoseView.swift`
- Modify: `Views/MassnahmenView.swift`
- Modify: `Views/MedikamenteView.swift`

Gleiches Muster wie Task 10: Button-Section am Formende entfernen, `.safeAreaInset(edge: .bottom)` anfügen.

SAMPLERView hat zwei Buttons (onZurueck und onWeiter in separaten Sections) — beide durch `.safeAreaInset` mit `HStack` ersetzen:

- [ ] **Schritt 1: SAMPLERView**

Die zwei Button-Sections entfernen und ersetzen durch:
```swift
.safeAreaInset(edge: .bottom) {
    HStack(spacing: 12) {
        Button(action: onZurueck) {
            Label("Zurück", systemImage: "chevron.left.circle.fill")
                .frame(maxWidth: .infinity).padding()
        }
        .buttonStyle(.bordered)
        .tint(Color("RDOrange"))

        Button(action: onWeiter) {
            Label("Weiter", systemImage: "arrow.right.circle.fill")
                .frame(maxWidth: .infinity).padding()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color("RDOrange"))
    }
    .padding([.horizontal, .bottom])
    .background(.bar)
}
```

- [ ] **Schritt 2: SINNHAFTView** — Button-Section entfernen, floating Zurück einfügen

- [ ] **Schritt 3: DiagnoseView** — Button-Section entfernen, floating Back einfügen (callback heißt `onBack`)

- [ ] **Schritt 4: MassnahmenView** — Button-Section entfernen, floating Back einfügen

- [ ] **Schritt 5: MedikamenteView** — Button-Section entfernen, floating Back einfügen

- [ ] **Schritt 6: Bauen + prüfen**

- [ ] **Schritt 7: Commit**

```bash
git add PatProt/Views/SAMPLERView.swift PatProt/Views/SINNHAFTView.swift \
        PatProt/Views/DiagnoseView.swift PatProt/Views/MassnahmenView.swift \
        PatProt/Views/MedikamenteView.swift
git commit -m "feat: Floating Action-Buttons in SAMPLER, SINNHAFT, Diagnose, Massnahmen, Medikamente"
```
