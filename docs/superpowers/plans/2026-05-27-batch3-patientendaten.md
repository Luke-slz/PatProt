# Batch 3 — Patientendaten Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Krankenkasse im PDF ausgeben, Qualifikation je Besatzungsmitglied in Einstellungen + Picker, KV-Karten-Foto aufnehmen, Einsatzort um PLZ und Stadt erweitern.

**Architecture:** Vier isolierte Änderungen, die sich auf Models, Settings, Views und PDF verteilen. Jede Änderung ist rückwärtskompatibel. Fotos bleiben session-only (kein Archiv). PersonalEintrag ersetzt den bisherigen String-Array mit Migration.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Testing (`@Test`, `#expect`), `xcodebuild`

---

## File Structure

| Datei | Änderungen |
|---|---|
| `PatProt/Models/Models.swift` | `plz`/`ort` in `EinsatzOrt`; `Qualifikation`-Enum; `PersonalEintrag`-Struct; `kvFotos` in `EinsatzProtokoll.reset()` |
| `PatProt/LocationManager.swift` | `street`, `postalCode`, `city` als separate `@Published`-Properties |
| `PatProt/Views/SettingsView.swift` | `[String]` → `[PersonalEintrag]` + Migration + Sheet statt Alert |
| `PatProt/Views/EinsatzOrtView.swift` | PLZ/Ort-Felder; LocationManager onChange; `BesatzungsFeld`/`PersonalPickerSheet` Qualifikation; KV-Foto-Button + Thumbnail |
| `PatProt/Services/PDFGenerator.swift` | Krankenkasse-Feld; PLZ/Ort in adresseText; `kvFotos`-Gruppe in `drawFotoPages` |
| `PatProtTests/PatProtTests.swift` | 3 neue Tests |

---

### Task 1: Datenmodell (Models.swift + Tests)

**Files:**
- Modify: `PatProt/Models/Models.swift`
- Test: `PatProtTests/PatProtTests.swift`

Kontext: `EinsatzOrt` (Zeile ~188) bekommt `plz` und `ort`. Neue Typen `Qualifikation` (enum) und `PersonalEintrag` (struct) kommen vor dem `// MARK: - Models`-Kommentar. `EinsatzProtokoll` (Klasse, Zeile ~90) bekommt `@Published var kvFotos: [FotoEintrag] = []` analog zu `medikamentFotos`. `reset()` löscht `kvFotos` analog zu `medikamentFotos`. `ProtokollDaten` und `apply(from:)` brauchen keine Änderung — Fotos werden nicht archiviert.

- [ ] **Step 1: Tests schreiben**

In `PatProtTests/PatProtTests.swift`, drei neue Tests zur `PatProtTests`-Struct hinzufügen:

```swift
@Test func einsatzOrtHatPlzUndOrt() {
    let ort = EinsatzOrt()
    #expect(ort.plz == "")
    #expect(ort.ort == "")
}

@Test func personalEintragMigration() {
    // Old format: [String] JSON
    let altJSON = "[\"Max Muster\",\"Jane Doe\"]"
    let data = Data(altJSON.utf8)!
    // Must fail to decode as [PersonalEintrag]
    let alsPE = try? JSONDecoder().decode([PersonalEintrag].self, from: data)
    #expect(alsPE == nil)
    // Must succeed via String migration
    let alsStrings = (try? JSONDecoder().decode([String].self, from: data)) ?? []
    let migriert = alsStrings.map { PersonalEintrag(name: $0, qualifikation: .rettungssanitaeter) }
    #expect(migriert.count == 2)
    #expect(migriert[0].name == "Max Muster")
    #expect(migriert[0].qualifikation == .rettungssanitaeter)
}

@Test func kvFotosResetLeert() {
    let protokoll = EinsatzProtokoll()
    protokoll.kvFotos.append(FotoEintrag(bildDateiname: "test.jpg"))
    protokoll.reset()
    #expect(protokoll.kvFotos.isEmpty)
}
```

- [ ] **Step 2: Tests laufen lassen — müssen fehlschlagen**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E 'Test Suite|passed|failed|error:'
```

Erwartet: Die drei neuen Tests schlagen fehl (Typen existieren noch nicht).

- [ ] **Step 3: `plz` und `ort` zu `EinsatzOrt` hinzufügen**

In `PatProt/Models/Models.swift`, `struct EinsatzOrt`, nach `var zusatz = ""`:

```swift
struct EinsatzOrt: Codable {
    var adresse = ""
    var zusatz = ""
    var plz = ""       // <-- NEU
    var ort = ""       // <-- NEU
    var einsatzArt = ""
    // ... Rest unverändert
}
```

- [ ] **Step 4: `Qualifikation`-Enum und `PersonalEintrag`-Struct hinzufügen**

In `PatProt/Models/Models.swift`, direkt vor `enum ProtokollVerfasser` (Zeile 79):

```swift
enum Qualifikation: String, CaseIterable, Codable {
    case ersthelfer         = "EH"
    case ersthelferE        = "EH-E"
    case rettungssanitaeter = "RS"
    case rettungsassistent  = "RA"
    case notfallsanitaeter  = "NotSan"
    case arzt               = "Arzt"
}

struct PersonalEintrag: Codable, Hashable {
    var name: String
    var qualifikation: Qualifikation = .rettungssanitaeter
}

```

- [ ] **Step 5: `kvFotos` in `EinsatzProtokoll` hinzufügen**

In `PatProt/Models/Models.swift`, `class EinsatzProtokoll`, nach `@Published var medikamentFotos: [FotoEintrag] = []`:

```swift
    // Medikamentenplan-Fotos (in-app only, nicht archiviert)
    @Published var medikamentFotos: [FotoEintrag] = []

    // KV-Karten-Foto (in-app only, nicht archiviert)
    @Published var kvFotos: [FotoEintrag] = []    // <-- NEU
```

- [ ] **Step 6: `reset()` um `kvFotos` erweitern**

In `PatProt/Models/Models.swift`, `func reset()`, nach den `medikamentFotos`-Zeilen:

```swift
        medikamentFotos.forEach { $0.loeschen() }
        medikamentFotos = []
        kvFotos.forEach { $0.loeschen() }    // <-- NEU
        kvFotos = []                          // <-- NEU
```

- [ ] **Step 7: Build prüfen**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E 'error:|Build succeeded|Build FAILED'
```

Erwartet: `Build succeeded`

- [ ] **Step 8: Tests laufen lassen — müssen grün sein**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E 'Test Suite|passed|failed|error:'
```

Erwartet: alle Tests grün (mind. 21 passing)

- [ ] **Step 9: Commit**

```bash
git add PatProt/Models/Models.swift PatProtTests/PatProtTests.swift
git commit -m "feat: add plz/ort to EinsatzOrt, Qualifikation enum, PersonalEintrag struct, kvFotos to EinsatzProtokoll"
```

---

### Task 2: SettingsView — PersonalEintrag + Qualifikation-Sheet

**Files:**
- Modify: `PatProt/Views/SettingsView.swift`

Kontext: `SettingsView` speichert Personal als `[String]` JSON via `@AppStorage("gespeichertesPersonal")`. Der Wechsel auf `[PersonalEintrag]` braucht eine Migration. Das "Person hinzufügen"-Alert wird zu einem Sheet, weil System-Alerts keinen `Picker` unterstützen.

- [ ] **Step 1: `personal`-Property + `personalSpeichern` ersetzen**

In `PatProt/Views/SettingsView.swift`, die beiden Funktionen ersetzen (Zeilen 20–26):

```swift
// Vorher:
private var personal: [String] {
    (try? JSONDecoder().decode([String].self, from: Data(personalJSON.utf8))) ?? []
}

private func personalSpeichern(_ liste: [String]) {
    personalJSON = (try? String(data: JSONEncoder().encode(liste), encoding: .utf8)) ?? "[]"
}

// Nachher:
private var personal: [PersonalEintrag] {
    guard let data = Data(personalJSON.utf8) else { return [] }
    if let liste = try? JSONDecoder().decode([PersonalEintrag].self, from: data) { return liste }
    // Migration: alter [String]-Format
    if let namen = try? JSONDecoder().decode([String].self, from: data) {
        return namen.map { PersonalEintrag(name: $0, qualifikation: .rettungssanitaeter) }
    }
    return []
}

private func personalSpeichern(_ liste: [PersonalEintrag]) {
    personalJSON = (try? String(data: JSONEncoder().encode(liste), encoding: .utf8)) ?? "[]"
}
```

- [ ] **Step 2: State-Variable für Qualifikation hinzufügen**

In `PatProt/Views/SettingsView.swift`, nach `@State private var neuerName = ""`:

```swift
    @State private var neuerName = ""
    @State private var neueQualifikation: Qualifikation = .rettungssanitaeter    // <-- NEU
```

- [ ] **Step 3: ForEach in Personal-Section updaten**

In `PatProt/Views/SettingsView.swift`, die ForEach-Schleife im Personal-Section (Zeilen 64–72):

```swift
// Vorher:
ForEach(personal, id: \.self) { person in
    Label(person, systemImage: "person")
        .foregroundStyle(.primary)
}
.onDelete { indexSet in
    var liste = personal
    liste.remove(atOffsets: indexSet)
    personalSpeichern(liste)
}

// Nachher:
ForEach(personal, id: \.self) { eintrag in
    HStack {
        Label(eintrag.name, systemImage: "person")
            .foregroundStyle(.primary)
        Spacer()
        Text(eintrag.qualifikation.rawValue)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
.onDelete { indexSet in
    var liste = personal
    liste.remove(atOffsets: indexSet)
    personalSpeichern(liste)
}
```

- [ ] **Step 4: Button "Person hinzufügen" anpassen**

In `PatProt/Views/SettingsView.swift`, der Button-Action (Zeile ~74):

```swift
// Vorher:
Button {
    neuerName = ""
    zeigePersonalHinzufuegen = true
} label: {
    Label("Person hinzufügen", systemImage: "plus.circle")
}

// Nachher:
Button {
    neuerName = ""
    neueQualifikation = .rettungssanitaeter
    zeigePersonalHinzufuegen = true
} label: {
    Label("Person hinzufügen", systemImage: "plus.circle")
}
```

- [ ] **Step 5: Alert durch Sheet ersetzen**

In `PatProt/Views/SettingsView.swift`, das `.alert("Person hinzufügen", ...)` entfernen und durch ein `.sheet` ersetzen. Die bestehenden Zeilen:

```swift
.alert("Person hinzufügen", isPresented: $zeigePersonalHinzufuegen) {
    TextField("Name", text: $neuerName)
    Button("Hinzufügen") {
        let name = neuerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        var liste = personal
        liste.append(name)
        personalSpeichern(liste)
    }
    Button("Abbrechen", role: .cancel) {}
}
```

ersetzen durch:

```swift
.sheet(isPresented: $zeigePersonalHinzufuegen) {
    NavigationStack {
        Form {
            Section("Name") {
                TextField("Name", text: $neuerName)
            }
            Section("Qualifikation") {
                Picker("Qualifikation", selection: $neueQualifikation) {
                    ForEach(Qualifikation.allCases, id: \.self) { q in
                        Text(q.rawValue).tag(q)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
        .navigationTitle("Person hinzufügen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Hinzufügen") {
                    let name = neuerName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    var liste = personal
                    liste.append(PersonalEintrag(name: name, qualifikation: neueQualifikation))
                    personalSpeichern(liste)
                    zeigePersonalHinzufuegen = false
                }
                .disabled(neuerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { zeigePersonalHinzufuegen = false }
            }
        }
    }
    .presentationDetents([.medium])
}
```

- [ ] **Step 6: Build prüfen**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E 'error:|Build succeeded|Build FAILED'
```

Erwartet: `Build succeeded`

- [ ] **Step 7: Commit**

```bash
git add PatProt/Views/SettingsView.swift
git commit -m "feat: upgrade personal list to PersonalEintrag with Qualifikation picker"
```

---

### Task 3: LocationManager + EinsatzOrtView PLZ/Ort

**Files:**
- Modify: `PatProt/LocationManager.swift`
- Modify: `PatProt/Views/EinsatzOrtView.swift`

Kontext: `LocationManager` publiziert aktuell nur `address` als vollständigen String ("Hauptstraße 12, 21502 Geesthacht"). Wir fügen `street`, `postalCode` und `city` als separate `@Published`-Properties hinzu. `address` bleibt unverändert (KonfigurationView nutzt ihn). In `EinsatzOrtView` werden PLZ/Ort-Felder eingebaut und der `onChange`-Handler erweitert.

- [ ] **Step 1: Neue `@Published`-Properties in LocationManager hinzufügen**

In `PatProt/LocationManager.swift`, nach `@Published var address: String = ""`:

```swift
    @Published var address: String = ""
    @Published var street: String = ""       // <-- NEU: nur Straße + Hausnummer
    @Published var postalCode: String = ""   // <-- NEU
    @Published var city: String = ""         // <-- NEU
```

- [ ] **Step 2: Geocoder-Callback in LocationManager erweitern**

In `PatProt/LocationManager.swift`, den Block wo `self.address` gesetzt wird (Zeilen ~40–44):

```swift
// Vorher:
let street = placemark.thoroughfare ?? ""
let number = placemark.subThoroughfare ?? ""
let postalCode = placemark.postalCode ?? ""
let city = placemark.locality ?? ""
self.address = "\(street) \(number), \(postalCode) \(city)"

// Nachher:
let streetName = placemark.thoroughfare ?? ""
let number = placemark.subThoroughfare ?? ""
let pc = placemark.postalCode ?? ""
let c = placemark.locality ?? ""
let streetFull = [streetName, number].filter { !$0.isEmpty }.joined(separator: " ")
self.street = streetFull
self.postalCode = pc
self.city = c
self.address = [streetFull, [pc, c].filter { !$0.isEmpty }.joined(separator: " ")]
    .filter { !$0.isEmpty }.joined(separator: ", ")
```

- [ ] **Step 3: PLZ- und Ort-Textfelder in EinsatzOrtView hinzufügen**

In `PatProt/Views/EinsatzOrtView.swift`, Einsatzort-Section, nach `TextField("Zusatz (Stockwerk, Wohnung...)", ...)`:

```swift
            TextField("Straße und Hausnummer", text: $protokoll.einsatzOrt.adresse)
            TextField("Zusatz (Stockwerk, Wohnung...)", text: $protokoll.einsatzOrt.zusatz)
            HStack(spacing: 8) {                                    // <-- NEU
                TextField("PLZ", text: $protokoll.einsatzOrt.plz)   // <-- NEU
                    .keyboardType(.numberPad)                        // <-- NEU
                    .frame(maxWidth: 90)                             // <-- NEU
                TextField("Ort / Stadt", text: $protokoll.einsatzOrt.ort) // <-- NEU
            }                                                       // <-- NEU
```

- [ ] **Step 4: `onChange`-Handler für LocationManager aktualisieren**

In `PatProt/Views/EinsatzOrtView.swift`, den bestehenden `onChange(of: locationManager.address)` Block (Zeile ~231):

```swift
// Vorher:
.onChange(of: locationManager.address) { _, newAddress in
    if !newAddress.isEmpty {
        protokoll.einsatzOrt.adresse = newAddress
    }
}

// Nachher:
.onChange(of: locationManager.address) { _, newAddress in
    if !newAddress.isEmpty {
        if !locationManager.street.isEmpty {
            protokoll.einsatzOrt.adresse = locationManager.street
            protokoll.einsatzOrt.plz = locationManager.postalCode
            protokoll.einsatzOrt.ort = locationManager.city
        } else {
            // Fallback: GPS-Koordinaten (kein Placemark verfügbar)
            protokoll.einsatzOrt.adresse = newAddress
        }
    }
}
```

- [ ] **Step 5: Build prüfen**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E 'error:|Build succeeded|Build FAILED'
```

Erwartet: `Build succeeded`

- [ ] **Step 6: Commit**

```bash
git add PatProt/LocationManager.swift PatProt/Views/EinsatzOrtView.swift
git commit -m "feat: add PLZ/Ort fields to EinsatzOrtView, split LocationManager address into components"
```

---

### Task 4: BesatzungsFeld + PersonalPickerSheet — Qualifikation

**Files:**
- Modify: `PatProt/Views/EinsatzOrtView.swift`

Kontext: `BesatzungsFeld` (Zeile ~291) und `PersonalPickerSheet` (Zeile ~322) arbeiten bisher mit `[String]`. Sie müssen auf `[PersonalEintrag]` umgestellt werden — inklusive Migration. `PersonalPickerSheet` soll beim Antippen `"Name (Qual)"` in das Besatzungsfeld eintragen.

`EinsatzOrtView` hat außerdem eine eigene `gespeichertesPersonal: [String]`-Property (Zeile ~42) für den Footer-Check — auch diese wird auf `[PersonalEintrag]` umgestellt.

- [ ] **Step 1: `EinsatzOrtView.gespeichertesPersonal` auf `[PersonalEintrag]` umstellen**

In `PatProt/Views/EinsatzOrtView.swift`, die `gespeichertesPersonal`-Property (Zeile ~42):

```swift
// Vorher:
private var gespeichertesPersonal: [String] {
    (try? JSONDecoder().decode([String].self, from: Data(personalJSON.utf8))) ?? []
}

// Nachher:
private var gespeichertesPersonal: [PersonalEintrag] {
    guard let data = Data(personalJSON.utf8) else { return [] }
    if let liste = try? JSONDecoder().decode([PersonalEintrag].self, from: data) { return liste }
    if let namen = try? JSONDecoder().decode([String].self, from: data) {
        return namen.map { PersonalEintrag(name: $0, qualifikation: .rettungssanitaeter) }
    }
    return []
}
```

- [ ] **Step 2: `BesatzungsFeld.personal` auf `[PersonalEintrag]` umstellen**

In `PatProt/Views/EinsatzOrtView.swift`, `struct BesatzungsFeld`, die `personal`-Property:

```swift
// Vorher:
private var personal: [String] {
    (try? JSONDecoder().decode([String].self, from: Data(personalJSON.utf8))) ?? []
}

// Nachher:
private var personal: [PersonalEintrag] {
    guard let data = Data(personalJSON.utf8) else { return [] }
    if let liste = try? JSONDecoder().decode([PersonalEintrag].self, from: data) { return liste }
    if let namen = try? JSONDecoder().decode([String].self, from: data) {
        return namen.map { PersonalEintrag(name: $0, qualifikation: .rettungssanitaeter) }
    }
    return []
}
```

Auch den Sheet-Aufruf in `BesatzungsFeld.body` anpassen:

```swift
// Vorher:
.sheet(isPresented: $zeigePickerSheet) {
    PersonalPickerSheet(ausgewählt: $text, personal: personal)
}

// Nachher:
.sheet(isPresented: $zeigePickerSheet) {
    PersonalPickerSheet(ausgewählt: $text, personal: personal)
}
// (kein Unterschied im Aufruf — PersonalPickerSheet-Signatur ändert sich in Step 3)
```

- [ ] **Step 3: `PersonalPickerSheet` auf `[PersonalEintrag]` umstellen**

In `PatProt/Views/EinsatzOrtView.swift`, `struct PersonalPickerSheet`:

```swift
// Vorher:
struct PersonalPickerSheet: View {
    @Binding var ausgewählt: String
    let personal: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var manuell = ""

    var body: some View {
        NavigationStack {
            List {
                if !personal.isEmpty {
                    Section("Gespeichertes Personal") {
                        ForEach(personal, id: \.self) { person in
                            Button {
                                ausgewählt = person
                                dismiss()
                            } label: {
                                HStack {
                                    Text(person)
                                    Spacer()
                                    if ausgewählt == person {
                                        Image(systemName: "checkmark").foregroundStyle(Color("RDOrange"))
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
```

```swift
// Nachher:
struct PersonalPickerSheet: View {
    @Binding var ausgewählt: String
    let personal: [PersonalEintrag]
    @Environment(\.dismiss) private var dismiss
    @State private var manuell = ""

    var body: some View {
        NavigationStack {
            List {
                if !personal.isEmpty {
                    Section("Gespeichertes Personal") {
                        ForEach(personal, id: \.self) { eintrag in
                            let anzeige = "\(eintrag.name) (\(eintrag.qualifikation.rawValue))"
                            Button {
                                ausgewählt = anzeige
                                dismiss()
                            } label: {
                                HStack {
                                    Text(eintrag.name)
                                    Spacer()
                                    Text(eintrag.qualifikation.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if ausgewählt == anzeige {
                                        Image(systemName: "checkmark").foregroundStyle(Color("RDOrange"))
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
```

Den Rest der `PersonalPickerSheet` unverändert lassen (manuell-Eingabe-Section, NavigationTitle etc.).

- [ ] **Step 4: Build prüfen**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E 'error:|Build succeeded|Build FAILED'
```

Erwartet: `Build succeeded`

- [ ] **Step 5: Commit**

```bash
git add PatProt/Views/EinsatzOrtView.swift
git commit -m "feat: upgrade BesatzungsFeld and PersonalPickerSheet to use PersonalEintrag with Qualifikation"
```

---

### Task 5: KV-Karten-Foto (EinsatzOrtView)

**Files:**
- Modify: `PatProt/Views/EinsatzOrtView.swift`

Kontext: Analog zu `BilderView.swift` wird in der Patienten-Section ein Foto-Button ergänzt. `KameraController` und `PHBilderPicker` sind bereits in `BilderView.swift` definiert und im selben Target — können direkt benutzt werden. Maximal 1 KV-Foto: beim Speichern wird das alte zuerst gelöscht.

- [ ] **Step 1: @State-Variablen in `EinsatzOrtView` hinzufügen**

In `PatProt/Views/EinsatzOrtView.swift`, nach `@State private var zeigeGeburtsdatumNumpad = false`:

```swift
    @State private var zeigeKVKameraAuswahl = false    // <-- NEU
    @State private var zeigeKVKamera = false            // <-- NEU
    @State private var zeigeKVBibliothek = false        // <-- NEU
```

- [ ] **Step 2: KV-Foto-Button und Thumbnail in Patient-Section einfügen**

In `PatProt/Views/EinsatzOrtView.swift`, Patient-Section, nach `TextField("Kostenträger / Krankenkasse", ...)`:

```swift
            TextField("Kostenträger / Krankenkasse", text: $protokoll.patientDaten.kostentraeger)
            // KV-Foto — NEU ab hier
            Button {
                zeigeKVKameraAuswahl = true
            } label: {
                Label(
                    protokoll.kvFotos.isEmpty ? "KV-Karte fotografieren" : "KV-Karte ersetzen",
                    systemImage: "creditcard.viewfinder"
                )
                .foregroundStyle(Color("RDOrange"))
            }
            .buttonStyle(.plain)
            if let foto = protokoll.kvFotos.first,
               let img = UIImage(contentsOfFile: foto.bildURL.path) {
                HStack {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .cornerRadius(6)
                    Spacer()
                    Button(role: .destructive) {
                        foto.loeschen()
                        protokoll.kvFotos = []
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                }
            }
```

- [ ] **Step 3: `kvFotoHinzufuegen`-Funktion zu `EinsatzOrtView` hinzufügen**

Am Ende von `struct EinsatzOrtView` (vor der schließenden `}`), nach den bestehenden `private` Funktionen/Properties:

```swift
    private func kvFotoHinzufuegen(_ bild: UIImage) {
        protokoll.kvFotos.forEach { $0.loeschen() }
        protokoll.kvFotos = []
        guard let data = bild.jpegData(compressionQuality: 0.7) else { return }
        let dateiname = "kvfoto_\(UUID().uuidString).jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(dateiname)
        guard (try? data.write(to: url, options: [.atomicWrite, .completeFileProtection])) != nil else { return }
        protokoll.kvFotos.append(FotoEintrag(bildDateiname: dateiname))
    }
```

- [ ] **Step 4: `.confirmationDialog` und `.sheet` für KV-Foto hinzufügen**

In `PatProt/Views/EinsatzOrtView.swift`, die bestehenden Modifier-Kette auf dem Form (dort wo `.sheet`, `.toolbar` etc. sind), neue Modifier hinzufügen:

```swift
        .confirmationDialog("KV-Karte hinzufügen", isPresented: $zeigeKVKameraAuswahl) {
            Button("Kamera") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    zeigeKVKamera = true
                }
            }
            Button("Aus Fotoauswahl") { zeigeKVBibliothek = true }
            Button("Abbrechen", role: .cancel) {}
        }
        .sheet(isPresented: $zeigeKVKamera) {
            KameraController(onCapture: { bild in
                kvFotoHinzufuegen(bild)
                zeigeKVKamera = false
            }, onAbbrechen: { zeigeKVKamera = false })
        }
        .sheet(isPresented: $zeigeKVBibliothek) {
            PHBilderPicker { bild in
                kvFotoHinzufuegen(bild)
                zeigeKVBibliothek = false
            }
        }
```

- [ ] **Step 5: Build prüfen**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E 'error:|Build succeeded|Build FAILED'
```

Erwartet: `Build succeeded`

- [ ] **Step 6: Commit**

```bash
git add PatProt/Views/EinsatzOrtView.swift
git commit -m "feat: add KV-Karten-Foto button and thumbnail to patient section"
```

---

### Task 6: PDFGenerator — Krankenkasse + PLZ/Ort + KV-Foto

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift`

Kontext: Drei unabhängige Änderungen in `drawPage1` und `drawFotoPages`:
1. Krankenkasse-Feld nach Versicherungsnummer/Gewicht (linke Patientenspalte)
2. `adresseText` um PLZ/Ort erweitern (rechte Section-1-Spalte, Zeile ~361)
3. `drawFotoPages` bekommt `kvFotos`-Parameter und eine dritte Gruppe

Kein neuer Unit-Test möglich für PDF-Rendering — visuell testen via PDF-Export.

- [ ] **Step 1: Krankenkasse-Feld in linker Patientenspalte hinzufügen**

In `PatProt/Services/PDFGenerator.swift`, `drawPage1`, im `do`-Block der linken Patientenspalte. Die bestehenden letzten beiden Zeilen des Blocks:

```swift
            let gewStr = p.patientDaten.gewicht.map { String(format: "%.0f kg", $0) } ?? ""
            field("Gewicht", gewStr, x:x+fw2, y:y+26, w:fw2, h:12, lw:fw2*0.5)
```

werden zu:

```swift
            let gewStr = p.patientDaten.gewicht.map { String(format: "%.0f kg", $0) } ?? ""
            field("Gewicht", gewStr, x:x+fw2, y:y+26, w:fw2, h:12, lw:fw2*0.5)
            if !p.patientDaten.kostentraeger.isEmpty {                              // <-- NEU
                field("Krankenkasse", p.patientDaten.kostentraeger,                 // <-- NEU
                      x:x, y:y+38, w:w, h:11, lw:55)                              // <-- NEU
            }                                                                       // <-- NEU
```

- [ ] **Step 2: PLZ/Ort in `adresseText` einbauen**

In `PatProt/Services/PDFGenerator.swift`, `drawPage1`, Zeile ~361:

```swift
// Vorher:
let adresseText = [p.einsatzOrt.adresse, p.einsatzOrt.zusatz].filter { !$0.isEmpty }.joined(separator: ", ")

// Nachher:
let plzOrt = [p.einsatzOrt.plz, p.einsatzOrt.ort].filter { !$0.isEmpty }.joined(separator: " ")
let adresseText = [p.einsatzOrt.adresse, p.einsatzOrt.zusatz, plzOrt].filter { !$0.isEmpty }.joined(separator: ", ")
```

- [ ] **Step 3: `drawFotoPages`-Signatur um `kvFotos` erweitern**

In `PatProt/Services/PDFGenerator.swift`, `drawFotoPages`-Funktion (Zeile ~1384):

```swift
// Vorher:
private static func drawFotoPages(ctx: UIGraphicsPDFRendererContext,
                                   mediFotos: [FotoEintrag],
                                   patFotos: [FotoEintrag],
                                   erstelltAm: Date) {
    let groups: [(String, [FotoEintrag])] = [
        ("Medikamentenplan", mediFotos),
        ("Patientenfoto",    patFotos),
    ].filter { !$1.isEmpty }

// Nachher:
private static func drawFotoPages(ctx: UIGraphicsPDFRendererContext,
                                   mediFotos: [FotoEintrag],
                                   patFotos: [FotoEintrag],
                                   kvFotos: [FotoEintrag],       // <-- NEU
                                   erstelltAm: Date) {
    let groups: [(String, [FotoEintrag])] = [
        ("Medikamentenplan", mediFotos),
        ("Patientenfoto",    patFotos),
        ("KV-Karte",         kvFotos),                           // <-- NEU
    ].filter { !$1.isEmpty }
```

- [ ] **Step 4: Aufruf von `drawFotoPages` in `generate()` anpassen**

In `PatProt/Services/PDFGenerator.swift`, den Aufruf (~Zeile 254):

```swift
// Vorher:
drawFotoPages(ctx: ctx,
              mediFotos: protokoll.medikamentFotos,
              patFotos: protokoll.fotos,
              erstelltAm: protokoll.erstelltAm)

// Nachher:
drawFotoPages(ctx: ctx,
              mediFotos: protokoll.medikamentFotos,
              patFotos: protokoll.fotos,
              kvFotos: protokoll.kvFotos,       // <-- NEU
              erstelltAm: protokoll.erstelltAm)
```

- [ ] **Step 5: Build + Tests**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E 'error:|Build succeeded|Build FAILED'
```

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E 'Test Suite|passed|failed|error:'
```

Erwartet: Build succeeded, alle Tests grün (mind. 21 passing)

- [ ] **Step 6: Commit**

```bash
git add PatProt/Services/PDFGenerator.swift
git commit -m "feat: add Krankenkasse to PDF, PLZ/Ort in address field, KV-Karte photo page"
```
