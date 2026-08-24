# RKN-Protokoll Anpassung Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PatProt-PDF und App an das RKN-Protokoll (Rhein-Kreis Neuss 2017) angleichen — neue Maßnahmen, Transportziel-Typen, Fahrzeugtypen, Medikamente-Layout.

**Architecture:** Vier unabhängige Tasks: Modell → MassnahmenView/EinsatzOrtView → AbschlussView → PDFGenerator. Jeder Task baut auf dem vorherigen auf (Modell-Felder müssen vor den Views existieren). Build-Verifikation nach jedem Task, Commit danach.

**Tech Stack:** Swift 5, SwiftUI, UIKit (PDFGenerator), iOS Simulator `id=58572FBD-8FEA-49FD-B5A2-6E8326E4BCED`

---

## File Structure

| Datei | Änderungsart |
|-------|-------------|
| `PatProt/Models/Models.swift` | Modify — neue Felder in `EinsatzOrt`, `MassnahmenBefund`, `ErgebnisData` |
| `PatProt/Views/MassnahmenView.swift` | Modify — neue Rows + State-Vars in Airway- und Kreislauf-Section |
| `PatProt/Views/EinsatzOrtView.swift` | Modify — Toggle „mit Patient" |
| `PatProt/Views/AbschlussView.swift` | Modify — neue Section „Transportziel Klinik" |
| `PatProt/Services/PDFGenerator.swift` | Modify — Section 1/6/8/9 |

---

## Task 1: Modell-Erweiterungen

**Files:**
- Modify: `PatProt/Models/Models.swift`

### EinsatzOrt — mitPatient

- [ ] **Step 1: `mitPatient` zu `EinsatzOrt` hinzufügen**

In `Models.swift`, Zeile ~194, nach `var sondersignal: Bool = false`:

```swift
    var sondersignal: Bool = false
    var mitPatient: Bool = false
```

### MassnahmenBefund — CPAP, Heimlich, Defi, Kardioversion, IO

- [ ] **Step 2: Neue Felder zu `MassnahmenBefund` hinzufügen**

In `Models.swift`, vor dem Kommentar `// Monitoring` (aktuell ~Zeile 499), einfügen:

```swift
    // Airway-Erweiterungen
    var cpap: Bool = false
    var cpapMbar: String = ""
    var heimlich: Bool = false

    // Kreislauf-Erweiterungen
    var defibrillation: Bool = false
    var defiJoule: Int = 200
    var defiAnzahl: Int = 1
    var kardioversion: Bool = false
    var kardioversionJoule: Int = 100
    var intraossaer: Bool = false
    var intraossaerOrt: String = ""

    // Monitoring
    var monEkg: Bool = false
```

(Ersetze also `// Monitoring\n    var monEkg: Bool = false` durch den Block oben.)

### ErgebnisData — Transportziel-Typen

- [ ] **Step 3: Transportziel-Felder zu `ErgebnisData` hinzufügen**

In `Models.swift`, nach `var anmerkungen: String = ""` (Ende von `ErgebnisData`, aktuell ~Zeile 532):

```swift
    var anmerkungen: String = ""

    // Transportziel Klinik
    var transportzielZna: Bool = false
    var transportzielStrokeUnit: Bool = false
    var transportzielKathLabor: Bool = false
    var transportzielSonstigesKH: String = ""
```

- [ ] **Step 4: Build verifizieren**

```bash
xcodebuild -project /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt/PatProt.xcodeproj \
  -scheme PatProt -sdk iphonesimulator \
  -destination 'id=58572FBD-8FEA-49FD-B5A2-6E8326E4BCED' \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Erwartetes Ergebnis: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt add PatProt/Models/Models.swift
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt commit -m "feat: extend models for RKN – CPAP/Heimlich/Defi/IO/Transportziel/mitPatient"
```

---

## Task 2: MassnahmenView + EinsatzOrtView

**Files:**
- Modify: `PatProt/Views/MassnahmenView.swift`
- Modify: `PatProt/Views/EinsatzOrtView.swift`

### MassnahmenView — State-Variablen

- [ ] **Step 1: Neue `@State`-Variablen für Numpads oben in der Struct ergänzen**

In `MassnahmenView.swift`, nach den bestehenden `@State private var zeigeVenoesGroesseNumpad = false`:

```swift
    @State private var zeigeCpapNumpad = false
    @State private var zeigeDefiJouleNumpad = false
    @State private var zeigeDefiAnzahlNumpad = false
    @State private var zeigeKardioversionJouleNumpad = false
```

### MassnahmenView — Airway: CPAP + Heimlich

- [ ] **Step 2: CPAP und Heimlich in die Airway-Section einbauen**

In `MassnahmenView.swift`, die Zeile `CheckboxRow("Atemwegszugang erschwert", ...)` liegt direkt vor `TextField("Sonstige Airway-Maßnahmen"...)`.
Einfügen **vor** `TextField("Sonstige Airway-Maßnahmen"...)`:

```swift
                CheckboxRow("CPAP (5–15 mBar)", isOn: $befund.cpap)
                if befund.cpap {
                    HStack {
                        Text("mBar")
                        Spacer()
                        Text(befund.cpapMbar.isEmpty ? "—" : befund.cpapMbar)
                            .foregroundColor(befund.cpapMbar.isEmpty ? .secondary : .primary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeCpapNumpad = true }
                    .sheet(isPresented: $zeigeCpapNumpad) {
                        NumpadSheet(mode: .integer(label: "CPAP Druck", unit: "mBar", maxDigits: 2),
                                    initial: befund.cpapMbar) { val in befund.cpapMbar = val }
                    }
                }
                CheckboxRow("Heimlich (Fremdkörperentfernung)", isOn: $befund.heimlich)
                TextField("Sonstige Airway-Maßnahmen", text: $befund.airwaySonstige)
```

(Ersetze `TextField("Sonstige Airway-Maßnahmen"...)` durch den Block oben, der das TextField enthält.)

### MassnahmenView — Kreislauf: IO, Defi, Kardioversion

- [ ] **Step 3: IO-Zugang, Defibrillation und Kardioversion in die Kreislauf-Section einbauen**

In `MassnahmenView.swift`, vor `TextField("Sonstige Kreislauf-Maßnahmen"...)` einfügen:

```swift
                CheckboxRow("Intraossär-Zugang", isOn: $befund.intraossaer)
                if befund.intraossaer {
                    TextField("Ort (z.B. Tibia re.)", text: $befund.intraossaerOrt)
                }
                CheckboxRow("Defibrillation", isOn: $befund.defibrillation)
                if befund.defibrillation {
                    HStack(spacing: 12) {
                        HStack {
                            Text("Joule")
                            Spacer()
                            Text(String(befund.defiJoule))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { zeigeDefiJouleNumpad = true }
                        .sheet(isPresented: $zeigeDefiJouleNumpad) {
                            NumpadSheet(mode: .integer(label: "Energie", unit: "J", maxDigits: 3),
                                        initial: String(befund.defiJoule)) { val in
                                befund.defiJoule = Int(val) ?? 200
                            }
                        }
                        HStack {
                            Text("Anzahl")
                            Spacer()
                            Text(String(befund.defiAnzahl))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { zeigeDefiAnzahlNumpad = true }
                        .sheet(isPresented: $zeigeDefiAnzahlNumpad) {
                            NumpadSheet(mode: .integer(label: "Anzahl Schocks", unit: "×", maxDigits: 2),
                                        initial: String(befund.defiAnzahl)) { val in
                                befund.defiAnzahl = Int(val) ?? 1
                            }
                        }
                    }
                }
                CheckboxRow("Kardioversion", isOn: $befund.kardioversion)
                if befund.kardioversion {
                    HStack {
                        Text("Joule")
                        Spacer()
                        Text(String(befund.kardioversionJoule))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { zeigeKardioversionJouleNumpad = true }
                    .sheet(isPresented: $zeigeKardioversionJouleNumpad) {
                        NumpadSheet(mode: .integer(label: "Energie Kardioversion", unit: "J", maxDigits: 3),
                                    initial: String(befund.kardioversionJoule)) { val in
                            befund.kardioversionJoule = Int(val) ?? 100
                        }
                    }
                }
                TextField("Sonstige Kreislauf-Maßnahmen", text: $befund.circSonstige)
```

(Ersetze `TextField("Sonstige Kreislauf-Maßnahmen"...)` durch den Block oben, der das TextField enthält.)

### EinsatzOrtView — mitPatient

- [ ] **Step 4: Toggle „mit Patient" in EinsatzOrtView ergänzen**

In `EinsatzOrtView.swift`, nach `Toggle("Notarzt", isOn: $protokoll.einsatzOrt.notarzt)` (Zeile ~96):

```swift
                Toggle("Sondersignal", isOn: $protokoll.einsatzOrt.sondersignal)
                Toggle("Notarzt", isOn: $protokoll.einsatzOrt.notarzt)
                Toggle("mit Patient", isOn: $protokoll.einsatzOrt.mitPatient)
```

- [ ] **Step 5: Build verifizieren**

```bash
xcodebuild -project /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt/PatProt.xcodeproj \
  -scheme PatProt -sdk iphonesimulator \
  -destination 'id=58572FBD-8FEA-49FD-B5A2-6E8326E4BCED' \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Erwartetes Ergebnis: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt add \
  PatProt/Views/MassnahmenView.swift \
  PatProt/Views/EinsatzOrtView.swift
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt commit -m "feat: add CPAP/Heimlich/Defi/IO/Kardioversion to MassnahmenView; add mitPatient toggle"
```

---

## Task 3: AbschlussView — Transportziel Klinik

**Files:**
- Modify: `PatProt/Views/AbschlussView.swift`

- [ ] **Step 1: Neue Section „Transportziel Klinik" vor Einsatzbesonderheiten einfügen**

In `AbschlussView.swift`, direkt **vor** der bestehenden `// Einsatzbesonderheiten`-Section (die mit `Section { CheckboxRow("Ambulante Versorgung vor Ort"...` beginnt) einfügen:

```swift
            // Transportziel Klinik
            Section {
                CheckboxRow("ZNA / Notaufnahme", isOn: $protokoll.ergebnis.transportzielZna)
                CheckboxRow("Stroke Unit", isOn: $protokoll.ergebnis.transportzielStrokeUnit)
                CheckboxRow("Kath.-Labor", isOn: $protokoll.ergebnis.transportzielKathLabor)
                TextField("Sonstiges Ziel", text: $protokoll.ergebnis.transportzielSonstigesKH)
            } header: {
                Label("Transportziel Klinik", systemImage: "building.2.crop.circle")
            }

            // Einsatzbesonderheiten
```

- [ ] **Step 2: Build verifizieren**

```bash
xcodebuild -project /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt/PatProt.xcodeproj \
  -scheme PatProt -sdk iphonesimulator \
  -destination 'id=58572FBD-8FEA-49FD-B5A2-6E8326E4BCED' \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Erwartetes Ergebnis: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt add PatProt/Views/AbschlussView.swift
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt commit -m "feat: add Transportziel Klinik section to AbschlussView"
```

---

## Task 4: PDFGenerator — Section 1 / 6 / 8 / 9

**Files:**
- Modify: `PatProt/Services/PDFGenerator.swift`

Alle Änderungen an einer einzigen Datei — nach jedem Sub-Step bauen um Fehler früh zu fangen.

### 4a: Section 1 — Fahrzeugtypen + mitPatient

- [ ] **Step 1: `vItems` in Section 1 erweitern (mehr Fahrzeugtypen)**

Suche in `PDFGenerator.swift` den Block:
```swift
            let vItems: [(String, Bool)] = [
                ("RTW", fzUp.contains("RTW")),
                ("KTW", fzUp.contains("KTW")),
                ("FR",  fzUp.contains("FR") || fzUp.contains("FIRST")),
                ("NEF", fzUp.contains("NEF")),
            ]
```

Ersetze durch:
```swift
            let vItems: [(String, Bool)] = [
                ("RTW", fzUp.contains("RTW")),
                ("KTW", fzUp.contains("KTW")),
                ("NEF", fzUp.contains("NEF")),
                ("MHW", fzUp.contains("MHW")),
                ("VRW", fzUp.contains("VRW")),
                ("RTH", fzUp.contains("RTH")),
                ("FR",  fzUp.contains("FR") || fzUp.contains("FIRST")),
            ]
```

- [ ] **Step 2: „mit Patient" Checkbox in Sondersignal-Zeile ergänzen**

Suche in `PDFGenerator.swift`:
```swift
            cb("Sondersignal", p.einsatzOrt.sondersignal, x:x+2, y:y+1.5, bs:7, lw:55)
            cb("Notarzt", p.einsatzOrt.notarzt, x:x+80, y:y+1.5, bs:7, lw:35)
```

Ersetze durch:
```swift
            cb("Sondersignal", p.einsatzOrt.sondersignal, x:x+2, y:y+1.5, bs:7, lw:55)
            cb("Notarzt", p.einsatzOrt.notarzt, x:x+80, y:y+1.5, bs:7, lw:35)
            cb("mit Patient", p.einsatzOrt.mitPatient, x:x+130, y:y+1.5, bs:7, lw:45)
```

### 4b: Section 6 — Neue Maßnahmen in PDF

- [ ] **Step 3: CPAP + Heimlich in `maItems1` einfügen**

Suche in `PDFGenerator.swift` innerhalb der `maItems1`-Liste:
```swift
            ("EGA supraglottisch", p.massnahmen.supraglottisch),
            ("Atemweg erschwert", p.massnahmen.atemwegErschwert),
        ]
```

Ersetze durch:
```swift
            ("EGA supraglottisch", p.massnahmen.supraglottisch),
            ("Atemweg erschwert", p.massnahmen.atemwegErschwert),
            ("CPAP", p.massnahmen.cpap),
            ("Heimlich (FK)", p.massnahmen.heimlich),
        ]
```

- [ ] **Step 4: Defi + Kardioversion + IO in `maItems2` einfügen**

Suche in `PDFGenerator.swift`:
```swift
            ("Peripher-venös", p.massnahmen.peripherVenoes),
            ("Tourniquet", p.massnahmen.tourniquet),
```

Ersetze durch:
```swift
            ("Peripher-venös", p.massnahmen.peripherVenoes),
            ("Intraossär", p.massnahmen.intraossaer),
            ("Defibrillation", p.massnahmen.defibrillation),
            ("Kardioversion", p.massnahmen.kardioversion),
            ("Tourniquet", p.massnahmen.tourniquet),
```

- [ ] **Step 5: Neue Detail-Zeilen in den maDetails-Block einfügen**

Suche in `PDFGenerator.swift` den Block mit:
```swift
        if !p.massnahmen.sauerstoffLitMin.isEmpty { maDetails.append(("O₂ (l/min)", p.massnahmen.sauerstoffLitMin)) }
```

Einfügen **davor** (neue Einträge für die neuen Felder):
```swift
        if p.massnahmen.defibrillation {
            maDetails.append(("Defi", "\(p.massnahmen.defiJoule) J × \(p.massnahmen.defiAnzahl)"))
        }
        if p.massnahmen.kardioversion {
            maDetails.append(("Kardioversion", "\(p.massnahmen.kardioversionJoule) J"))
        }
        if p.massnahmen.cpap && !p.massnahmen.cpapMbar.isEmpty {
            maDetails.append(("CPAP", "\(p.massnahmen.cpapMbar) mBar"))
        }
        if p.massnahmen.intraossaer && !p.massnahmen.intraossaerOrt.isEmpty {
            maDetails.append(("IO-Zugang", p.massnahmen.intraossaerOrt))
        }
        if !p.massnahmen.sauerstoffLitMin.isEmpty { maDetails.append(("O₂ (l/min)", p.massnahmen.sauerstoffLitMin)) }
```

(Ersetze `if !p.massnahmen.sauerstoffLitMin.isEmpty ...` durch den Block oben, der diese Zeile enthält.)

### 4c: Section 8 — Medikamente-Spalten neu ordnen

- [ ] **Step 6: Spaltenreihenfolge in Section 8 anpassen**

Suche in `PDFGenerator.swift`:
```swift
            let mC: [CGFloat] = [mTotW*0.11, mTotW*0.32, mTotW*0.14, mTotW*0.12, mTotW*0.20, mTotW*0.11]
            let mHdr = ["Zeit","Medikament","Dosis","Einheit","Applikationsweg",""]
```

Ersetze durch:
```swift
            let mC: [CGFloat] = [mTotW*0.32, mTotW*0.14, mTotW*0.12, mTotW*0.20, mTotW*0.11, mTotW*0.11]
            let mHdr = ["Medikament","Dosis","Einheit","Applikationsweg","Zeit",""]
```

Suche dann in derselben Section:
```swift
                let vals2 = [t(med.zeit), med.name, med.dosis, med.einheit, med.route, ""]
```

Ersetze durch:
```swift
                let vals2 = [med.name, med.dosis, med.einheit, med.route, t(med.zeit), ""]
```

### 4d: Section 9 — Transportziel Klinik

- [ ] **Step 7: Transportziel-Checkboxen in Section 9 einfügen**

Suche in `PDFGenerator.swift` innerhalb der Section 9:
```swift
        field("Übergabe an Rettungsmittel", p.uebergabeAn, x:lx, y:y, w:rx-lx, h:12, lw:100, hl:true)
        y += 12
```

Einfügen **davor** (zwischen `secHeader(...)` und dem `field("Übergabe...")`):

```swift
        // Transportziel Klinik
        let tzItems: [(String, Bool)] = [
            ("ZNA / Notaufnahme", p.ergebnis.transportzielZna),
            ("Stroke Unit",       p.ergebnis.transportzielStrokeUnit),
            ("Kath.-Labor",       p.ergebnis.transportzielKathLabor),
        ]
        let tzW = (rx - lx) / CGFloat(tzItems.count + 1)
        fillRect(CGRect(x:lx, y:y, width:rx-lx, height:10), .white)
        strokeRect(CGRect(x:lx, y:y, width:rx-lx, height:10))
        for (i,(label,checked)) in tzItems.enumerated() {
            cb(label, checked, x:lx+CGFloat(i)*tzW+2, y:y+1.5, bs:7, lw:tzW-12)
        }
        if !p.ergebnis.transportzielSonstigesKH.isEmpty {
            field("Sonstiges KH", p.ergebnis.transportzielSonstigesKH,
                  x:lx+tzW*3, y:y, w:tzW, h:10, lw:55)
        }
        y += 10

        field("Übergabe an Rettungsmittel", p.uebergabeAn, x:lx, y:y, w:rx-lx, h:12, lw:100, hl:true)
        y += 12
```

(Ersetze `field("Übergabe an Rettungsmittel"...)` durch den Block oben, der dieses field enthält.)

- [ ] **Step 8: Build verifizieren**

```bash
xcodebuild -project /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt/PatProt.xcodeproj \
  -scheme PatProt -sdk iphonesimulator \
  -destination 'id=58572FBD-8FEA-49FD-B5A2-6E8326E4BCED' \
  build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Erwartetes Ergebnis: `** BUILD SUCCEEDED **`

- [ ] **Step 9: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt add PatProt/Services/PDFGenerator.swift
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt commit -m "feat: update PDF Section 1/6/8/9 for RKN – vehicles, new Maßnahmen, Medi column order, Transportziel"
```

---

## Akzeptanzkriterien

1. `BUILD SUCCEEDED` nach jedem Task
2. Section 1 PDF: 7 Fahrzeug-Checkboxen (RTW/KTW/NEF/MHW/VRW/RTH/FR) + „mit Patient"
3. MassnahmenView: CPAP mit Druck-Numpad, Heimlich, IO-Zugang mit Ort, Defi mit J+Anz-Numpads, Kardioversion mit J-Numpad
4. AbschlussView: Section „Transportziel Klinik" mit ZNA/Stroke/Kath.Labor/Sonstiges
5. PDF Section 6: CPAP, Heimlich, IO, Defi, Kardioversion als Checkboxen + Detailzeilen
6. PDF Section 8: Spaltenreihenfolge Medikament→Dosis→Einheit→Applikation→Zeit
7. PDF Section 9: Transportziel-Checkboxen vor Übergabe-Zeile
