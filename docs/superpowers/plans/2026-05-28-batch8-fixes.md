# Batch 8 — Quick Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four independent usability issues: NumpadSheet-Werte können gelöscht werden, NACA-Score erscheint nicht mehr doppelt, Einsatzzeiten-Reihenfolge korrigiert, Personal in Einstellungen bearbeitbar.

**Architecture:** Reine View-Fixes ohne Modell-Änderungen. Jeder Task ist vollständig unabhängig. Tests nur für NumpadSheet (da logisch testbar); View-Fixes über Build-Verifikation.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Testing (`@Test`, `#expect`), `xcodebuild test`

---

## Dateien

| Datei | Änderung |
|---|---|
| `PatProt/Views/NumpadSheet.swift` | `confirm()` default-case: leere Bestätigung erlauben |
| `PatProt/Views/NotfallgeschehenView.swift` | NACA-Section-Header entfernen |
| `PatProt/Views/EinsatzzeitenView.swift` | ZeitFeld-Reihenfolge + Validierung tauschen |
| `PatProt/Views/SettingsView.swift` | Personal tappbar + Bearbeiten-Sheet |
| `PatProtTests/PatProtTests.swift` | 1 neuer Test |

---

## Task 1: NumpadSheet — leere Bestätigung + Test

**Files:**
- Modify: `PatProt/Views/NumpadSheet.swift` (Zeile 147–149)
- Test: `PatProtTests/PatProtTests.swift`

**Context:** `NumpadSheet.confirm()` hat drei Fälle: `.bloodPressure`, `.time`, und `default`. Nur der `default`-Fall wird geändert. Zeile 147: `guard !digits.isEmpty else { return }` → entfernen, stattdessen leeren String an Callback übergeben.

- [ ] **Step 1: Test schreiben (failing)**

In `PatProtTests/PatProtTests.swift`, nach dem letzten `@Test`:

```swift
@Test func numpadFormatDisplayLeer() {
    // Leere digits → formatDisplay gibt "—" zurück
    let result = NumpadSheet.formatDisplay(digits: "", mode: .integer(label: "X", unit: "Y"))
    #expect(result == "—")
}
```

- [ ] **Step 2: Test ausführen — muss bestehen (formatDisplay ist bereits korrekt)**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "numpadFormatDisplayLeer|FAILED"
```

Erwartet: `numpadFormatDisplayLeer` passed. (Der Test ist grün, weil `formatDisplay` bereits `"—"` für leere Eingabe liefert — er dokumentiert das Verhalten.)

- [ ] **Step 3: NumpadSheet.swift — confirm() ändern**

In `PatProt/Views/NumpadSheet.swift`, Zeile 147–149, ersetze:

```swift
        default:
            guard !digits.isEmpty else { return }
            onConfirm(displayText)
            dismiss()
```

durch:

```swift
        default:
            onConfirm(digits.isEmpty ? "" : displayText)
            dismiss()
```

- [ ] **Step 4: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle 39 Tests `passed`, 0 Fehler.

- [ ] **Step 5: Commit**

```bash
git add PatProt/Views/NumpadSheet.swift PatProtTests/PatProtTests.swift
git commit -m "fix: allow empty NumpadSheet confirmation to clear optional values"
```

---

## Task 2: NACA doppelt — Section-Header entfernen

**Files:**
- Modify: `PatProt/Views/NotfallgeschehenView.swift` (Zeilen 94–96)

**Context:** In `NotfallgeschehenView`, Zeile 77–96: die NACA-`Section` hat einen `header: { Label("NACA-Score", ...) }`. Der Inline-Picker zeigt "NACA-Score" bereits selbst — der Header ist redundant.

- [ ] **Step 1: Section-Header entfernen**

In `PatProt/Views/NotfallgeschehenView.swift`, ersetze:

```swift
            } header: {
                Label("NACA-Score", systemImage: "chart.bar.fill")
            }
            Section {
                TextField("Ergänzungen / Sonstiges", text: $befund.notfallFreitext, axis: .vertical)
```

durch:

```swift
            }
            Section {
                TextField("Ergänzungen / Sonstiges", text: $befund.notfallFreitext, axis: .vertical)
```

- [ ] **Step 2: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests `passed`, 0 Fehler.

- [ ] **Step 3: Commit**

```bash
git add PatProt/Views/NotfallgeschehenView.swift
git commit -m "fix: remove duplicate NACA-Score section header in NotfallgeschehenView"
```

---

## Task 3: Einsatzzeiten Reihenfolge

**Files:**
- Modify: `PatProt/Views/EinsatzzeitenView.swift`

**Context:** `EinsatzzeitenView.swift` hat zwei zu ändernde Stellen:
1. Die ZeitFeld-Reihenfolge (Zeilen 29–32)
2. Die `zeitFehler` Validierungslogik (Zeilen 12–15)

`EinsatzOrtView.swift` hat bereits die richtige Reihenfolge (Abfahrt vor Übergabe) — dort keine Änderung nötig.

Feldnamen im Modell: `protokoll.einsatzOrt.abfahrtzeit` = "Einsatz Ende", `protokoll.einsatzOrt.krankenHausAnkunft` = "Übergabe an RD".

- [ ] **Step 1: ZeitFeld-Reihenfolge tauschen**

In `PatProt/Views/EinsatzzeitenView.swift`, ersetze Zeilen 29–32:

```swift
                ZeitFeld(label: "Alarmzeit",        datum: $protokoll.einsatzOrt.alarmzeit)
                ZeitFeld(label: "Ankunft Patient", datum: $protokoll.einsatzOrt.ankunftzeit)
                ZeitFeld(label: "Übergabe an RD",  datum: $protokoll.einsatzOrt.krankenHausAnkunft)
                ZeitFeld(label: "Einsatz Ende",    datum: $protokoll.einsatzOrt.abfahrtzeit)
```

durch:

```swift
                ZeitFeld(label: "Alarmzeit",        datum: $protokoll.einsatzOrt.alarmzeit)
                ZeitFeld(label: "Ankunft Patient",  datum: $protokoll.einsatzOrt.ankunftzeit)
                ZeitFeld(label: "Einsatz Ende",     datum: $protokoll.einsatzOrt.abfahrtzeit)
                ZeitFeld(label: "Übergabe an RD",   datum: $protokoll.einsatzOrt.krankenHausAnkunft)
```

- [ ] **Step 2: Zeitvalidierung anpassen**

In `PatProt/Views/EinsatzzeitenView.swift`, `zeitFehler` computed property, ersetze:

```swift
        if let a = ankunft,   let b = uebergabe, b < a { fehler.append("Übergabe liegt vor der Ankunft") }
        if let a = uebergabe, let b = ende,      b < a { fehler.append("Einsatz Ende liegt vor der Übergabe") }
```

durch:

```swift
        if let a = ankunft, let b = ende,      b < a { fehler.append("Einsatz Ende liegt vor der Ankunft") }
        if let a = ende,    let b = uebergabe, b < a { fehler.append("Übergabe liegt vor dem Einsatz Ende") }
```

- [ ] **Step 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests `passed`, 0 Fehler.

- [ ] **Step 4: Commit**

```bash
git add PatProt/Views/EinsatzzeitenView.swift
git commit -m "fix: swap Einsatz Ende and Übergabe order in EinsatzzeitenView"
```

---

## Task 4: Personal bearbeiten in SettingsView

**Files:**
- Modify: `PatProt/Views/SettingsView.swift`

**Context:** `SettingsView` hat bereits:
- `personal: [PersonalEintrag]` (computed, aus `personalJSON` AppStorage)
- `personalSpeichern(_ liste:)` Hilfsmethode
- `zeigePersonalHinzufuegen: Bool`, `neuerName: String`, `neueQualifikation: Qualifikation` State-Variablen
- Ein Hinzufügen-Sheet (`.sheet(isPresented: $zeigePersonalHinzufuegen)`)

Das `Fahrzeuge`-Bearbeiten-Pattern (Zeilen 102–128) als Vorlage: Einträge werden zu Buttons, Tap öffnet ein Sheet.

`PersonalEintrag` hat: `name: String`, `qualifikation: Qualifikation`.

- [ ] **Step 1: Neue State-Variablen hinzufügen**

In `SettingsView`, nach `@State private var neueQualifikation: Qualifikation = .rettungssanitaeter`:

```swift
    @State private var zeigePersonalBearbeiten = false
    @State private var bearbeitungsPersonIndex: Int? = nil
    @State private var bearbeitungsPersonName = ""
    @State private var bearbeitungsPersonQualifikation: Qualifikation = .rettungssanitaeter
```

- [ ] **Step 2: Personal-Einträge tappbar machen**

In `SettingsView`, die Personal-Section: ersetze den `ForEach`-Block (aktuell `ForEach(personal, id: \.self) { eintrag in HStack { ... } }`):

```swift
                ForEach(Array(personal.enumerated()), id: \.offset) { index, eintrag in
                    Button {
                        bearbeitungsPersonIndex = index
                        bearbeitungsPersonName = eintrag.name
                        bearbeitungsPersonQualifikation = eintrag.qualifikation
                        zeigePersonalBearbeiten = true
                    } label: {
                        HStack {
                            Label(eintrag.name, systemImage: "person")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(eintrag.qualifikation.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    var liste = personal
                    liste.remove(atOffsets: indexSet)
                    personalSpeichern(liste)
                }
```

- [ ] **Step 3: Footer-Text anpassen**

In der Personal-Section, den Footer-Text ersetzen:

```swift
// vorher:
Text("Namen werden beim Ausfüllen der Besatzung zur Auswahl angeboten. Mit Wischgeste löschen.")

// nachher:
Text("Antippen zum Bearbeiten. Wischgeste zum Löschen.")
```

- [ ] **Step 4: Bearbeiten-Sheet hinzufügen**

Nach dem bestehenden `.sheet(isPresented: $zeigePersonalHinzufuegen) { ... }` Block, ein weiteres Sheet anhängen:

```swift
        .sheet(isPresented: $zeigePersonalBearbeiten) {
            NavigationStack {
                Form {
                    Section("Name") {
                        TextField("Name", text: $bearbeitungsPersonName)
                    }
                    Section("Qualifikation") {
                        Picker("Qualifikation", selection: $bearbeitungsPersonQualifikation) {
                            ForEach(Qualifikation.allCases, id: \.self) { q in
                                Text(q.rawValue).tag(q)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }
                .navigationTitle("Person bearbeiten")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            let name = bearbeitungsPersonName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty, let idx = bearbeitungsPersonIndex else { return }
                            var liste = personal
                            guard idx < liste.count else { return }
                            liste[idx] = PersonalEintrag(name: name, qualifikation: bearbeitungsPersonQualifikation)
                            personalSpeichern(liste)
                            zeigePersonalBearbeiten = false
                            bearbeitungsPersonIndex = nil
                        }
                        .disabled(bearbeitungsPersonName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            zeigePersonalBearbeiten = false
                            bearbeitungsPersonIndex = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
```

- [ ] **Step 5: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle 39 Tests `passed`, 0 Fehler.

- [ ] **Step 6: Commit**

```bash
git add PatProt/Views/SettingsView.swift
git commit -m "feat: add edit functionality for saved personal in SettingsView"
```
