# Batch 9 — SAMPLER L Erweiterung, Unbekannt, Auffindewerte Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SAMPLER L um Stuhlgang + Regelblutung erweitern; Unbekannt-Flags für A/M/P; Auffindewerte-Section in Notfallgeschehen.

**Architecture:** Reine Erweiterung — neue Felder in bestehenden Structs (backward-compatible Codable defaults), neue Sections in bestehenden Views, neue Rows im PDF. Jeder Task ist unabhängig.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Testing (`@Test`, `#expect`), `xcodebuild test`

---

## Dateien

| Datei | Änderung |
|---|---|
| `PatProt/Models/Models.swift` | +6 Felder in SAMPLERBefund (L-Erweiterung) + 3 Unbekannt-Flags + 7 Auffindewerte-Felder in NotfallgeschehenBefund |
| `PatProt/Views/SAMPLERView.swift` | 2 neue L-Sections + Unbekannt-Toggles in A/M/P |
| `PatProt/Views/NotfallgeschehenView.swift` | NavigationLink + AuffindewerteView |
| `PatProt/Services/PDFGenerator.swift` | +2 SAMPLER-Rows, Unbekannt in A/M/P, Auffindewerte-Zeile |
| `PatProtTests/PatProtTests.swift` | 3 neue Tests |

---

## Task 1: Model-Felder + Tests

**Files:**
- Modify: `PatProt/Models/Models.swift`
- Test: `PatProtTests/PatProtTests.swift`

**Context:**
- `SAMPLERBefund` liegt ab Zeile 522. Nach `letztesMahlUnbekannt: Bool = false` (Zeile 529) neue Felder einfügen.
- `NotfallgeschehenBefund` liegt ab Zeile 784. Nach `notfallFreitext: String = ""` (Zeile 810) neue Felder einfügen.
- Alle neuen Felder haben Default-Werte → rückwärtskompatibel mit gespeicherten JSON-Archiven.

- [ ] **Step 1: Tests schreiben (failing)**

In `PatProtTests/PatProtTests.swift`, nach dem letzten `@Test`:

```swift
@Test func samplerBefundHatStuhlgangUndRegelblutung() {
    let s = SAMPLERBefund()
    #expect(s.letzterStuhlgang == "")
    #expect(s.letzterStuhlgangUnbekannt == false)
    #expect(s.letzteRegelblutung == "")
    #expect(s.letzteRegelblutungUnbekannt == false)
}

@Test func samplerBefundHatUnbekanntFelder() {
    let s = SAMPLERBefund()
    #expect(s.allergienUnbekannt == false)
    #expect(s.medikamenteUnbekannt == false)
    #expect(s.patientenVorgeschichteUnbekannt == false)
}

@Test func notfallgeschehenHatAuffindewerte() {
    let n = NotfallgeschehenBefund()
    #expect(n.auffindePuls == "")
    #expect(n.auffindeSpO2 == "")
    #expect(n.auffindeRRSys == "")
}
```

- [ ] **Step 2: Tests ausführen — müssen FAILED sein**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "samplerBefundHatStuhlgang|samplerBefundHatUnbekannt|notfallgeschehenHatAuffindewerte|FAILED"
```

Erwartet: 3 Tests FAILED (Felder existieren noch nicht).

- [ ] **Step 3: SAMPLERBefund erweitern**

In `PatProt/Models/Models.swift`, nach Zeile 529 (`var letztesMahlUnbekannt: Bool = false`):

```swift
    var letzterStuhlgang: String = ""
    var letzterStuhlgangZeit: Date? = nil
    var letzterStuhlgangUnbekannt: Bool = false
    var letzteRegelblutung: String = ""
    var letzteRegelblutungZeit: Date? = nil
    var letzteRegelblutungUnbekannt: Bool = false
    var allergienUnbekannt: Bool = false
    var medikamenteUnbekannt: Bool = false
    var patientenVorgeschichteUnbekannt: Bool = false
```

- [ ] **Step 4: NotfallgeschehenBefund erweitern**

In `PatProt/Models/Models.swift`, nach Zeile 810 (`var notfallFreitext: String = ""`):

```swift
    var auffindePuls: String = ""
    var auffindeSpO2: String = ""
    var auffindeRRSys: String = ""
    var auffindeRRDia: String = ""
    var auffindeAF: String = ""
    var auffindeBewusstsein: String = ""
    var auffindeFreitext: String = ""
```

- [ ] **Step 5: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed (inkl. 3 neue), 0 Fehler.

- [ ] **Step 6: Commit**

```bash
git add PatProt/Models/Models.swift PatProtTests/PatProtTests.swift
git commit -m "feat: add SAMPLER L extension, Unbekannt flags, and Auffindewerte model fields"
```

---

## Task 2: SAMPLERView — L-Sections + Unbekannt für A/M/P

**Files:**
- Modify: `PatProt/Views/SAMPLERView.swift`

**Context:** Die aktuelle L-Section (Zeilen 78–92) endet mit der Letzte-Mahlzeit-Section. Danach kommt `Section { VStack { Text("E — Ereignis") ...`. Zwei neue Sections direkt nach der Letzte-Mahlzeit-Section einfügen (vor E).

Die A-, M-, P-Sections befinden sich in Zeilen 31–76. Je Section einen Toggle `"Unbekannt"` vor dem TextEditor/TextField hinzufügen + den TextEditor/TextField in `if !befund.flagUnbekannt` einwickeln.

- [ ] **Step 1: Zwei neue L-Sections einfügen**

In `PatProt/Views/SAMPLERView.swift`, direkt nach der schließenden `}` der Letzte-Mahlzeit-Section (nach Zeile 92, vor der E-Section):

```swift
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("L — Letzter Stuhlgang").font(.subheadline.bold())
                    Text("Wann zuletzt Stuhlgang").font(.caption).foregroundColor(.secondary)
                    Toggle("Unbekannt", isOn: $befund.letzterStuhlgangUnbekannt)
                        .onChange(of: befund.letzterStuhlgangUnbekannt) { _, isUnknown in
                            if isUnknown { befund.letzterStuhlgangZeit = nil }
                        }
                    if !befund.letzterStuhlgangUnbekannt {
                        ZeitFeld(label: "Uhrzeit", datum: $befund.letzterStuhlgangZeit)
                    }
                    TextField("Freitext", text: $befund.letzterStuhlgang)
                    Text("→ PDF S. 1 · SAMPLER · L").font(.caption2).foregroundColor(.secondary)
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("L — Letzte Regelblutung").font(.subheadline.bold())
                    Text("Wann letzte Regelblutung").font(.caption).foregroundColor(.secondary)
                    Toggle("Unbekannt", isOn: $befund.letzteRegelblutungUnbekannt)
                        .onChange(of: befund.letzteRegelblutungUnbekannt) { _, isUnknown in
                            if isUnknown { befund.letzteRegelblutungZeit = nil }
                        }
                    if !befund.letzteRegelblutungUnbekannt {
                        ZeitFeld(label: "Uhrzeit", datum: $befund.letzteRegelblutungZeit)
                    }
                    TextField("Freitext", text: $befund.letzteRegelblutung)
                    Text("→ PDF S. 1 · SAMPLER · L").font(.caption2).foregroundColor(.secondary)
                }
            }
```

- [ ] **Step 2: A-Section — Unbekannt Toggle**

In `PatProt/Views/SAMPLERView.swift`, A-Section (Zeilen 31–38). Ersetze:

```swift
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("A — Allergien").font(.subheadline.bold())
                    Text("Bekannte Allergien und Unverträglichkeiten").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $befund.allergien).frame(minHeight: 60)
                    Text("→ PDF S. 1 · SAMPLER · A").font(.caption2).foregroundColor(.secondary)
                }
            }
```

durch:

```swift
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("A — Allergien").font(.subheadline.bold())
                    Text("Bekannte Allergien und Unverträglichkeiten").font(.caption).foregroundColor(.secondary)
                    Toggle("Unbekannt", isOn: $befund.allergienUnbekannt)
                        .onChange(of: befund.allergienUnbekannt) { _, isUnknown in
                            if isUnknown { befund.allergien = "" }
                        }
                    if !befund.allergienUnbekannt {
                        TextEditor(text: $befund.allergien).frame(minHeight: 60)
                    }
                    Text("→ PDF S. 1 · SAMPLER · A").font(.caption2).foregroundColor(.secondary)
                }
            }
```

- [ ] **Step 3: P-Section — Unbekannt Toggle**

In `PatProt/Views/SAMPLERView.swift`, P-Section (Zeilen 70–77). Ersetze:

```swift
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("P — Patientenvorgeschichte").font(.subheadline.bold())
                    Text("Relevante Vorerkrankungen und Operationen").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $befund.patientenVorgeschichte).frame(minHeight: 70)
                    Text("→ PDF S. 1 · SAMPLER · P").font(.caption2).foregroundColor(.secondary)
                }
            }
```

durch:

```swift
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("P — Patientenvorgeschichte").font(.subheadline.bold())
                    Text("Relevante Vorerkrankungen und Operationen").font(.caption).foregroundColor(.secondary)
                    Toggle("Unbekannt", isOn: $befund.patientenVorgeschichteUnbekannt)
                        .onChange(of: befund.patientenVorgeschichteUnbekannt) { _, isUnknown in
                            if isUnknown { befund.patientenVorgeschichte = "" }
                        }
                    if !befund.patientenVorgeschichteUnbekannt {
                        TextEditor(text: $befund.patientenVorgeschichte).frame(minHeight: 70)
                    }
                    Text("→ PDF S. 1 · SAMPLER · P").font(.caption2).foregroundColor(.secondary)
                }
            }
```

- [ ] **Step 4: M-Section — Unbekannt Toggle**

In `PatProt/Views/SAMPLERView.swift`, M-Section (Zeilen 39–69). Die M-Section hat neben dem TextField auch einen QR-Scanner-Button und `MedikamentFotoSektion`. Ersetze den Anfang der Section (VStack-Inhalt von Text("M — Medikamente") bis zum TextField):

```swift
// Anfang des VStack, aktuell:
                    Text("M — Medikamente").font(.subheadline.bold())
                    Text("Aktuelle Medikation (Text und/oder Foto)").font(.caption).foregroundColor(.secondary)
                    TextField("z.B. Metoprolol 50mg, ASS 100mg", text: $befund.medikamente, axis: .vertical)
                        .lineLimit(3...6)
                    if let fehler = scanFehler {
```

ersetzen durch:

```swift
                    Text("M — Medikamente").font(.subheadline.bold())
                    Text("Aktuelle Medikation (Text und/oder Foto)").font(.caption).foregroundColor(.secondary)
                    Toggle("Unbekannt", isOn: $befund.medikamenteUnbekannt)
                        .onChange(of: befund.medikamenteUnbekannt) { _, isUnknown in
                            if isUnknown { befund.medikamente = "" }
                        }
                    if !befund.medikamenteUnbekannt {
                        TextField("z.B. Metoprolol 50mg, ASS 100mg", text: $befund.medikamente, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    if let fehler = scanFehler {
```

Der Rest der M-Section (QR-Scanner-Button, MedikamentFotoSektion) bleibt unverändert und ist weiterhin immer sichtbar.

- [ ] **Step 5: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed, 0 Fehler.

- [ ] **Step 6: Commit**

```bash
git add PatProt/Views/SAMPLERView.swift
git commit -m "feat: add Stuhlgang/Regelblutung L-sections and Unbekannt toggles for A/M/P in SAMPLERView"
```

---

## Task 3: Auffindewerte — NotfallgeschehenView + AuffindewerteView

**Files:**
- Modify: `PatProt/Views/NotfallgeschehenView.swift`

**Context:** `NotfallgeschehenView` zeigt eine `List` mit mehreren Sections. Die erste Section hat die NavigationLinks (Unfallhergang, Unfallmechanismus). Am Ende der `List` gibt es eine Section mit dem NACA-Picker (Zeilen 77–94) und eine Section mit Freitext-Ergänzungen (Zeilen 95–100). Den Auffindewerte-Link in eine neue Section, sinnvoll platziert (nach der Erstbefund-Section, vor NACA).

Aktuell (vereinfacht):
```
Section { Unfallhergang, Unfallmechanismus }
Section { Pre Emergency Status }
Section { Erstbefund bei Ankunft }
Section { Verlaufsbemerkungen, Dyn. Erweiterung }
Section { NACA-Picker }
Section { Freitext }
```

Ziel: Neuen NavigationLink "Auffindewerte" nach "Erstbefund bei Ankunft" einfügen (in der Verlauf/Erweiterung-Section oder als eigene Section).

Am Ende der Datei (nach AuswahlSection) die neue `AuffindewerteView` hinzufügen.

- [ ] **Step 1: NavigationLink in NotfallgeschehenView**

In `PatProt/Views/NotfallgeschehenView.swift`, nach der Erstbefund-Section (nach dem NavigationLink `DynamischeErweiterungView`-Block, der endet mit `}` nach Zeile 75), eine neue Section einfügen:

```swift
            Section {
                NavigationLink {
                    AuffindewerteView(befund: $befund)
                } label: {
                    NfgZeile(
                        titel: "Auffindewerte",
                        wert: (befund.auffindePuls.isEmpty && befund.auffindeSpO2.isEmpty
                               && befund.auffindeRRSys.isEmpty && befund.auffindeBewusstsein.isEmpty)
                            ? nil
                            : [befund.auffindePuls.isEmpty ? nil : "Puls \(befund.auffindePuls)",
                               befund.auffindeSpO2.isEmpty ? nil : "SpO₂ \(befund.auffindeSpO2)%",
                               befund.auffindeRRSys.isEmpty ? nil : "RR \(befund.auffindeRRSys)/\(befund.auffindeRRDia)"]
                               .compactMap { $0 }.joined(separator: " · ")
                    )
                }
            }
```

- [ ] **Step 2: AuffindewerteView am Ende der Datei hinzufügen**

In `PatProt/Views/NotfallgeschehenView.swift`, nach dem letzten bestehenden struct (nach `AuswahlSection`), eine neue View `AuffindewerteView` hinzufügen:

```swift
// MARK: - Auffindewerte

struct AuffindewerteView: View {
    @Binding var befund: NotfallgeschehenBefund

    @State private var zeigePulsNumpad  = false
    @State private var zeigeSpO2Numpad  = false
    @State private var zeigeAFNumpad    = false
    @State private var zeigeRRNumpad    = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Puls (/min)").foregroundStyle(.secondary)
                    Spacer()
                    Text(befund.auffindePuls.isEmpty ? "–" : "\(befund.auffindePuls) /min")
                        .foregroundStyle(befund.auffindePuls.isEmpty ? Color(.tertiaryLabel) : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { zeigePulsNumpad = true }
                .sheet(isPresented: $zeigePulsNumpad) {
                    NumpadSheet(mode: .integer(label: "Puls", unit: "/min", maxDigits: 3),
                                initial: befund.auffindePuls) { val in befund.auffindePuls = val }
                }

                HStack {
                    Text("SpO₂ (%)").foregroundStyle(.secondary)
                    Spacer()
                    Text(befund.auffindeSpO2.isEmpty ? "–" : "\(befund.auffindeSpO2) %")
                        .foregroundStyle(befund.auffindeSpO2.isEmpty ? Color(.tertiaryLabel) : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { zeigeSpO2Numpad = true }
                .sheet(isPresented: $zeigeSpO2Numpad) {
                    NumpadSheet(mode: .integer(label: "SpO₂", unit: "%", maxDigits: 3),
                                initial: befund.auffindeSpO2) { val in befund.auffindeSpO2 = val }
                }

                HStack {
                    Text("RR (mmHg)").foregroundStyle(.secondary)
                    Spacer()
                    Text(befund.auffindeRRSys.isEmpty ? "–" : "\(befund.auffindeRRSys)/\(befund.auffindeRRDia) mmHg")
                        .foregroundStyle(befund.auffindeRRSys.isEmpty ? Color(.tertiaryLabel) : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { zeigeRRNumpad = true }
                .sheet(isPresented: $zeigeRRNumpad) {
                    NumpadSheet(mode: .bloodPressure,
                                initial: befund.auffindeRRSys.isEmpty ? "" : "\(befund.auffindeRRSys)/\(befund.auffindeRRDia)") { val in
                        let parts = val.split(separator: "/")
                        if parts.count == 2 {
                            befund.auffindeRRSys = String(parts[0])
                            befund.auffindeRRDia = String(parts[1])
                        } else if val.isEmpty {
                            befund.auffindeRRSys = ""
                            befund.auffindeRRDia = ""
                        }
                    }
                }

                HStack {
                    Text("AF (/min)").foregroundStyle(.secondary)
                    Spacer()
                    Text(befund.auffindeAF.isEmpty ? "–" : "\(befund.auffindeAF) /min")
                        .foregroundStyle(befund.auffindeAF.isEmpty ? Color(.tertiaryLabel) : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { zeigeAFNumpad = true }
                .sheet(isPresented: $zeigeAFNumpad) {
                    NumpadSheet(mode: .integer(label: "AF", unit: "/min", maxDigits: 2),
                                initial: befund.auffindeAF) { val in befund.auffindeAF = val }
                }
            } header: { Text("Messwerte bei Erstkontakt") }

            Section {
                TextField("AVPU / Freitext (z.B. A, V, P, U)", text: $befund.auffindeBewusstsein)
            } header: { Text("Bewusstsein") }

            Section {
                TextField("Ergänzungen", text: $befund.auffindeFreitext, axis: .vertical)
                    .lineLimit(3...6)
            } header: { Text("Freitext") }
        }
        .navigationTitle("Auffindewerte")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

- [ ] **Step 3: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed, 0 Fehler.

- [ ] **Step 4: Commit**

```bash
git add PatProt/Views/NotfallgeschehenView.swift
git commit -m "feat: add Auffindewerte navigation link and view in NotfallgeschehenView"
```

---

## Task 4: PDFGenerator — SAMPLER Erweiterung + Auffindewerte

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift`

**Context:**
- SAMPLER-Block: `samplerAllRows` in Zeile 535–546. Drei Erweiterungen: (1) Unbekannt in A/M/P, (2) zwei neue L-Rows, (3) Auffindewerte-Zeile nach dem SAMPLER-Block.
- Die Auffindewerte-Zeile soll nach `y += 11` (Zeile 549) des SAMPLER-Blocks erscheinen, also im Bereich vor Section 3.

- [ ] **Step 1: samplerAllRows — Unbekannt für A/M/P**

In `PatProt/Services/PDFGenerator.swift`, die Zeilen 536–541:

```swift
// vorher:
            ("S – Symptome",       p.sampler.symptome),
            ("A – Allergien",      p.sampler.allergien),
            ("M – Medikamente",    p.medikamentFotos.isEmpty
                                    ? p.sampler.medikamente
                                    : "Medikamentenplan: Foto-Anhang (S. 3ff.)"),
            ("P – Vorgeschichte",  p.sampler.patientenVorgeschichte),
```

ersetzen durch:

```swift
            ("S – Symptome",       p.sampler.symptome),
            ("A – Allergien",      p.sampler.allergienUnbekannt ? "Unbekannt" : p.sampler.allergien),
            ("M – Medikamente",    p.sampler.medikamenteUnbekannt ? "Unbekannt"
                                    : (p.medikamentFotos.isEmpty
                                        ? p.sampler.medikamente
                                        : "Medikamentenplan: Foto-Anhang (S. 3ff.)")),
            ("P – Vorgeschichte",  p.sampler.patientenVorgeschichteUnbekannt ? "Unbekannt" : p.sampler.patientenVorgeschichte),
```

- [ ] **Step 2: Neue L-Rows für Stuhlgang und Regelblutung**

In `PDFGenerator.swift`, nach dem `letztesMahlText`-Block (Zeile 520–529) und vor `schwangerschaftText`:

```swift
        let letzterStuhlgangText: String = {
            if p.sampler.letzterStuhlgangUnbekannt { return "Unbekannt" }
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            let was = p.sampler.letzterStuhlgang.isEmpty ? "–" : p.sampler.letzterStuhlgang
            if let zeit = p.sampler.letzterStuhlgangZeit { return "\(was) · \(fmt.string(from: zeit)) Uhr" }
            return was
        }()
        let letzteRegelblutungText: String = {
            if p.sampler.letzteRegelblutungUnbekannt { return "Unbekannt" }
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            let was = p.sampler.letzteRegelblutung.isEmpty ? "–" : p.sampler.letzteRegelblutung
            if let zeit = p.sampler.letzteRegelblutungZeit { return "\(was) · \(fmt.string(from: zeit)) Uhr" }
            return was
        }()
```

In `samplerAllRows` nach `("L – Letztes Essen", letztesMahlText)` zwei neue Zeilen:

```swift
            ("L – Letzter Stuhlgang",   letzterStuhlgangText),
            ("L – Letzte Regelblutung", letzteRegelblutungText),
```

- [ ] **Step 3: Auffindewerte-Zeile nach SAMPLER-Block**

In `PDFGenerator.swift`, direkt nach dem `for (label, value) in samplerAllRows { ... y += 11 }` Block (nach Zeile 550, vor dem `// ── SECTION 3 ──` Kommentar):

```swift
        // Auffindewerte — nur wenn mindestens ein Messwert gesetzt
        let ng = p.notfallGeschehen
        let auffindeTeile = [
            ng.auffindePuls.isEmpty    ? nil : "Puls \(ng.auffindePuls)/min",
            ng.auffindeSpO2.isEmpty    ? nil : "SpO₂ \(ng.auffindeSpO2)%",
            ng.auffindeRRSys.isEmpty   ? nil : "RR \(ng.auffindeRRSys)/\(ng.auffindeRRDia)",
            ng.auffindeAF.isEmpty      ? nil : "AF \(ng.auffindeAF)/min",
            ng.auffindeBewusstsein.isEmpty ? nil : "Bew. \(ng.auffindeBewusstsein)",
        ].compactMap { $0 }
        if !auffindeTeile.isEmpty {
            field("Auffindewerte", auffindeTeile.joined(separator: " · "),
                  x:lx, y:y, w:rx-lx, h:11, lw:70)
            y += 11
        }
```

- [ ] **Step 4: Build + Tests**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "passed|FAILED|error:"
```

Erwartet: alle Tests passed, 0 Fehler.

- [ ] **Step 5: Commit**

```bash
git add PatProt/Services/PDFGenerator.swift
git commit -m "feat: add SAMPLER L rows, Unbekannt for A/M/P, and Auffindewerte in PDFGenerator"
```
