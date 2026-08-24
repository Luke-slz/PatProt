# Batch 7 — UI/UX & Komplexe Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** iPad-Startseite an AppStorage anpassen; Eigene Sichtungskategorie (PRIOR) in MANV; Maschinelle-Beatmung-Parameter; Medikamenten-Rechner als Hilfs-Sheet.

**Architecture:** Rückwärtskompatible Model-Erweiterungen (String- und Bool-Defaults), reine View-Ergänzungen, kein neues Service. `MedikamentenRechnerSheet` ist ein reines UI-Tool ohne Persistierung.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Testing, `xcodebuild test`

---

## Dateien

| Datei | Zweck |
|---|---|
| `PatProt/Models/Models.swift` | `manvEigeneSK` + Beatmungsfelder |
| `PatProt/Views/iPadMainView.swift` | AppStorage Startseite |
| `PatProt/Views/NotfallgeschehenView.swift` | SK-Picker |
| `PatProt/Views/MassnahmenView.swift` | Maschinelle Beatmung UI |
| `PatProt/Views/MedikamenteView.swift` | Rechner-Sheet |
| `PatProt/Services/PDFGenerator.swift` | MANV SK + Beatmung im PDF |
| `PatProtTests/PatProtTests.swift` | 2 neue Tests |

---

## Task 1: Model — manvEigeneSK + Maschinelle-Beatmung-Felder + Tests

**Files:**
- Modify: `PatProt/Models/Models.swift`
- Test: `PatProtTests/PatProtTests.swift`

**Context:**
- `NotfallgeschehenBefund` (suche nach `var manvNachforderung: String = ""` — füge danach ein)
- `MassnahmenBefund` (suche nach `var maskenbeatmungUnmoeglich: Bool = false` — füge danach ein)
- Alle neuen Felder sind rückwärtskompatibel (String = "" oder Bool = false)

- [ ] **Step 1: Tests schreiben (failing)**

In `PatProtTests/PatProtTests.swift`, nach dem letzten `@Test`:

```swift
@Test func notfallgeschehenHatManvEigeneSK() {
    let n = NotfallgeschehenBefund()
    #expect(n.manvEigeneSK == "")
}

@Test func massnahmenHatMaschinelleBeatmungFelder() {
    let m = MassnahmenBefund()
    #expect(m.maschinelleBeatmung == false)
    #expect(m.tidalvolumen == "")
    #expect(m.peep == "")
}
```

- [ ] **Step 2: Tests ausführen — müssen fehlschlagen**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "FAILED|notfallgeschehen|massnahmenHat"
```

- [ ] **Step 3: NotfallgeschehenBefund erweitern**

In `PatProt/Models/Models.swift`, nach `var manvNachforderung: String = ""`:

```swift
var manvEigeneSK: String = ""
```

- [ ] **Step 4: MassnahmenBefund erweitern**

In `PatProt/Models/Models.swift`, nach `var maskenbeatmungUnmoeglich: Bool = false`:

```swift
var maschinelleBeatmung:    Bool   = false
var tidalvolumen:           String = ""
var peep:                   String = ""
var fio2:                   String = ""
var beatmungsfrequenzMasch: String = ""
```

- [ ] **Step 5: Tests ausführen — müssen bestehen**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED"
```

Erwartet: alle Tests `passed` (38 total), 0 `FAILED`.

- [ ] **Step 6: Commit**

```bash
git add PatProt/Models/Models.swift PatProtTests/PatProtTests.swift
git commit -m "feat: add manvEigeneSK to NotfallgeschehenBefund, maschinelle Beatmung to MassnahmenBefund"
```

---

## Task 2: iPad Startseite + PRIOR in MANV view

**Files:**
- Modify: `PatProt/Views/iPadMainView.swift`
- Modify: `PatProt/Views/NotfallgeschehenView.swift`

### iPad Startseite

**Context:** In `iPadMainView`, `startScreen` zeigt hardcodierte Strings (suche nach `Text("RD Protokoll")`). Ersetze durch AppStorage.

- [ ] **Step 1: AppStorage Properties hinzufügen**

In `iPadMainView`, bei den `@State`-Deklarationen (nach `@State private var zeigeArchiv = false`), einfügen:

```swift
@AppStorage("einheitenname") private var einheitenname: String = "First Responder Geesthacht"
@AppStorage("startseiteUntertitel") private var startseiteUntertitel: String = "Einsatzprotokollierung First Responder"
```

- [ ] **Step 2: Hardcodierte Strings in startScreen ersetzen**

Suche nach:
```swift
Text("RD Protokoll")
    .font(.largeTitle).fontWeight(.bold)
Text("Einsatzprotokollierung Rettungsdienst")
    .font(.subheadline).foregroundColor(.secondary)
```

Ersetze durch:
```swift
Text(einheitenname.isEmpty ? "First Responder Geesthacht" : einheitenname)
    .font(.largeTitle).fontWeight(.bold)
    .multilineTextAlignment(.center)
Text(startseiteUntertitel.isEmpty ? "Einsatzprotokollierung First Responder" : startseiteUntertitel)
    .font(.subheadline).foregroundColor(.secondary)
    .multilineTextAlignment(.center)
```

### PRIOR in MANV

**Context:** In `NotfallgeschehenView.swift`, `DynamischeErweiterungView`. Die Besonderheiten-Section (mit `Toggle("MANV-Lage", ...)`) existiert. Nach dem `if befund.manv`-Block mit `Toggle("1. Eintreffende Kraft")` kommt der Sichtungsergebnis-Block (nur wenn `befund.manv && befund.ersteEintreffendeKraft`). Danach kommt der MANV-Meldungs-Block (nur wenn `befund.manv`).

Füge eine neue Section **innerhalb** `if befund.manv` ein (z.B. als erste Section nach dem Sichtungsergebnis-Block):

- [ ] **Step 3: SK-Picker einfügen**

In `PatProt/Views/NotfallgeschehenView.swift`, in `DynamischeErweiterungView`, direkt nach dem Sichtungsergebnis-Block (der `if befund.manv && befund.ersteEintreffendeKraft { Section { ... } }` endet) und vor dem MANV-Meldungs-Block:

```swift
if befund.manv {
    Section {
        Picker("Eigene Sichtungskategorie", selection: $befund.manvEigeneSK) {
            Text("–").tag("")
            Text("SK I – Rot (sofort)").tag("SK I")
            Text("SK II – Gelb (aufgeschoben)").tag("SK II")
            Text("SK III – Grün (leicht verletzt)").tag("SK III")
            Text("SK IV – Blau (ohne Überlebenschance)").tag("SK IV")
            Text("T – Schwarz (verstorben)").tag("T")
        }
        .pickerStyle(.menu)
    } header: { Label("Eigene Sichtungskategorie", systemImage: "tag.fill") }
}
```

- [ ] **Step 4: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests `passed`, 0 Fehler.

- [ ] **Step 5: Commit**

```bash
git add PatProt/Views/iPadMainView.swift PatProt/Views/NotfallgeschehenView.swift
git commit -m "feat: iPad start screen uses AppStorage, add PRIOR Sichtungskategorie picker to MANV"
```

---

## Task 3: Maschinelle Beatmung in MassnahmenView + PDFGenerator

**Files:**
- Modify: `PatProt/Views/MassnahmenView.swift`
- Modify: `PatProt/Services/PDFGenerator.swift`

**Context:** In `MassnahmenView.swift`, die `CheckboxRow("Maskenbeatmung (BVM)", ...)` ist aktuell bei ca. Zeile 39. Lese die Datei, um die genaue Stelle und das NumpadSheet-Pattern zu verstehen. Das Pattern aus anderen Feldern (z.B. `sauerstoffLitMin`) ist:

```swift
if befund.sauerstoffgabe {
    HStack {
        Text("L/min")
        Spacer()
        Text(befund.sauerstoffLitMin.isEmpty ? "—" : befund.sauerstoffLitMin)
            .foregroundColor(befund.sauerstoffLitMin.isEmpty ? .secondary : .primary)
    }
    .contentShape(Rectangle())
    .onTapGesture { zeigeSauerstoffNumpad = true }
    .sheet(isPresented: $zeigeSauerstoffNumpad) {
        NumpadSheet(mode: .decimal(label: "O₂ Durchfluss", unit: "L/min"),
                    initial: befund.sauerstoffLitMin) { val in befund.sauerstoffLitMin = val }
    }
}
```

Verwende dasselbe Pattern für die Beatmungsparameter. Benötigte neue `@State`-Variablen in `MassnahmenView`:
- `@State private var zeigeTvNumpad = false`
- `@State private var zeigePeepNumpad = false`
- `@State private var zeigeFio2Numpad = false`
- `@State private var zeigeBfMaschNumpad = false`

- [ ] **Step 1: MassnahmenView — Beatmung UI**

Lese `PatProt/Views/MassnahmenView.swift`, um die genaue Position der Maskenbeatmung-Zeile zu finden.

Füge nach `CheckboxRow("Maskenbeatmung (BVM)", isOn: $befund.maskenbeatmung)` ein:

```swift
if befund.maskenbeatmung {
    CheckboxRow("Maschinelle Beatmung", isOn: $befund.maschinelleBeatmung)
    if befund.maschinelleBeatmung {
        HStack {
            Text("Tidalvolumen (ml)")
            Spacer()
            Text(befund.tidalvolumen.isEmpty ? "—" : befund.tidalvolumen)
                .foregroundColor(befund.tidalvolumen.isEmpty ? .secondary : .primary)
        }
        .contentShape(Rectangle())
        .onTapGesture { zeigeTvNumpad = true }
        .sheet(isPresented: $zeigeTvNumpad) {
            NumpadSheet(mode: .integer(label: "Tidalvolumen", unit: "ml"),
                        initial: befund.tidalvolumen) { val in befund.tidalvolumen = val }
        }
        HStack {
            Text("PEEP (cmH₂O)")
            Spacer()
            Text(befund.peep.isEmpty ? "—" : befund.peep)
                .foregroundColor(befund.peep.isEmpty ? .secondary : .primary)
        }
        .contentShape(Rectangle())
        .onTapGesture { zeigePeepNumpad = true }
        .sheet(isPresented: $zeigePeepNumpad) {
            NumpadSheet(mode: .integer(label: "PEEP", unit: "cmH₂O"),
                        initial: befund.peep) { val in befund.peep = val }
        }
        HStack {
            Text("FiO₂ (%)")
            Spacer()
            Text(befund.fio2.isEmpty ? "—" : befund.fio2)
                .foregroundColor(befund.fio2.isEmpty ? .secondary : .primary)
        }
        .contentShape(Rectangle())
        .onTapGesture { zeigeFio2Numpad = true }
        .sheet(isPresented: $zeigeFio2Numpad) {
            NumpadSheet(mode: .integer(label: "FiO₂", unit: "%"),
                        initial: befund.fio2) { val in befund.fio2 = val }
        }
        HStack {
            Text("AF Gerät (/min)")
            Spacer()
            Text(befund.beatmungsfrequenzMasch.isEmpty ? "—" : befund.beatmungsfrequenzMasch)
                .foregroundColor(befund.beatmungsfrequenzMasch.isEmpty ? .secondary : .primary)
        }
        .contentShape(Rectangle())
        .onTapGesture { zeigeBfMaschNumpad = true }
        .sheet(isPresented: $zeigeBfMaschNumpad) {
            NumpadSheet(mode: .integer(label: "AF Gerät", unit: "/min"),
                        initial: befund.beatmungsfrequenzMasch) { val in befund.beatmungsfrequenzMasch = val }
        }
    }
}
```

Füge die 4 neuen `@State`-Variablen oben in `MassnahmenView` ein (bei den anderen `@State`-Deklarationen).

- [ ] **Step 2: PDFGenerator — Maschinelle Beatmung**

In `PatProt/Services/PDFGenerator.swift`, finde die Maßnahmen-Sektion in `drawPage2`. Suche nach `"Maskenbeatmung"` oder `maskenbeatmung`. Füge nach dem Maskenbeatmung-Eintrag ein:

```swift
if p.massnahmen.maschinelleBeatmung {
    let beatTeile: [String] = [
        p.massnahmen.tidalvolumen.isEmpty ? nil : "TV \(p.massnahmen.tidalvolumen)ml",
        p.massnahmen.peep.isEmpty         ? nil : "PEEP \(p.massnahmen.peep)cmH₂O",
        p.massnahmen.fio2.isEmpty         ? nil : "FiO₂ \(p.massnahmen.fio2)%",
        p.massnahmen.beatmungsfrequenzMasch.isEmpty ? nil : "AF \(p.massnahmen.beatmungsfrequenzMasch)/min",
    ].compactMap { $0 }
    let beatStr = beatTeile.isEmpty ? "–" : beatTeile.joined(separator: " · ")
    maItems1.append(("Masch. Beatmung", true))
    // Beatmungsparameter als eigene Zeile:
    // (Lese die umgebende PDF-Logik, um das korrekte Rendering-Pattern zu verwenden)
}
```

> **Wichtig:** Lese die umgebende PDF-Logik für `maItems1` in `drawPage2`, bevor du editierst, um das korrekte Tuple-Format zu verstehen und die Parameter-Zeile korrekt zu rendern. Das Format ist wahrscheinlich `[(String, Bool)]` — wenn ja, füge nur `("Masch. Beatmung", p.massnahmen.maschinelleBeatmung)` zu `maItems1` hinzu, und render die Parameter separat als Freitext-Zeile.

- [ ] **Step 3: PDFGenerator — MANV Eigene SK**

In `PatProt/Services/PDFGenerator.swift`, finde die Zeile mit `"MANV\(ng.ersteEintreffendeKraft..."` (ca. Zeile 403). Ergänze die eigene SK:

Vorher (ungefähr):
```swift
? "MANV\(ng.ersteEintreffendeKraft ? " · 1. Eintreffend" : "") · \(ng.anzahlBeteiligte) Bet."
```

Nachher:
```swift
? "MANV\(ng.ersteEintreffendeKraft ? " · 1. Eintreffend" : "") · \(ng.anzahlBeteiligte) Bet.\(ng.manvEigeneSK.isEmpty ? "" : " · \(ng.manvEigeneSK)")"
```

- [ ] **Step 4: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests `passed`, 0 Fehler.

- [ ] **Step 5: Commit**

```bash
git add PatProt/Views/MassnahmenView.swift PatProt/Services/PDFGenerator.swift
git commit -m "feat: maschinelle Beatmung UI in MassnahmenView, MANV SK + Beatmung in PDF"
```

---

## Task 4: Medikamenten-Rechner

**Files:**
- Modify: `PatProt/Views/MedikamenteView.swift`

**Context:** `MedikamenteView` zeigt eine Liste von `MedikamentEintrag`. Füge:
1. `@EnvironmentObject private var protokoll: EinsatzProtokoll` hinzu (für Patientengewicht)
2. `@State private var zeigeRechner = false`
3. Einen Toolbar-Button "Rechner" der `MedikamentenRechnerSheet` als `.sheet` öffnet
4. `MedikamentenRechnerSheet` als privaten Struct am Ende der Datei

`PatientDaten.gewicht` ist `Double?` in kg.

- [ ] **Step 1: MedikamentenRechnerSheet implementieren**

Füge am Ende von `PatProt/Views/MedikamenteView.swift` (nach dem letzten `}`) ein:

```swift
// MARK: - Medikamenten-Rechner

private struct RechnerMed: Identifiable {
    let id = UUID()
    let name: String
    let dosisProKg: Double?
    let festDosis: Double?
    let einheit: String
    let route: String
    let maxDosis: Double?
}

private let rechnerMedikamente: [RechnerMed] = [
    RechnerMed(name: "Adrenalin (Anaphylaxie)", dosisProKg: 0.01, festDosis: nil,   einheit: "mg",  route: "i.m.", maxDosis: 0.5),
    RechnerMed(name: "Glucose 40%",              dosisProKg: nil,  festDosis: 20.0,  einheit: "g",   route: "i.v.", maxDosis: nil),
    RechnerMed(name: "ASS (ACS)",                dosisProKg: nil,  festDosis: 250.0, einheit: "mg",  route: "p.o.", maxDosis: nil),
    RechnerMed(name: "Nitro (Spray)",            dosisProKg: nil,  festDosis: 0.4,   einheit: "mg",  route: "s.l.", maxDosis: nil),
    RechnerMed(name: "Midazolam (Krampf)",       dosisProKg: 0.1,  festDosis: nil,   einheit: "mg",  route: "nasal", maxDosis: 10.0),
]

private struct MedikamentenRechnerSheet: View {
    let patientengewicht: Double?
    @State private var gewichtText: String
    @State private var auswahl: Int = 0
    @Environment(\.dismiss) private var dismiss

    init(patientengewicht: Double?) {
        self.patientengewicht = patientengewicht
        _gewichtText = State(initialValue: patientengewicht.map { String(format: "%.0f", $0) } ?? "")
    }

    private var gewicht: Double? { Double(gewichtText.replacingOccurrences(of: ",", with: ".")) }

    private var dosisText: String {
        let med = rechnerMedikamente[auswahl]
        if let pk = med.dosisProKg, let kg = gewicht {
            var d = pk * kg
            if let max = med.maxDosis { d = min(d, max) }
            return String(format: "%.2f %@ %@", d, med.einheit, med.route)
        } else if let fd = med.festDosis {
            return String(format: "%.0f %@ %@", fd, med.einheit, med.route)
        }
        return "–"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Gewicht (kg)")
                        Spacer()
                        TextField("kg", text: $gewichtText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: { Text("Patientengewicht") }

                Section {
                    Picker("Medikament", selection: $auswahl) {
                        ForEach(rechnerMedikamente.indices, id: \.self) { i in
                            Text(rechnerMedikamente[i].name).tag(i)
                        }
                    }
                    .pickerStyle(.inline)
                } header: { Text("Medikament") }

                Section {
                    HStack {
                        Text("Berechnete Dosis")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(dosisText)
                            .fontWeight(.bold)
                            .foregroundColor(Color("RDOrange"))
                    }
                    if rechnerMedikamente[auswahl].dosisProKg != nil && gewicht == nil {
                        Text("Gewicht eingeben für gewichtsbasierte Berechnung")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    if let max = rechnerMedikamente[auswahl].maxDosis {
                        Text("Max. \(String(format: "%.1f", max)) \(rechnerMedikamente[auswahl].einheit)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } header: { Text("Ergebnis") }
            }
            .navigationTitle("Medikamenten-Rechner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
```

- [ ] **Step 2: MedikamenteView einbinden**

In `MedikamenteView`:

1. Füge `@EnvironmentObject private var protokoll: EinsatzProtokoll` hinzu
2. Füge `@State private var zeigeRechner = false` hinzu
3. Füge `.toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { zeigeRechner = true } label: { Image(systemName: "function") } } }` zur Form hinzu
4. Füge `.sheet(isPresented: $zeigeRechner) { MedikamentenRechnerSheet(patientengewicht: protokoll.patientDaten.gewicht) }` zur Form hinzu

- [ ] **Step 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests `passed`, 0 Fehler.

- [ ] **Step 4: Commit**

```bash
git add PatProt/Views/MedikamenteView.swift
git commit -m "feat: add Medikamenten-Rechner sheet to MedikamenteView"
```
