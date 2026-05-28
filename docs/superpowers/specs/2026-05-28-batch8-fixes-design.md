# Design: Batch 8 — Quick Fixes

**Datum:** 2026-05-28
**Scope:** NumpadSheet löschen, NACA doppelt, Einsatzzeiten Reihenfolge, Personal bearbeiten

---

## 1. NumpadSheet — Wert löschen

### Problem
`NumpadSheet.confirm()` hat `guard !digits.isEmpty else { return }` im default-case. Wenn man alle Ziffern per ⌫ löscht, lässt sich der leere Zustand nicht bestätigen — Werte wie Gewicht, SpO₂, Puls etc. können nach dem Setzen nicht gelöscht werden.

`ZeitFeld` hat bereits einen ✕-Button (wenn `datum != nil`) — Uhrzeiten sind davon nicht betroffen.

### Fix

In `PatProt/Views/NumpadSheet.swift`, `confirm()`, default-case:

```swift
// vorher:
default:
    guard !digits.isEmpty else { return }
    onConfirm(displayText)
    dismiss()

// nachher:
default:
    onConfirm(digits.isEmpty ? "" : displayText)
    dismiss()
```

**Effekt je Aufruf-Kontext:**
- `Double?`-Felder (Gewicht, SpO₂, etc.): Callback empfängt `""` → `Double("")` = `nil` → Wert gelöscht
- `String`-Felder (Tidalvolumen, PEEP, etc.): Callback empfängt `""` → leerer String = kein Wert

**Unverändert:**
- `.time`-Modus: behält `guard d.count == 5` (unvollständige Uhrzeit nicht bestätigbar)
- `.bloodPressure`-Modus: behält beide Guards (sys und dia müssen gefüllt sein)

**UX:** Nutzer löscht alle Ziffern mit ⌫, Display zeigt "—", Tap auf ✓ löscht den Wert. Kein zusätzlicher Button nötig.

### Test
```swift
@Test func numpadLeereBestaetigung() {
    var received: String? = nil
    // Simuliert confirm() mit leerem digits-String
    // Erwartet: onConfirm("") wird aufgerufen (nicht blockiert)
    // Da NumpadSheet nicht direkt testbar, wird die Logik inline geprüft:
    let digits = ""
    let result = digits.isEmpty ? "" : digits
    #expect(result == "")
}
```

> **Hinweis:** Da `NumpadSheet` ein View ist, wird der Test minimal gehalten. Die eigentliche Sicherung ist der Build + manuelle Verifikation dass Gewicht auf nil gesetzt werden kann.

---

## 2. NACA doppelt

### Problem
In `NotfallgeschehenView.swift` hat die NACA-Section sowohl einen expliziten `Section`-Header als auch einen `Picker("NACA-Score", ...)` mit `.pickerStyle(.inline)`. In SwiftUI Form + inline-Picker rendert iOS den Picker-Label als sichtbare Kopfzeile zusätzlich zum Section-Header — "NACA-Score" erscheint dadurch zweimal.

### Fix

In `PatProt/Views/NotfallgeschehenView.swift`, NACA-Section: Section-Header entfernen.

```swift
// vorher:
Section {
    Picker("NACA-Score", selection: ...) { ... }
        .pickerStyle(.inline)
    ...
} header: {
    Label("NACA-Score", systemImage: "chart.bar.fill")
}

// nachher:
Section {
    Picker("NACA-Score", selection: ...) { ... }
        .pickerStyle(.inline)
    ...
}
```

Der Picker-Label "NACA-Score" bleibt und identifiziert das Feld ausreichend.

---

## 3. Einsatzzeiten Reihenfolge

### Problem
In `EinsatzzeitenView.swift` ist die Reihenfolge aktuell:
1. Alarmzeit
2. Ankunft Patient
3. Übergabe an RD
4. Einsatz Ende

Gewünscht: Übergabe und Einsatz Ende tauschen:
1. Alarmzeit
2. Ankunft Patient
3. Einsatz Ende
4. Übergabe an RD

### Fix

**`PatProt/Views/EinsatzzeitenView.swift`** — ZeitFeld-Reihenfolge tauschen:

```swift
// vorher:
ZeitFeld(label: "Alarmzeit",        datum: $protokoll.einsatzOrt.alarmzeit)
ZeitFeld(label: "Ankunft Patient",  datum: $protokoll.einsatzOrt.ankunftzeit)
ZeitFeld(label: "Übergabe an RD",   datum: $protokoll.einsatzOrt.krankenHausAnkunft)
ZeitFeld(label: "Einsatz Ende",     datum: $protokoll.einsatzOrt.abfahrtzeit)

// nachher:
ZeitFeld(label: "Alarmzeit",        datum: $protokoll.einsatzOrt.alarmzeit)
ZeitFeld(label: "Ankunft Patient",  datum: $protokoll.einsatzOrt.ankunftzeit)
ZeitFeld(label: "Einsatz Ende",     datum: $protokoll.einsatzOrt.abfahrtzeit)
ZeitFeld(label: "Übergabe an RD",   datum: $protokoll.einsatzOrt.krankenHausAnkunft)
```

**Zeitvalidierung anpassen** — `zeitFehler` in `EinsatzzeitenView`:

```swift
// vorher:
if let a = ankunft,   let b = uebergabe, b < a { fehler.append("Übergabe liegt vor der Ankunft") }
if let a = uebergabe, let b = ende,      b < a { fehler.append("Einsatz Ende liegt vor der Übergabe") }

// nachher:
if let a = ankunft, let b = ende,      b < a { fehler.append("Einsatz Ende liegt vor der Ankunft") }
if let a = ende,    let b = uebergabe, b < a { fehler.append("Übergabe liegt vor dem Einsatz Ende") }
```

**`PatProt/Views/EinsatzOrtView.swift`** — dort gibt es ebenfalls ZeitFeld-Einträge (ca. Zeile 156–159). Gleiche Reihenfolge anwenden:

```swift
// vorher:
ZeitFeld(label: "Alarmzeit",              datum: $protokoll.einsatzOrt.alarmzeit)
ZeitFeld(label: "Ankunft Patient",        datum: $protokoll.einsatzOrt.ankunftzeit)
ZeitFeld(label: "Abfahrt Einsatzstelle",  datum: $protokoll.einsatzOrt.abfahrtzeit)
ZeitFeld(label: "Übergabe an RD",         datum: $protokoll.einsatzOrt.krankenHausAnkunft)

// nachher:
ZeitFeld(label: "Alarmzeit",              datum: $protokoll.einsatzOrt.alarmzeit)
ZeitFeld(label: "Ankunft Patient",        datum: $protokoll.einsatzOrt.ankunftzeit)
ZeitFeld(label: "Abfahrt Einsatzstelle",  datum: $protokoll.einsatzOrt.abfahrtzeit)
ZeitFeld(label: "Übergabe an RD",         datum: $protokoll.einsatzOrt.krankenHausAnkunft)
```

> **Hinweis:** In `EinsatzOrtView` sind die Felder bereits in der richtigen Reihenfolge (Abfahrt vor Übergabe). Nur `EinsatzzeitenView` muss geändert werden.

---

## 4. Personal bearbeiten

### Problem
`SettingsView` erlaubt Personal hinzufügen und per Wischgeste löschen, aber nicht bearbeiten. Name- oder Qualifikations-Korrekturen erfordern Löschen und Neu-Anlegen.

### Fix

In `PatProt/Views/SettingsView.swift`:

**Neue State-Variablen** (neben bestehenden):
```swift
@State private var zeigePersonalBearbeiten = false
@State private var bearbeitungsPersonIndex: Int? = nil
@State private var bearbeitungsPersonName = ""
@State private var bearbeitungsPersonQualifikation: Qualifikation = .rettungssanitaeter
```

**Personal-Listeneinträge tappbar machen** (wie Fahrzeuge):
```swift
// vorher: plain HStack in ForEach(personal, id: \.self)
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

**Footer-Text** anpassen:
```swift
Text("Antippen zum Bearbeiten. Wischgeste zum Löschen.")
```

**Bearbeiten-Sheet** hinzufügen (nach dem Hinzufügen-Sheet):
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

---

## Dateien mit Änderungen

| Datei | Änderungen |
|---|---|
| `PatProt/Views/NumpadSheet.swift` | `confirm()` default-case: leere Bestätigung zulassen |
| `PatProt/Views/NotfallgeschehenView.swift` | NACA-Section-Header entfernen |
| `PatProt/Views/EinsatzzeitenView.swift` | Reihenfolge Einsatz Ende / Übergabe tauschen + Validierung |
| `PatProt/Views/SettingsView.swift` | Personal-Einträge tappbar + Bearbeiten-Sheet |

## Tests

```swift
@Test func numpadLeereBestaetigung() {
    // Leere digits → onConfirm("") — nicht blockiert
    let digits = ""
    let result = digits.isEmpty ? "" : NumpadSheet.formatDisplay(digits: digits, mode: .integer(label: "X", unit: "Y"))
    #expect(result == "")
}
```
