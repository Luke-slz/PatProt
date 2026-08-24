# Batch 13 — Maßnahmen in ABCDE-Ansicht

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Relevante aktive Maßnahmen in den ABCDE-Detailansichten einblenden, damit der Helfer nicht zwischen Views wechseln muss.

**Architecture:** Reine View-Änderungen. Vier ABCDE-Views bekommen einen neuen `massnahmen: MassnahmenBefund`-Parameter + eine read-only Section. ExposureView nutzt bereits `protokoll`. Acht Call-Sites werden aktualisiert.

**Tech Stack:** Swift 5.9, SwiftUI, `xcodebuild test`

---

## Dateien

| Datei | Änderung |
|---|---|
| `PatProt/Views/ABCDEDetailViews.swift` | 4 neue Parameter + 5 Maßnahmen-Sections |
| `PatProt/ContentView 2.swift` | 4 Call-Sites: `massnahmen: protokoll.massnahmen` |
| `PatProt/Views/iPadMainView.swift` | 4 Call-Sites: `massnahmen: protokoll.massnahmen` |

---

## Task 1: Maßnahmen-Parameter und Sections in ABCDEDetailViews

**Files:**
- Modify: `PatProt/Views/ABCDEDetailViews.swift`

**Context:**

Lese die Datei zunächst, um die exakten aktuellen Zeilennummern und Feldnamen zu prüfen. Bekannte Structs:
- `AirwayView` (~Zeile 85): `@Binding var befund: AirwayBefund; var onZurueck: () -> Void`
- `BreathingView` (~Zeile 139): `@Binding var befund: BreathingBefund; var onZurueck: () -> Void`
- `CirculationView` (~Zeile 287): `@Binding var befund: CirculationBefund; var onZurueck: () -> Void`
- `DisabilityView` (~Zeile 471): `@Binding var befund: DisabilityBefund; var onZurueck: () -> Void`
- `ExposureView` (~Zeile 690): `@ObservedObject var protokoll: EinsatzProtokoll; var onZurueck: () -> Void` — kein neuer Parameter!

`MassnahmenBefund`-Felder (verifiziere Namen in Models.swift):
- Bool: `atemwegFreimachen`, `cervikalStuetze`, `absaugung`, `guedelTubus`, `wendlTubus`, `supraglottisch`, `atemwegErschwert`, `heimlich`, `sauerstoffgabe`, `maskenbeatmung`, `maschinelleBeatmung`, `cpap`, `peripherVenoes`, `intraossaer`, `defibrillation`, `kardioversion`, `tourniquet`, `kuehlung`, `waermeerhalt`, `verband`, `beckenschlinge`, `extremitaetenschienung`, `vakuummatratze`, `monBz`, `monEkg`, `krisenintervention`
- String: `supraglottischTyp`, `sauerstoffLitMin`, `cpapMbar`, `peripherVenoesOrt`, `intraossaerOrt`

- [ ] **Step 1: AirwayView — Parameter + Section**

1a. Füge `var massnahmen: MassnahmenBefund` als zweite Property nach `@Binding var befund: AirwayBefund` hinzu (vor `var onZurueck`).

1b. Füge am Ende von `body` (vor dem letzten `.navigationTitle(...)` oder dem letzten `}` des Forms), diese Section ein:

```swift
            let airwayMassnahmen: [String] = {
                var items: [String] = []
                if massnahmen.atemwegFreimachen { items.append("Atemweg freimachen") }
                if massnahmen.cervikalStuetze   { items.append("Cervikalstütze") }
                if massnahmen.absaugung         { items.append("Absaugung") }
                if massnahmen.guedelTubus       { items.append("Guedel-Tubus (OPA)") }
                if massnahmen.wendlTubus        { items.append("Wendl-Tubus (NPA)") }
                if massnahmen.supraglottisch    {
                    let t = massnahmen.supraglottischTyp
                    items.append("Supraglottischer AW\(t.isEmpty ? "" : " (\(t))")")
                }
                if massnahmen.atemwegErschwert  { items.append("Erschwerter Atemweg") }
                if massnahmen.heimlich          { items.append("Heimlich-Manöver") }
                return items
            }()
            if !airwayMassnahmen.isEmpty {
                Section {
                    ForEach(airwayMassnahmen, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                } header: {
                    Label("Dokumentierte Maßnahmen", systemImage: "cross.fill")
                }
            }
```

- [ ] **Step 2: BreathingView — Parameter + Section**

2a. Füge `var massnahmen: MassnahmenBefund` nach `@Binding var befund: BreathingBefund` hinzu.

2b. Section am Ende des Forms:

```swift
            let breathingMassnahmen: [String] = {
                var items: [String] = []
                if massnahmen.sauerstoffgabe {
                    let l = massnahmen.sauerstoffLitMin
                    items.append("O₂\(l.isEmpty ? "" : " \(l) l/min")")
                }
                if massnahmen.maskenbeatmung      { items.append("Maskenbeatmung") }
                if massnahmen.maschinelleBeatmung { items.append("Maschinelle Beatmung") }
                if massnahmen.cpap {
                    let p = massnahmen.cpapMbar
                    items.append("CPAP\(p.isEmpty ? "" : " \(p) mbar")")
                }
                return items
            }()
            if !breathingMassnahmen.isEmpty {
                Section {
                    ForEach(breathingMassnahmen, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                } header: {
                    Label("Dokumentierte Maßnahmen", systemImage: "cross.fill")
                }
            }
```

- [ ] **Step 3: CirculationView — Parameter + Section**

3a. Füge `var massnahmen: MassnahmenBefund` nach `@Binding var befund: CirculationBefund` hinzu.

3b. Section am Ende des Forms:

```swift
            let circMassnahmen: [String] = {
                var items: [String] = []
                if massnahmen.peripherVenoes {
                    let o = massnahmen.peripherVenoesOrt
                    items.append("Peripher-venöser Zugang\(o.isEmpty ? "" : " (\(o))")")
                }
                if massnahmen.intraossaer {
                    let o = massnahmen.intraossaerOrt
                    items.append("Intraossärer Zugang\(o.isEmpty ? "" : " (\(o))")")
                }
                if massnahmen.defibrillation  { items.append("Defibrillation") }
                if massnahmen.kardioversion   { items.append("Kardioversion") }
                if massnahmen.tourniquet      { items.append("Tourniquet") }
                return items
            }()
            if !circMassnahmen.isEmpty {
                Section {
                    ForEach(circMassnahmen, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                } header: {
                    Label("Dokumentierte Maßnahmen", systemImage: "cross.fill")
                }
            }
```

- [ ] **Step 4: DisabilityView — Parameter + Section**

4a. Füge `var massnahmen: MassnahmenBefund` nach `@Binding var befund: DisabilityBefund` hinzu.

4b. Section am Ende des Forms:

```swift
            let disabilityMassnahmen: [String] = {
                var items: [String] = []
                if massnahmen.monBz              { items.append("BZ-Monitoring") }
                if massnahmen.monEkg             { items.append("EKG-Monitoring") }
                if massnahmen.krisenintervention { items.append("Krisenintervention") }
                return items
            }()
            if !disabilityMassnahmen.isEmpty {
                Section {
                    ForEach(disabilityMassnahmen, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                } header: {
                    Label("Dokumentierte Maßnahmen", systemImage: "cross.fill")
                }
            }
```

- [ ] **Step 5: ExposureView — Section (kein neuer Parameter)**

ExposureView hat bereits `@ObservedObject var protokoll: EinsatzProtokoll`. Nutze `protokoll.massnahmen` direkt.

Section am Ende des Forms:

```swift
            let exposureMassnahmen: [String] = {
                let m = protokoll.massnahmen
                var items: [String] = []
                if m.kuehlung               { items.append("Kühlung") }
                if m.waermeerhalt           { items.append("Wärmeerhalt") }
                if m.verband                { items.append("Verband") }
                if m.beckenschlinge         { items.append("Beckenschlinge") }
                if m.extremitaetenschienung { items.append("Extremitätenschienung") }
                if m.vakuummatratze         { items.append("Vakuummatratze") }
                return items
            }()
            if !exposureMassnahmen.isEmpty {
                Section {
                    ForEach(exposureMassnahmen, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                } header: {
                    Label("Dokumentierte Maßnahmen", systemImage: "cross.fill")
                }
            }
```

- [ ] **Step 6: Build prüfen (vor Call-Site-Updates)**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "error:|warning:.*massnahmen" | head -20
```

Erwartet: Fehler bei fehlenden `massnahmen`-Argumenten in call sites — das ist erwünscht (zeigt wo zu aktualisieren).

---

## Task 2: Call-Sites aktualisieren

**Files:**
- Modify: `PatProt/ContentView 2.swift`
- Modify: `PatProt/Views/iPadMainView.swift`

**Context:**
- `ContentView 2.swift` Zeilen 108, 113, 118, 123: `AirwayView(befund: ...)`, `BreathingView(befund: ...)`, `CirculationView(befund: ...)`, `DisabilityView(befund: ...)`
- `iPadMainView.swift` Zeilen 333, 337, 341, 345: selbe vier Views
- `protokoll` ist in beiden Dateien als `@ObservedObject` verfügbar

- [ ] **Step 1: ContentView 2.swift aktualisieren**

Für jeden der vier View-Aufrufe in `ContentView 2.swift`, füge `massnahmen: protokoll.massnahmen` als Argument hinzu:

```swift
// Zeile 108 — vorher:
AirwayView(befund: $protokoll.airway) { ... }
// nachher:
AirwayView(befund: $protokoll.airway, massnahmen: protokoll.massnahmen) { ... }

// Zeile 113 — vorher:
BreathingView(befund: $protokoll.breathing) { ... }
// nachher:
BreathingView(befund: $protokoll.breathing, massnahmen: protokoll.massnahmen) { ... }

// Zeile 118 — vorher:
CirculationView(befund: $protokoll.circulation) { ... }
// nachher:
CirculationView(befund: $protokoll.circulation, massnahmen: protokoll.massnahmen) { ... }

// Zeile 123 — vorher:
DisabilityView(befund: $protokoll.disability) { ... }
// nachher:
DisabilityView(befund: $protokoll.disability, massnahmen: protokoll.massnahmen) { ... }
```

- [ ] **Step 2: iPadMainView.swift aktualisieren**

Für die vier View-Aufrufe in `iPadMainView.swift` (Zeilen ~333, 337, 341, 345):

```swift
AirwayView(befund: $protokoll.airway, massnahmen: protokoll.massnahmen) { ... }
BreathingView(befund: $protokoll.breathing, massnahmen: protokoll.massnahmen) { ... }
CirculationView(befund: $protokoll.circulation, massnahmen: protokoll.massnahmen) { ... }
DisabilityView(befund: $protokoll.disability, massnahmen: protokoll.massnahmen) { ... }
```

- [ ] **Step 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed, 0 Fehler.

- [ ] **Step 4: Commit**

```bash
git add PatProt/Views/ABCDEDetailViews.swift "PatProt/ContentView 2.swift" PatProt/Views/iPadMainView.swift
git commit -m "feat: show relevant Maßnahmen summary in each ABCDE detail view"
```
