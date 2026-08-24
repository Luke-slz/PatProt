# BEFAST-Schema in D – Disability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** BEFAST-Schlaganfall-Schema in der D-Disability-Ansicht als aufklappbaren Abschnitt mit Toggle hinzufügen und im PDF ausgeben.

**Architecture:** Drei sequenzielle Änderungen: (1) 8 neue Felder in `DisabilityBefund`, (2) neuer aufklappbarer Section in `DisabilityView`, (3) bedingte Zeilen im D-Neurologie-Block des PDFs plus korrigierte Sektionshöhe.

**Tech Stack:** SwiftUI, UIGraphicsPDFRenderer, `@Binding`, `CheckboxRow` (bereits vorhanden), `ZeitFeld` (bereits in EinsatzOrtView.swift)

---

## File Map

| Datei | Aktion | Änderung |
|---|---|---|
| `PatProt/Models/Models.swift` | Modify | 8 neue Felder in `DisabilityBefund` |
| `PatProt/Views/ABCDEDetailViews.swift` | Modify | Neuer BEFAST-Section in `DisabilityView` |
| `PatProt/Services/PDFGenerator.swift` | Modify | `neItems` → `var`, BEFAST-Zeilen anhängen, Sektionshöhe korrigieren |

---

## Task 1: DisabilityBefund um BEFAST-Felder erweitern

**Files:**
- Modify: `PatProt/PatProt/PatProt/Models/Models.swift` (struct `DisabilityBefund`, aktuell Zeilen 274–287)

- [ ] **Schritt 1: 8 neue Felder hinzufügen**

Aktueller Struct-Abschluss (Zeilen 282–287):
```swift
    var blutzucker: Double? = nil
    var schmerz: Int = 0
    var freitext = ""

    var gcsGesamt: Int { gcsAugen + gcsVerbal + gcsMotor }
}
```

Ersetzen durch:
```swift
    var blutzucker: Double? = nil
    var schmerz: Int = 0
    var freitext = ""

    // BEFAST
    var befastAktiv: Bool = false
    var befastBalance: Bool = false
    var befastEyes: Bool = false
    var befastFace: Bool = false
    var befastArm: Bool = false
    var befastSpeech: Bool = false
    var befastZeitUnbekannt: Bool = false
    var befastSymptombeginn: Date? = nil

    var gcsGesamt: Int { gcsAugen + gcsVerbal + gcsMotor }
}
```

- [ ] **Schritt 2: Rückwärtskompatibilität prüfen**

`DisabilityBefund` ist `Codable`. Bool-Felder mit Defaultwert und `Date?` mit `nil`-Default werden von Swift beim Dekodieren alter JSON-Archive automatisch mit ihren Defaults befüllt — kein Migrationscode nötig.

- [ ] **Schritt 3: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt add "PatProt/Models/Models.swift"
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt commit -m "feat: DisabilityBefund – BEFAST-Felder hinzugefügt"
```

---

## Task 2: DisabilityView – BEFAST-Section einfügen

**Files:**
- Modify: `PatProt/PatProt/PatProt/Views/ABCDEDetailViews.swift` (struct `DisabilityView`, nach dem GCS-Abschnitt, vor dem Pupillen-Abschnitt, aktuell ca. Zeile 435)

`CheckboxRow` ist bereits in derselben Datei definiert (Zeile 26).  
`ZeitFeld` ist in `PatProt/Views/EinsatzOrtView.swift` definiert und direkt zugänglich (gleiches Modul).

- [ ] **Schritt 1: Neuen Section zwischen GCS und Pupillen einfügen**

Direkt nach dem schließenden `}` des GCS-Abschnitts (der mit `.listRowBackground(gcsBg)` endet, ca. Zeile 434) und vor dem `Section { TextField("Pupillen links...` (ca. Zeile 436) einfügen:

```swift
Section {
    Toggle("BEFAST-Schema", isOn: $befund.befastAktiv)
    if befund.befastAktiv {
        CheckboxRow("B – Balance (Schwindel / Gleichgewichtsstörung)", isOn: $befund.befastBalance)
        CheckboxRow("E – Eyes (Sehstörung / Doppelbilder)", isOn: $befund.befastEyes)
        CheckboxRow("F – Face (Gesichtslähmung / hängender Mundwinkel)", isOn: $befund.befastFace)
        CheckboxRow("A – Arm (Armparese / Armhalteversuch auffällig)", isOn: $befund.befastArm)
        CheckboxRow("S – Speech (Sprachstörung / Aphasie)", isOn: $befund.befastSpeech)
        Toggle("T – Zeitpunkt unbekannt", isOn: $befund.befastZeitUnbekannt)
        if !befund.befastZeitUnbekannt {
            ZeitFeld(label: "T – Symptombeginn", datum: $befund.befastSymptombeginn)
        }
    }
} header: {
    Label("BEFAST-Schema (Schlaganfall)", systemImage: "brain")
}
```

- [ ] **Schritt 2: Manuell prüfen**

Simulator: D – Disability öffnen → Toggle „BEFAST-Schema" antippen → B/E/F/A/S Checkboxen und „Zeitpunkt unbekannt"-Toggle erscheinen → „Zeitpunkt unbekannt" deaktiviert zeigt ZeitFeld → Toggle wieder aus → Abschnitt klappt zu.

- [ ] **Schritt 3: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt add "PatProt/Views/ABCDEDetailViews.swift"
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt commit -m "feat: DisabilityView – BEFAST-Schema als aufklappbarer Abschnitt"
```

---

## Task 3: PDF – BEFAST-Zeilen und korrigierte Sektionshöhe

**Files:**
- Modify: `PatProt/PatProt/PatProt/Services/PDFGenerator.swift` (D-Neurologie-Block, ca. Zeilen 471–517)

- [ ] **Schritt 1: `neItems` von `let` auf `var` ändern**

Aktuelle Zeile 474:
```swift
let neItems: [(String,String)] = [
```

Ersetzen durch:
```swift
var neItems: [(String,String)] = [
```

- [ ] **Schritt 2: BEFAST-Zeilen nach dem bestehenden Array anhängen**

Direkt nach der schließenden `]` des `neItems`-Arrays (Zeile 484, nach `("Schmerz NRS", ...)`) und vor `for (i,(label,value)) in neItems.enumerated()` einfügen:

```swift
if gcs.befastAktiv {
    let tf = DateFormatter()
    tf.dateFormat = "HH:mm"
    let zeitStr: String = {
        if gcs.befastZeitUnbekannt { return "unbekannt" }
        if let d = gcs.befastSymptombeginn { return tf.string(from: d) }
        return "—"
    }()
    neItems += [
        ("BEFAST B", gcs.befastBalance ? "+" : "–"),
        ("BEFAST E", gcs.befastEyes    ? "+" : "–"),
        ("BEFAST F", gcs.befastFace    ? "+" : "–"),
        ("BEFAST A", gcs.befastArm     ? "+" : "–"),
        ("BEFAST S", gcs.befastSpeech  ? "+" : "–"),
        ("BEFAST T", zeitStr),
    ]
}
```

- [ ] **Schritt 3: Sektionshöhe korrigieren**

Aktuelle Zeile 517:
```swift
y = mvColY + CGFloat(max(mvItems.count, atItems.count, ciItems.count))*mvH + 2
```

Ersetzen durch:
```swift
y = mvColY + CGFloat(max(mvItems.count, atItems.count, ciItems.count, neItems.count, haItems.count))*mvH + 2
```

- [ ] **Schritt 4: Manuell prüfen**

Protokoll mit aktiviertem BEFAST (mind. B und F angehakt, Symptombeginn z.B. 14:32) → PDF exportieren → D-Neurologie-Spalte enthält Zeilen BEFAST B +, BEFAST E –, BEFAST F +, BEFAST A –, BEFAST S –, BEFAST T 14:32. Sektionshöhe passt sich an (kein Überlappen mit Section 4).

Variante mit „Zeitpunkt unbekannt": BEFAST T zeigt „unbekannt".

- [ ] **Schritt 5: Commit**

```bash
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt add "PatProt/Services/PDFGenerator.swift"
git -C /Users/lukeslz/Documents/Privat/DLRG/PatProt/PatProt commit -m "feat: PDF – BEFAST-Zeilen in D-Neurologie, Sektionshöhe korrigiert"
```
