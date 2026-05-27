# Batch 2 — Bugs & Quick Wins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vier Fixes: Archiv-Deduplikation via UUID-Restore, Übergabe auto-fill aus weitereEinsatzmittel, Uhrzeit-Clear-Button, Notfallgeschehen-Freitext in View und PDF.

**Architecture:** Alle Änderungen sind isoliert — kein neues Subsystem, nur gezielte Erweiterungen bestehender Klassen und Views. Models.swift bekommt zwei strukturelle Fixes (`var id`, `notfallFreitext`). EinsatzOrtView und AbschlussView bekommen je eine kleine UI-Änderung. NotfallgeschehenView und PDFGenerator bekommen das neue Freitext-Feld.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Testing (`@Test`, `#expect`), `xcodebuild`

---

## File Structure

| Datei | Änderungen |
|---|---|
| `PatProt/Models/Models.swift` | `let id` → `var id`, `id = d.id` in `apply(from:)`, `notfallFreitext` in `NotfallgeschehenBefund` |
| `PatProt/Views/EinsatzOrtView.swift` | × Button in `ZeitFeld` |
| `PatProt/Views/AbschlussView.swift` | `.onAppear` auto-fill `uebergabeAn` |
| `PatProt/Views/NotfallgeschehenView.swift` | Section „Freitext" mit `notfallFreitext` |
| `PatProt/Services/PDFGenerator.swift` | `notfallFreitext` nach `verlaufsbemerkungen`-Block rendern |
| `PatProtTests/PatProtTests.swift` | 2 neue Tests |

---

### Task 1: Archiv-Deduplikation + notfallFreitext (Models)

**Files:**
- Modify: `PatProt/Models/Models.swift` — Zeile 91 (`let id`), Zeile ~951 (`apply(from:)`), Zeile ~752 (`NotfallgeschehenBefund`)
- Test: `PatProtTests/PatProtTests.swift`

Kontext: `EinsatzProtokoll` ist eine `class` mit `let id = UUID()`. `apply(from: ProtokollDaten)` restauriert alle Published-Properties außer `id`. Wenn nach einem Archiv-Laden erneut gespeichert wird, stimmt die UUID nicht überein → Duplikat. Fix: `id` mutable machen und in `apply` setzen.

`NotfallgeschehenBefund` ist ein `struct Codable`. Das neue Feld mit Default `""` ist automatisch rückwärtskompatibel (Codable ignoriert fehlende Keys mit Default-Wert, da struct init alle Parameter braucht — hier via `var` mit Default).

- [ ] **Step 1: Tests schreiben**

In `PatProtTests/PatProtTests.swift`, neue Tests zur Struct `PatProtTests` hinzufügen:

```swift
@Test func applyFromRestoresId() {
    let protokoll = EinsatzProtokoll()
    let originalId = protokoll.id
    var daten = ProtokollDaten()
    daten.id = UUID()  // andere UUID
    #expect(daten.id != originalId)
    protokoll.apply(from: daten)
    #expect(protokoll.id == daten.id)
}

@Test func notfallgeschehenBefundHatNotfallFreitext() {
    let befund = NotfallgeschehenBefund()
    #expect(befund.notfallFreitext == "")
}
```

- [ ] **Step 2: Tests laufen lassen — müssen fehlschlagen**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E 'Test Suite|passed|failed|error:'
```

Erwartet: `applyFromRestoresId` schlägt fehl (id wird nicht gesetzt), `notfallgeschehenBefundHatNotfallFreitext` schlägt fehl (property existiert nicht).

- [ ] **Step 3: `let id` → `var id` in EinsatzProtokoll**

In `PatProt/Models/Models.swift`, Zeile 91:

```swift
// vorher:
let id = UUID()

// nachher:
var id = UUID()
```

- [ ] **Step 4: `id = d.id` in `apply(from:)` ergänzen**

In `PatProt/Models/Models.swift`, Funktion `apply(from d: ProtokollDaten)` (~Zeile 951) — erste Zeile im Funktionskörper ergänzen:

```swift
func apply(from d: ProtokollDaten) {
    id = d.id   // <-- NEU: erste Zeile
    einsatzOrt = d.einsatzOrt; patientDaten = d.patientDaten; besatzung = d.besatzung
    // ... Rest unverändert
}
```

- [ ] **Step 5: `notfallFreitext` zu `NotfallgeschehenBefund` hinzufügen**

In `PatProt/Models/Models.swift`, `struct NotfallgeschehenBefund` (~Zeile 750) — nach `var verlaufsbemerkungen`:

```swift
var dynamischeErweiterung: String = ""
var notfallFreitext: String = ""   // <-- NEU: nach dynamischeErweiterung
```

Genau: nach `var dynamischeErweiterung: String = ""` einfügen (das ist das letzte Feld vor `var manvGesamtSK`).

- [ ] **Step 6: Build prüfen**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E 'error:|Build succeeded|Build FAILED'
```

Erwartet: `Build succeeded`

- [ ] **Step 7: Tests laufen lassen — müssen grün sein**

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E 'Test Suite|passed|failed|error:'
```

Erwartet: alle Tests grün (mind. 23 passing)

- [ ] **Step 8: Commit**

```bash
git add PatProt/Models/Models.swift PatProtTests/PatProtTests.swift
git commit -m "fix: restore UUID in apply(from:) to prevent archive duplicates; add notfallFreitext to NotfallgeschehenBefund"
```

---

### Task 2: Uhrzeit löschen (ZeitFeld)

**Files:**
- Modify: `PatProt/Views/EinsatzOrtView.swift` — `struct ZeitFeld` (~Zeile 696)

Kontext: `ZeitFeld` hat `@Binding var datum: Date?`. Der HStack enthält: Label · Spacer · Zeittext · „Jetzt"-Button. Es fehlt ein Clear-Button. Der × Button soll nur erscheinen wenn `datum != nil`, um keinen Platz zu verbrauchen wenn kein Wert gesetzt ist.

Kein Unit-Test möglich für reine SwiftUI-View-Logik — visuell testen.

- [ ] **Step 1: × Button in ZeitFeld.body einfügen**

In `PatProt/Views/EinsatzOrtView.swift`, `ZeitFeld.body`, nach dem „Jetzt"-Button:

```swift
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
        if datum != nil {                              // <-- NEU
            Button {                                  // <-- NEU
                datum = nil                           // <-- NEU
            } label: {                               // <-- NEU
                Image(systemName: "xmark.circle.fill")// <-- NEU
                    .foregroundStyle(.secondary)      // <-- NEU
            }                                        // <-- NEU
            .buttonStyle(.plain)                     // <-- NEU
        }                                            // <-- NEU
    }
    .contentShape(Rectangle())
    .onTapGesture { zeigeNumpad = true }
    .sheet(isPresented: $zeigeNumpad) {
        NumpadSheet(mode: .time(label: label), initial: displayText) { timeStr in
            applyTime(timeStr)
        }
    }
}
```

- [ ] **Step 2: Build prüfen**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E 'error:|Build succeeded|Build FAILED'
```

Erwartet: `Build succeeded`

- [ ] **Step 3: Commit**

```bash
git add PatProt/Views/EinsatzOrtView.swift
git commit -m "feat: add clear button to ZeitFeld to allow deleting entered times"
```

---

### Task 3: Übergabe Auto-Fill (AbschlussView)

**Files:**
- Modify: `PatProt/Views/AbschlussView.swift` — Section „Übergabe an anderes Rettungsmittel" (~Zeile 72)

Kontext: Die Section mit `TextField("Rettungsmittel / Kennung...", text: $protokoll.uebergabeAn)` bekommt ein `.onAppear`, das `uebergabeAn` mit `einsatzOrt.weitereEinsatzmittel.joined(separator: " / ")` vorausfüllt — aber nur wenn `uebergabeAn` noch leer und `weitereEinsatzmittel` nicht leer ist. So werden manuelle Eingaben nie überschrieben.

Kein Unit-Test möglich für SwiftUI onAppear — visuell testen.

- [ ] **Step 1: `.onAppear` zur Übergabe-Section hinzufügen**

In `PatProt/Views/AbschlussView.swift`, die Section mit `uebergabeAn` (~Zeile 72):

```swift
Section {
    TextField("Rettungsmittel / Kennung (z.B. RTW 10/83-2)", text: $protokoll.uebergabeAn)
    TextField("Zustand bei Übergabe", text: $protokoll.zustandBeiUebergabe)
} header: {
    Label("Übergabe an anderes Rettungsmittel", systemImage: "cross.vial.fill")
}
.onAppear {                                                           // <-- NEU
    if protokoll.uebergabeAn.isEmpty,                                 // <-- NEU
       !protokoll.einsatzOrt.weitereEinsatzmittel.isEmpty {           // <-- NEU
        protokoll.uebergabeAn = protokoll.einsatzOrt                  // <-- NEU
            .weitereEinsatzmittel.joined(separator: " / ")            // <-- NEU
    }                                                                 // <-- NEU
}                                                                     // <-- NEU
```

- [ ] **Step 2: Build prüfen**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E 'error:|Build succeeded|Build FAILED'
```

Erwartet: `Build succeeded`

- [ ] **Step 3: Commit**

```bash
git add PatProt/Views/AbschlussView.swift
git commit -m "feat: auto-fill Übergabe-Feld from weitereEinsatzmittel on appear"
```

---

### Task 4: Notfallgeschehen-Freitext View + PDF

**Files:**
- Modify: `PatProt/Views/NotfallgeschehenView.swift` — vor `.navigationTitle` (~Zeile 97)
- Modify: `PatProt/Services/PDFGenerator.swift` — `drawPage1`, nach `verlaufsbemerkungen`-Block (~Zeile 445)

Kontext: `notfallFreitext` wurde in Task 1 zu `NotfallgeschehenBefund` hinzugefügt. Jetzt braucht es (a) eine Eingabe-Section in der View und (b) eine bedingte Zeile im PDF.

In `NotfallgeschehenView.swift`: Die Form endet kurz vor `.navigationTitle("Notfallgeschehen")`. Dort eine neue Section einfügen.

In `PDFGenerator.swift` (`drawPage1`): Der Notfallgeschehen-Block endet mit dem `verlaufsbemerkungen`-Check (~Zeile 445–448). Danach kommt `// ABCDE grid`. Das neue Freitext-Feld gehört zwischen `verlaufsbemerkungen` und ABCDE.

- [ ] **Step 1: Section in NotfallgeschehenView einfügen**

In `PatProt/Views/NotfallgeschehenView.swift`, unmittelbar vor `.navigationTitle("Notfallgeschehen")`:

```swift
        // Neues Freitext-Feld — vor .navigationTitle einfügen
        Section {
            TextField("Ergänzungen / Sonstiges", text: $befund.notfallFreitext, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Label("Freitext", systemImage: "text.alignleft")
        }
    }   // Ende Form
    .navigationTitle("Notfallgeschehen")
    .navigationBarTitleDisplayMode(.large)
}
```

Konkret: die bestehenden letzten Zeilen der Form vor `.navigationTitle`:
```swift
        }       // Ende Section NACA
    }           // Ende Form
    .navigationTitle("Notfallgeschehen")
```
werden zu:
```swift
        }       // Ende Section NACA
        Section {
            TextField("Ergänzungen / Sonstiges", text: $befund.notfallFreitext, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Label("Freitext", systemImage: "text.alignleft")
        }
    }           // Ende Form
    .navigationTitle("Notfallgeschehen")
```

- [ ] **Step 2: notfallFreitext im PDF rendern**

In `PatProt/Services/PDFGenerator.swift`, `drawPage1`, nach dem `verlaufsbemerkungen`-Block (der so aussieht):

```swift
        if !ng.verlaufsbemerkungen.isEmpty {
            field("Verlaufsbemerkungen", ng.verlaufsbemerkungen, x:lx, y:y, w:rx-lx, h:11, lw:85)
            y += 11
        }
```

Direkt danach (vor `// ABCDE grid`) einfügen:

```swift
        if !ng.notfallFreitext.isEmpty {
            field("Ergänzungen", ng.notfallFreitext, x:lx, y:y, w:rx-lx, h:11, lw:55)
            y += 11
        }
```

- [ ] **Step 3: Build + Tests**

```bash
xcodebuild build -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E 'error:|Build succeeded|Build FAILED'
```

```bash
xcodebuild test -scheme PatProt -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E 'Test Suite|passed|failed|error:'
```

Erwartet: Build succeeded, alle Tests grün

- [ ] **Step 4: Commit**

```bash
git add PatProt/Views/NotfallgeschehenView.swift PatProt/Services/PDFGenerator.swift
git commit -m "feat: Notfallgeschehen-Freitext section in view and PDF"
```
